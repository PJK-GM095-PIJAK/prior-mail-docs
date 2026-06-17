# SECURITY.md

> Security and privacy policy for PriorMail. **This document is enforced**, not aspirational. Code that violates it should not be merged. Audit findings against this document.

---

## 1. Threat Model

### What we're protecting
1. **Email content uploaded by the user** — private data; processed transiently on the backend and then discarded
2. **LLM API key** — spending risk if leaked; content is sent through it
3. **Model checkpoints** — IP from training; not strictly secret but not public
4. **PII in training data** — must not contain real user emails without consent + redaction

### Threats we care about (in priority order)
1. **PII leakage** through logs, error messages, or third-party APIs beyond the LLM
2. **LLM API key theft** — financial cost and potential data exfiltration
3. **Malicious `.eml` content** — XSS via email body rendered in the browser
4. **Compromised dependencies** (supply chain)
5. **Insider mistake** — team member commits a key or logs email body

### Key simplification vs. prior architecture
PriorMail no longer has user accounts, OAuth tokens, or a server-side database. The backend is **fully stateless**: it receives an `.eml`, processes it in memory, returns the result, and retains nothing. This eliminates an entire category of threats (unauthorized DB access, token theft, cross-user data leakage).

### Threats explicitly out of scope (for MVP)
- Nation-state actors
- Physical access to running infrastructure
- Side-channel attacks on the ML models
- Sophisticated phishing of team members themselves (we will, however, use a password manager and 2FA)

---

## 2. Data Classification

| Class | Examples | Handling |
|---|---|---|
| **Secret** | LLM API key (Anthropic / OpenAI) | Render env vars only. Never in code or logs. |
| **Sensitive** | Email bodies, subjects, sender info (uploaded at runtime) | In memory only on backend. Never written to disk or DB. Never logged beyond a 100-char snippet. |
| **Internal** | Model versions, processing latency, error types | Loggable. |
| **Public** | Project documentation, repo READMEs (excluding secrets) | Open. |

---

## 3. Email Content Handling

Email content is uploaded by the user and processed transiently. Rules:

- **In-memory only.** The backend parses the `.eml`, runs the pipeline, and returns the result in the HTTP response. Nothing is written to disk, a database, or a cache.
- **Logging:** Logs may include `subject` and `sender_email` for debugging, but **never** the full body. Snippets in logs are capped at 100 chars.
- **Third-party exposure:** Only one external service ever sees email content — the hosted LLM (for summarization and task extraction). No other third party touches content. This must not change without a security review.
- **Frontend rendering:** Email body rendered in the browser must be **sanitized before display** (`dangerouslySetInnerHTML` is forbidden; use a sanitization library such as DOMPurify). Email bodies are attacker-controlled input.
- **Training data:** Real user emails enter the training dataset only with explicit consent **and** after PII redaction (see `ML_PIPELINE.md §7`).

---

## 4. Secret Management

### Where secrets live

| Secret | Where it's stored | Who can read |
|---|---|---|
| LLM API key (Anthropic / OpenAI) | Render env vars | Backend only |
| Supabase Storage credentials | Render env vars | Backend only (model checkpoint download at startup) |
| `wandb` API key | Local `.netrc`, NOT in repo | Each developer |
| Sentry DSN | Vercel + Render env vars | App at startup |

### Rules
- **Never** commit a `.env` or any file containing real secrets
- `.env.example` is mandatory in each repo (template with placeholder values)
- All secret loading goes through `pydantic-settings` (backend) or Next.js env validation (frontend); typos must fail loudly at startup
- Rotate any secret that may have been exposed (in chat, in a PR, in logs) within 24 hours
- If you commit a secret by accident: rotate first, then clean git history (`git filter-repo`) and force-push

### Detection
- Pre-commit hook scans for high-entropy strings and common secret patterns (`gitleaks` or `detect-secrets`)
- GitHub secret scanning enabled on all repos
- Any alert from these tools is treated as P0

---

## 5. XSS — Email Body Rendering

Email bodies are attacker-controlled content. A malicious `.eml` could contain JavaScript, `<script>` tags, `onclick` attributes, or data URIs designed to execute code in the browser.

**Rules:**
- **Never** use `dangerouslySetInnerHTML` on email body content (or any user-supplied field)
- Use a sanitization library (e.g. `DOMPurify`) before rendering any HTML extracted from the `.eml`
- If rendering plain-text only, escape it as text nodes — do not inject into `innerHTML`
- This rule applies to `body_text`, `subject`, `sender_name`, and `snippet` — all come from the `.eml`

---

## 6. Rate Limiting & Abuse Prevention

See `API_CONTRACT.md §4` for the exact limits. Defense rules:

- All limits keyed on **IP address** (no user accounts)
- A global limit guards against runaway LLM spend
- 429 responses include `Retry-After`
- Repeated 429s from the same IP trigger a WARN-level log

---

## 7. File Upload Security

The `POST /api/v1/emails/analyze` endpoint accepts a user-supplied file. Rules:

- **Size limit:** 5 MB maximum. Reject with `413` before parsing.
- **Type check:** Validate that the file is parseable as `message/rfc822` (`.eml`). Do not trust the `Content-Type` header from the request — validate the actual file content.
- **No execution:** The `.eml` is parsed with Python's stdlib `email` module. No subprocess invocation, no shell execution.
- **Timeout:** Processing should time out at 30 s server-side (covers the LLM call). Return `504` if exceeded.

---

## 8. Dependency Security

- Lock files committed (`uv.lock`, `pnpm-lock.yaml`)
- Dependabot or Renovate enabled on all repos
- Security advisories reviewed weekly
- Major version upgrades require a PR with rationale
- No git-installed dependencies (`pip install git+...` or `github:...` pnpm syntax forbidden — pin to versioned releases)

---

## 9. Security Review Checklist

Before any PR that touches secrets, file upload handling, or email rendering:

- [ ] Are there any new secrets? If yes, are they in env vars (not committed)?
- [ ] Is email body content sanitized before any browser rendering?
- [ ] Are logs free of full email body? (Check new log statements — snippets ≤100 chars only)
- [ ] Are error messages free of sensitive content (stack traces must not dump the `.eml` body)?
- [ ] Is any new third-party service receiving email content? If yes, is there a justification?
- [ ] Does the upload handler enforce the 5 MB limit and reject non-`.eml` content?

---

## 10. Incident Response (lightweight)

For a 5-week capstone we won't have a formal IR process. But if a security issue is found:

1. **Stop the bleeding** — disable the affected endpoint or revoke the affected credentials
2. **Notify the team** in the group chat with a short summary
3. **Document** the incident (what, when, how detected, what data was potentially affected)
4. **Fix** the root cause and ship a patch
5. **Review** in the next team sync: what gap allowed this, what changes here would prevent recurrence

---

## 11. Things We're Explicitly Not Doing (MVP)

- No formal penetration test
- No SOC 2 or ISO 27001 compliance
- No bug bounty program
- No formal data processing agreement template (capstone scope)

Post-MVP, several of these would be required for any real production deployment.

---

## 12. Changelog

| Date | Change | By |
|---|---|---|
| 2026-05-25 | Initial policy (Gmail-based architecture) | Team |
| 2026-06-17 | Full rewrite: removed Gmail OAuth, Supabase Vault, audit log, RLS, account deletion, and per-user rate limiting. Added XSS (email body rendering) and file upload security sections. Simplified to match stateless .eml upload architecture. | Team |

---

*Last updated: 2026-06-17*
