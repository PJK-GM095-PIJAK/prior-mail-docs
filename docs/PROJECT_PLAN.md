# PROJECT_PLAN.md

> The operational project plan for **PriorMail**. The original Indonesian deliverable for Pijak × IBM SkillsBuild lives separately; this is the working English version that the team and any LLM assistant should treat as canonical.

---

## 1. Project Overview

**Name:** PriorMail
**Team ID:** PJK-GM095
**Theme:** AI for Productivity and Automation
**Program:** Pijak × IBM SkillsBuild Capstone

### Problem

Knowledge workers receive hundreds of emails daily and spend significant time triaging their inbox. Important emails are missed, tasks go unidentified, and phishing risks add another layer of cognitive load. Existing tools lack automated, intelligent triage that works on real-world email.

### Solution

A web app that lets a user upload any `.eml` email file and automatically:

1. Detects phishing attempts
2. Classifies the email by priority (`urgent` / `high` / `normal` / `low`) using fine-tuned DistilBERT
3. Summarizes the content
4. Extracts actionable tasks and deadlines
5. Surfaces all of this in a dashboard, persisted in the browser's `localStorage`

### Research Questions

1. How effective is fine-tuned DistilBERT for priority classification and phishing detection of email?
2. How does a LangGraph multi-agent pipeline improve summarization and task extraction quality?
3. What is the measured accuracy and latency of the full pipeline on a realistic email test set?

---

## 2. Team

| Member | ID | Role |
|---|---|---|
| Insan Anshary Rasul | APC000D6Y0267 | Core AI & Documentation Lead — DistilBERT fine-tuning, model deployment |
| Syafiq Sadidul Azmi | APC001D6Y0210 | AI Workflow & Infrastructure Specialist — FastAPI backend, .eml parsing, Render deployment |
| Mochamad Chairulridjal Nurvikri | APC001D6Y0328 | Frontend & Intelligent UI Lead — Next.js dashboard, localStorage integration, LangGraph agents |
| Faiz Naufal Huda | APC001D6Y0331 | AI Security & Evaluation Lead — phishing detection, LangGraph agents |

### Code Ownership Quick Reference

| Repo | Primary | Secondary |
|---|---|---|
| `prior-mail-backend` | Syafiq | Insan, Faiz |
| `prior-mail-frontend` | Ridjal | All |
| `prior-mail-model` | Insan | Faiz |
| `prior-mail-docs` | All (by section) | — |

---

## 3. Timeline (5 weeks)

| Week | Focus | Key deliverables |
|---|---|---|
| 1 | Requirements + design | Project plan submitted (7 May), repo scaffolding, UI/UX mocks, initial spec docs |
| 2 | Backend + frontend foundations | FastAPI skeleton, .eml parsing endpoint, Next.js shell with upload UI |
| 3 | ML + integration | Priority classifier trained (baseline), LangGraph pipeline assembled, basic dashboard connected to API |
| 4 | Integration + optimization | End-to-end flow working, localStorage persistence, performance tuning, debugging |
| 5 | Final testing + delivery | Eval gates met, documentation finalized, presentation video (10 min), demo |

### Pijak Program Milestones

- **7 May** — Project plan submission
- **Weeks 2–4** — Mandatory mentoring sessions
- **1–3 Jun** — Progress report
- **19 Jun** — Final deadline (video presentation)
- **19–22 Jun** — 360° feedback round

---

## 4. Scope

### In Scope (MVP)
- `.eml` file upload interface (drag-and-drop + file picker)
- Phishing detection (binary, DistilBERT fine-tuned) — runs first; stops pipeline on positive
- Priority classification (4 classes, DistilBERT fine-tuned) — runs only if not phishing
- Summarization + task extraction via LangGraph pipeline (hosted LLM)
- Dashboard with priority sorting, summaries, task list
- Browser `localStorage` for persisting processed emails across page reloads
- Clear-all option for local data

### Out of Scope (MVP)
- Gmail API integration / OAuth / inbox sync
- Any server-side user storage or database
- User accounts or authentication
- Auto-reply or email composition
- Microsoft Outlook / Microsoft Graph integration
- Multi-account support
- Enterprise SSO
- Mobile native apps
- Calendar integration
- Email categorization beyond priority (e.g. project tagging)

---

## 5. Risk Management

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | DistilBERT accuracy below target in available training time | Medium | Medium | Transfer learning + augmentation; ship baseline as fallback |
| 2 | LangGraph multi-agent flow too complex for 5 weeks | High | Medium | Start with single agent; add complexity incrementally |
| 3 | Team member blocked or behind schedule | Medium | High | Clear ownership; sync every 2 days in group chat |
| 4 | Deployment issues (Render) | Low | Medium | Dockerize early; test deployment in Week 4 |
| 5 | LLM API cost overrun for summarization | Low | Low | Use cheapest capable model; cache repeated identical inputs |
| 6 | localStorage size limit hit during demo | Low | Low | Implement oldest-first eviction; strip body_text from old entries |

> **Risk #1 from prior plan (Gmail API quota/auth issues) has been eliminated** by the switch to `.eml` upload.

---

## 6. Tech Stack Summary

> Full versions and constraints in each repo's `CLAUDE.md`.

- **Backend:** Python 3.11, FastAPI, Pydantic v2, LangGraph
- **Frontend:** Node.js 20, Next.js 15 (App Router), React 19, Tailwind 4, browser localStorage
- **ML:** PyTorch 2.x, Hugging Face Transformers, DistilBERT (`distilbert-base-uncased`)
- **Storage:** Supabase Storage only — used for storing trained model checkpoints; no Postgres, no Auth, no Vault
- **Hosting:** Vercel (frontend), Render (backend)

---

## 7. Communication

- **Daily async:** project group chat
- **Sync every 2 days:** short stand-up (15 min)
- **Weekly:** longer demo + retrospective
- **Mentoring:** as scheduled by Pijak (Weeks 2–4)
- **Decisions:** open in `prior-mail-docs` as a PR; merge means decision is final

---

## 8. Success Criteria

The project is considered successful when:

- [ ] Live deployed app (frontend on Vercel, backend on Render) accessible to demo users
- [ ] All eval gates in `ML_PIPELINE.md` met for at least one promoted model version
- [ ] At least one full end-to-end demo: upload `.eml` → see phishing/priority classification → see summary → see extracted tasks
- [ ] Documentation complete: this `PROJECT_PLAN.md`, all referenced spec files, and a presentation deck
- [ ] 10-minute demo video recorded
- [ ] 360° feedback submitted

---

## 9. Architecture Decision Log

| Date | Decision | Rationale |
|---|---|---|
| 2026-06-17 | Dropped Gmail API; switched to `.eml` upload | Eliminated OAuth complexity, Supabase Vault, background sync workers, and external API quota risk. Core AI pipeline unchanged. Simplification justified given June 19 deadline. |
| 2026-06-17 | Dropped server-side database; using browser localStorage | No user accounts needed for the capstone demo. Removes Supabase Postgres + Auth entirely. Data is per-browser, which is acceptable for the scope. |

---

*Last updated: 2026-06-17*
