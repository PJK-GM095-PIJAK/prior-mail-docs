# SECURITY.md

> Security and privacy policy for PriorMail. **This document is enforced**, not aspirational. Code that violates it should not be merged. Audit findings against this document.

---

## 1. Threat Model

### What we're protecting
1. **Email content** — private user data, our highest-sensitivity asset
2. **OAuth refresh tokens** — long-lived access to user inboxes
3. **User identity** — email, name, association with Gmail account
4. **Model checkpoints** — IP we created from training; not strictly secret but not public either

### Threats we care about (in priority order)
1. **Unauthorized access** to email content (other users, attackers, accidental leaks)
2. **Token theft** (refresh tokens give full inbox read access)
3. **PII leakage** through logs, error messages, third-party APIs, or training data
4. **Compromised dependencies** (supply chain)
5. **Insider mistake** — team member commits a secret or queries the wrong user's data

### Threats explicitly out of scope (for MVP)
- Nation-state actors
- Physical access to running infrastructure
- Side-channel attacks on the ML models
- Sophisticated phishing of team members themselves (we will, however, use a password manager and 2FA)

---

## 2. Data Classification

| Class | Examples | Handling |
|---|---|---|
| **Secret** | OAuth refresh tokens, API keys, model API keys, JWT signing keys | Env vars + Supabase Vault. Never in code or logs. |
| **Sensitive** | Email bodies, summaries, extracted tasks, sender info | DB only, RLS enforced. Logs use snippets (≤100 chars). 30-day retention for bodies. |
| **Internal** | User profile, sync state, audit logs, model versions | DB with RLS. Loggable. |
| **Public** | Project documentation, repo READMEs (excluding secrets) | Open. |

---

## 3. PII Handling

### Email content
- **Storage:** Postgres with RLS. Bodies auto-nulled after 30 days; only snippet + hash + AI-derived fields retained.
- **Transmission:** TLS 1.2+ everywhere. No exception.
- **Logging:** Logs may include subject and sender, but **never** full body. Snippets in logs capped at 100 chars.
- **Third-party APIs:** Only one third party touches email content — the LLM summarizer/task extractor. No other external service ever sees content.
- **Training data:** Real user emails enter training data only with explicit consent **and** after PII redaction (see `ML_PIPELINE.md` §7).

### User profile
- Stored in `users` table. Display name and avatar from Google profile.
- On account deletion (`DELETE /api/v1/account`), all rows cascading from the user are deleted, then the auth user is deleted, then the Gmail OAuth token is revoked.

### Audit log
Every read/write of email content is recorded in `audit_log` with `user_id`, `email_id`, `action`, `actor`. This is for forensics — if data appears where it shouldn't, we can trace it. The audit log is not user-facing.

---

## 4. Gmail OAuth Scopes Policy

### Allowed scope (MVP)
- `https://www.googleapis.com/auth/gmail.readonly` — read messages and threads

### Forbidden scopes (MVP)
- `gmail.send` — never, until/unless email composition is in scope
- `gmail.modify` — never, until/unless we move emails between folders or apply labels
- `gmail.compose`, `gmail.insert`, `gmail.settings.*` — never, not in roadmap

### Why minimum scope matters
Google's OAuth verification process scales with the sensitivity of scopes requested. `gmail.readonly` is "restricted scope" but achievable; broader scopes require a much more rigorous review. More practically, requesting only what we need limits blast radius if a token is ever leaked.

If a future feature requires broader scope, it must come with:
1. A documented user benefit
2. A security review (the feature in `SECURITY.md`)
3. A reauthorization flow (the user must explicitly grant the new scope)

---

## 5. Secret Management

### Where secrets live
| Secret | Where it's stored | Who can read |
|---|---|---|
| Gmail OAuth client ID + secret | Render env vars, Vercel env vars | Service accounts only |
| Supabase service role key | Render env vars | Backend only — never frontend |
| Supabase anon key | Vercel env vars, Render env vars | Frontend (anon role) |
| Supabase JWT signing secret | Supabase managed | Supabase only |
| LLM API key (Anthropic / OpenAI) | Render env vars | Backend only |
| User-specific Gmail refresh tokens | Supabase Vault | Backend with service role |
| `wandb` API key | Local `.netrc`, NOT in repo | Each developer |
| Sentry DSN | Vercel + Render env vars | App at startup |

### Rules
- **Never** commit a `.env` or any file containing real secrets
- `.env.example` is mandatory in each repo (template with empty values)
- All secret loading goes through `pydantic-settings` (backend) or Next.js env validation (frontend); typos must fail loudly at startup
- Rotate any secret that may have been exposed (in chat, in a PR, in logs) — within 24 hours
- If you commit a secret by accident: rotate first, then clean git history (using e.g. `git filter-repo`) and force-push

### Detection
- Pre-commit hook scans for high-entropy strings and common secret patterns (use `gitleaks` or `detect-secrets`)
- GitHub secret scanning enabled on all repos
- Any alert from these tools is treated as a P0

---

## 6. Authentication & Authorization

### Authentication flow
1. User signs in with Google via Auth.js
2. Supabase creates/updates the user
3. Backend receives Supabase-issued JWT and validates it on every request (using Supabase's JWKS endpoint, cached)
4. Backend trusts `user_id` from the validated JWT — never from request body or query

### Authorization
- Every query that reads user-specific data must filter by `user_id` from the JWT
- RLS provides defense in depth, but the backend service role bypasses RLS, so the application code must enforce ownership itself
- Helper: `current_user_id` FastAPI dependency that extracts the user from the JWT — use it instead of accepting `user_id` as a parameter

### Sessions
- JWTs expire after Supabase's default (1 hour); refresh via Auth.js silently
- Logout invalidates the Supabase session

---

## 7. Audit Logging

Every read or write of email content gets an `audit_log` row:

| `action` | When |
|---|---|
| `read` | Backend serves email body to the frontend (e.g. `GET /emails/{id}` with body included) |
| `classify` | Initial classification by LangGraph pipeline |
| `reclassify` | Re-run via `POST /emails/{id}/reclassify` |
| `summarize` | LLM summarization call (logs that content was sent to external LLM) |
| `delete` | Body auto-nulled at 30 days, or account deletion |

> The audit log is the answer to "did anyone read my data?" — it must be complete. Code reviews should look for missing audit entries on any code path that touches email content.

---

## 8. Data Retention & Deletion

### Email bodies
- Retained 30 days from `received_at`, then auto-nulled by a daily cleanup job
- Snippet, hash, and AI-derived fields (priority, summary, etc.) retained indefinitely

### Account deletion
- Hard delete cascading from `users` table
- Sequence:
  1. Revoke Gmail OAuth token (`oauth2.revoke` endpoint)
  2. Delete all related rows (DB cascades)
  3. Delete Supabase Auth user
- This is **irreversible**. Frontend confirms twice.

### Backup retention
- Supabase automated backups: 7 days (default)
- We do **not** keep additional backups outside Supabase
- Account deletion does not retroactively delete from backups (Supabase backup policy); document this in the user-facing privacy notice

---

## 9. Rate Limiting & Abuse Prevention

See `API_CONTRACT.md` §9 for the exact limits. Defense rules:

- All per-user limits keyed on `user_id` from the JWT (not IP)
- A separate global limit guards against runaway costs (Gmail quota, LLM spend)
- 429 responses include `Retry-After`
- Repeated 429s trigger a log warning at WARN level (potential abuse or bug)

---

## 10. Dependency Security

- Lock files committed (`uv.lock`, `pnpm-lock.yaml`)
- Dependabot or Renovate enabled on all repos (default config OK)
- Security advisories reviewed weekly
- Major version upgrades require a PR with rationale
- No git-installed dependencies (`pip install git+...` or pnpm `github:...` are forbidden — pin to versioned releases)

---

## 11. Security Review Checklist

Before any PR that touches auth, secrets, or email content, the reviewer asks:

- [ ] Are there any new secrets? If yes, are they in env vars (not committed)?
- [ ] Are all queries filtered by `user_id` from the validated JWT?
- [ ] Are any logs printing email body, full subject of sensitive emails, or sender PII beyond the standard fields?
- [ ] Are error messages free of sensitive content (stack traces don't dump request body)?
- [ ] If touching the audit log: are all paths that touch email content recording an entry?
- [ ] If sending data to a third party: is it the LLM provider or something new? If new, is there a justification?
- [ ] Are any new Gmail scopes requested? If yes, has the rationale been documented?

---

## 12. Incident Response (lightweight)

For a 5-week capstone we won't have a formal IR process. But if a security issue is found:

1. **Stop the bleeding** — disable the affected endpoint or revoke the affected credentials
2. **Notify the team** in the group chat with a short summary
3. **Document** the incident (what, when, how detected, what data was potentially affected)
4. **Fix** the root cause and ship a patch
5. **Review** in the next team sync: what gap allowed this, and what changes here in `SECURITY.md` would prevent recurrence

If user data was demonstrably accessed by an unintended party, notify the affected users.

---

## 13. Things We're Explicitly Not Doing (MVP)

To set expectations:

- No formal penetration test
- No SOC 2 or ISO 27001 compliance
- No HSM for key management (Supabase Vault is enough for our scale)
- No bug bounty program
- No formal data processing agreement template (capstone scope)

Post-MVP, several of these would be required for any real production deployment.

---

## 14. Changelog

| Date | Change | By |
|---|---|---|
| 2026-05-25 | Initial policy | Team |

---

*Last updated: 2026-05-25*
