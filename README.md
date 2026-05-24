# prior-mail-docs

Shared specifications and documentation for the **PriorMail** capstone project (Team PJK-GM095).

This repo is the **single source of truth** for cross-repo concerns: API contracts, data models, system architecture, and ML pipeline specs. It is consumed by the three working repos as a **git submodule** at `./docs/`. The three CLAUDE templates live in `docs/claude/` and are meant to be renamed to `CLAUDE.md` inside each sibling repo.

## Sibling Repos

| Repo | Role | Submodule path |
|---|---|---|
| [`prior-mail-backend`](../prior-mail-backend) | FastAPI + Gmail + LangGraph | `./docs/` |
| [`prior-mail-frontend`](../prior-mail-frontend) | Next.js dashboard | `./docs/` |
| [`prior-mail-model`](../prior-mail-model) | IndoBERT training + phishing detection | `./docs/` |

## CLAUDE.md Templates

Each sibling repo should have its own `CLAUDE.md` at the repo root. Use the files in `docs/claude/` as templates and rename them when copying:

- Backend: `docs/claude/CLAUDE-BACKEND.md` -> `prior-mail-backend/CLAUDE.md`
- Frontend: `docs/claude/CLAUDE-FRONTEND.md` -> `prior-mail-frontend/CLAUDE.md`
- Model: `docs/claude/CLAUDE-MODEL.md` -> `prior-mail-model/CLAUDE.md`

## Files in this Repo

| File | Owned by | Purpose |
|---|---|---|
| `PROJECT_PLAN.md` | All | High-level plan, timeline, team |
| `ARCHITECTURE.md` | All | System diagram, data flow, deployment topology |
| `API_CONTRACT.md` | Backend (Syafiq) | All HTTP endpoints, request/response schemas, error codes |
| `DATA_MODELS.md` | Backend (Syafiq) | DB schema, Pydantic models, enum values |
| `ML_PIPELINE.md` | Model (Insan, Faiz) | Model architecture, training scripts, eval gates, checkpoint format |
| `SECURITY.md` | All | Privacy rules, secret handling, scope policy |

> If a file does not yet exist, create it before referencing it from sibling repos.

## How Sibling Repos Consume This Repo

Each sibling repo adds this repo as a git submodule mounted at `./docs/`.

### One-time setup (done by repo maintainer)
```bash
# Run inside each sibling repo (backend, frontend, model)
git submodule add https://github.com/PJK-GM095-PIJAK/prior-mail-docs.git docs
git submodule update --init --recursive
git add .gitmodules docs
git commit -m "chore: add prior-mail-docs as submodule"
```

### After cloning a sibling repo
```bash
git clone https://github.com/PJK-GM095-PIJAK/prior-mail-backend.git
cd prior-mail-backend
git submodule update --init --recursive
```

Or shorter, when first cloning:
```bash
git clone --recurse-submodules https://github.com/PJK-GM095-PIJAK/prior-mail-backend.git
```

### Pulling the latest docs in a sibling repo
```bash
git submodule update --remote docs
git add docs
git commit -m "chore: bump prior-mail-docs submodule"
```

## Workflow: Updating a Spec

1. Open a PR in `prior-mail-docs` with the proposed change.
2. Discuss with owner(s) listed in the table above.
3. Merge to `main` in `prior-mail-docs`.
4. In **every** affected sibling repo, run `git submodule update --remote docs` and open a small PR to bump the submodule pointer. CI in each sibling repo should verify nothing breaks.
5. Coordinate the merges so all sibling repos move forward together.

> **Important:** Submodules pin to a specific commit, not a branch. So even after merging here, sibling repos still see the OLD version until they bump the pointer. This is a feature, not a bug — it prevents accidental breakage.

## Conventions

- All spec files use **English** (consistent with `CLAUDE.md` in sibling repos).
- Markdown only. No HTML, no embedded diagrams as images — use Mermaid or ASCII so diffs are readable.
- Breaking changes (renamed fields, removed endpoints) must include a migration note at the top of the file with the date and a one-line summary.
- Version each spec file with `> Last updated: YYYY-MM-DD` at the bottom.

## Status

Initial scaffolding. Spec files to be filled in during Week 1–2.

---

*Team PJK-GM095 — Pijak × IBM SkillsBuild*
