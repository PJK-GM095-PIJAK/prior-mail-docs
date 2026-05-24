# DATA_MODELS.md

> Database schema, Pydantic models, and TypeScript types for PriorMail. This is the single source of truth for data shapes. If the database, backend code, or frontend code disagrees with this file, the code is wrong.

---

## 1. Overview

Five Postgres tables in Supabase:

| Table | Purpose | Owner |
|---|---|---|
| `users` | User profile + OAuth state | Backend |
| `emails` | Classified emails with AI-derived fields | Backend |
| `extracted_tasks` | Tasks extracted by the LangGraph pipeline | Backend |
| `audit_log` | Every read/write of email content (compliance) | Backend |
| `sync_jobs` | Tracks running sync jobs (prevents duplicates) | Backend (worker) |

All tables use UUID primary keys (v4) and `timestamptz` for time fields.

Row-level security (RLS) is enabled on **every** table — see §6.

---

## 2. Enums

These are defined as Postgres enums and mirrored in Pydantic (backend) and TypeScript (frontend).

### `priority_level`
```
urgent | high | normal | low
```

### `audit_action`
```
read | classify | reclassify | delete | summarize
```

### `actor_type`
```
user | worker | agent
```

### `sync_job_status`
```
pending | running | completed | failed
```

> **Single source:** Postgres enums are authoritative. Backend mirrors via Pydantic; frontend mirrors via `zod` schemas in `types/enums.ts`.

---

## 3. Tables

### 3.1 `users`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | uuid | PK, default `gen_random_uuid()` | Matches Supabase Auth `user.id` |
| `email` | text | NOT NULL, UNIQUE | |
| `display_name` | text | NULL | from Google profile |
| `avatar_url` | text | NULL | |
| `gmail_refresh_token` | text | NOT NULL | **Encrypted via Supabase Vault** |
| `gmail_email` | text | NOT NULL | the Gmail account they connected (may differ from `email` in edge cases) |
| `last_sync_history_id` | text | NULL | for Gmail delta sync |
| `last_sync_at` | timestamptz | NULL | |
| `created_at` | timestamptz | NOT NULL, default `now()` | |
| `updated_at` | timestamptz | NOT NULL, default `now()` | trigger updates on row change |

**Indexes:**
- `users_pkey` on `id`
- `users_email_key` on `email`

### 3.2 `emails`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | uuid | PK, default `gen_random_uuid()` | |
| `user_id` | uuid | NOT NULL, FK → `users.id` ON DELETE CASCADE | |
| `gmail_message_id` | text | NOT NULL | |
| `thread_id` | text | NOT NULL | |
| `subject` | text | NOT NULL, default `''` | empty string for blank subjects |
| `sender_email` | text | NOT NULL | |
| `sender_name` | text | NULL | |
| `received_at` | timestamptz | NOT NULL | |
| `snippet` | text | NOT NULL | first 200 chars, used in list views |
| `body_hash` | text | NOT NULL | SHA-256 of normalized body |
| `body_text` | text | NULL | full body; **auto-nulled after 30 days** |
| `priority` | priority_level | NOT NULL | |
| `priority_confidence` | real | NOT NULL, CHECK 0 ≤ x ≤ 1 | |
| `is_phishing` | boolean | NOT NULL, default false | |
| `phishing_score` | real | NOT NULL, CHECK 0 ≤ x ≤ 1 | |
| `summary` | text | NULL | LLM-generated |
| `model_versions` | jsonb | NOT NULL, default `{}` | e.g. `{"priority":"v1.3","phishing":"v1.0"}` |
| `processed_at` | timestamptz | NULL | when LangGraph pipeline finished |
| `created_at` | timestamptz | NOT NULL, default `now()` | |
| `updated_at` | timestamptz | NOT NULL, default `now()` | |

**Constraints:**
- `UNIQUE (user_id, gmail_message_id)` — same message can't be ingested twice per user

**Indexes:**
- `emails_pkey` on `id`
- `emails_user_received_idx` on `(user_id, received_at DESC)` — for list query
- `emails_user_priority_idx` on `(user_id, priority, received_at DESC)` — for filtered list
- `emails_user_phishing_idx` on `(user_id, is_phishing) WHERE is_phishing = true` — partial index

### 3.3 `extracted_tasks`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | uuid | PK, default `gen_random_uuid()` | |
| `user_id` | uuid | NOT NULL, FK → `users.id` ON DELETE CASCADE | denormalized for RLS |
| `email_id` | uuid | NOT NULL, FK → `emails.id` ON DELETE CASCADE | |
| `description` | text | NOT NULL | |
| `due_date` | date | NULL | |
| `completed` | boolean | NOT NULL, default false | |
| `completed_at` | timestamptz | NULL | set when `completed` flips to true |
| `created_at` | timestamptz | NOT NULL, default `now()` | |
| `updated_at` | timestamptz | NOT NULL, default `now()` | |

**Indexes:**
- `tasks_pkey` on `id`
- `tasks_user_completed_due_idx` on `(user_id, completed, due_date NULLS LAST)`
- `tasks_email_idx` on `email_id`

### 3.4 `audit_log`

Append-only. Never updated, never deleted (except via `DELETE /api/v1/account` cascade).

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | uuid | PK, default `gen_random_uuid()` | |
| `user_id` | uuid | NOT NULL, FK → `users.id` ON DELETE CASCADE | |
| `email_id` | uuid | NULL, FK → `emails.id` ON DELETE SET NULL | |
| `action` | audit_action | NOT NULL | |
| `actor` | actor_type | NOT NULL | |
| `actor_detail` | text | NULL | e.g. `"agent:classify"` |
| `metadata` | jsonb | NOT NULL, default `{}` | |
| `created_at` | timestamptz | NOT NULL, default `now()` | |

**Indexes:**
- `audit_pkey` on `id`
- `audit_user_created_idx` on `(user_id, created_at DESC)`

### 3.5 `sync_jobs`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | uuid | PK, default `gen_random_uuid()` | |
| `user_id` | uuid | NOT NULL, FK → `users.id` ON DELETE CASCADE | |
| `status` | sync_job_status | NOT NULL, default `'pending'` | |
| `started_at` | timestamptz | NULL | |
| `finished_at` | timestamptz | NULL | |
| `processed_count` | integer | NOT NULL, default 0 | |
| `error` | text | NULL | populated on failure |
| `created_at` | timestamptz | NOT NULL, default `now()` | |

**Constraints:**
- Partial unique index: `CREATE UNIQUE INDEX sync_jobs_user_active_idx ON sync_jobs (user_id) WHERE status IN ('pending', 'running')` — prevents two active jobs per user

---

## 4. Background Jobs (Postgres-side)

### Body retention cleanup
Daily job (cron via Supabase or worker-scheduled):

```sql
UPDATE emails
SET body_text = NULL, updated_at = now()
WHERE body_text IS NOT NULL
  AND received_at < now() - interval '30 days';
```

`body_hash` is **kept** so reprocessing can detect "we've already seen this content" if needed (but reprocessing without body itself fails — see `email.body_expired` error code).

---

## 5. Triggers

### `updated_at` auto-update
Apply to `users`, `emails`, `extracted_tasks`, `sync_jobs`:
```sql
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON <table>
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

### `task.completed_at` auto-set
On `extracted_tasks`, when `completed` flips true, set `completed_at = now()`. When it flips false, set to NULL.

---

## 6. Row-Level Security (RLS)

**All tables have RLS enabled.** Backend uses the service role key (which bypasses RLS) only inside trusted server code. Frontend uses the anon/authenticated role and is therefore subject to RLS.

### Universal policy
For all tables: a row is visible to / writable by the user whose `user_id` matches `auth.uid()`.

```sql
-- Example for emails
CREATE POLICY "users_own_emails" ON emails
FOR ALL
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
```

> Even though MVP doesn't query Supabase directly from the frontend (all data goes through the backend), RLS is enabled as defense in depth. The Realtime channels rely on it.

---

## 7. Pydantic Models (backend)

Located in `prior-mail-backend/src/priormail/models/`. Examples below; full models in code.

```python
# models/enums.py
from enum import StrEnum

class Priority(StrEnum):
    URGENT = "urgent"
    HIGH = "high"
    NORMAL = "normal"
    LOW = "low"

class AuditAction(StrEnum):
    READ = "read"
    CLASSIFY = "classify"
    RECLASSIFY = "reclassify"
    DELETE = "delete"
    SUMMARIZE = "summarize"
```

```python
# models/email.py
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field
from uuid import UUID
from .enums import Priority

class EmailListItem(BaseModel):
    """The shape returned by GET /api/v1/emails (list view)."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    gmail_message_id: str
    thread_id: str
    subject: str
    sender_email: str
    sender_name: str | None
    received_at: datetime
    snippet: str
    priority: Priority
    priority_confidence: float = Field(ge=0, le=1)
    is_phishing: bool
    phishing_score: float = Field(ge=0, le=1)
    has_summary: bool
    task_count: int
    processed_at: datetime | None

class EmailDetail(EmailListItem):
    """The shape returned by GET /api/v1/emails/{id}."""
    body_text: str | None
    summary: str | None
    tasks: list["TaskItem"]
```

Naming convention:
- `*Item` / `*Detail` — read shapes for API responses
- `*Create` — write shapes for create requests
- `*Update` — write shapes for partial updates (all fields optional)
- `*DB` — internal shape mirroring DB row (rarely exposed)

---

## 8. TypeScript Types (frontend)

Located in `prior-mail-frontend/types/`. **Field names must match Pydantic models exactly.**

```ts
// types/enums.ts
import { z } from "zod";

export const Priority = z.enum(["urgent", "high", "normal", "low"]);
export type Priority = z.infer<typeof Priority>;

export const PRIORITY_VALUES = Priority.options;
```

```ts
// types/email.ts
import { z } from "zod";
import { Priority } from "./enums";

export const EmailListItem = z.object({
  id: z.string().uuid(),
  gmail_message_id: z.string(),
  thread_id: z.string(),
  subject: z.string(),
  sender_email: z.string().email(),
  sender_name: z.string().nullable(),
  received_at: z.string().datetime(),
  snippet: z.string(),
  priority: Priority,
  priority_confidence: z.number().min(0).max(1),
  is_phishing: z.boolean(),
  phishing_score: z.number().min(0).max(1),
  has_summary: z.boolean(),
  task_count: z.number().int().nonnegative(),
  processed_at: z.string().datetime().nullable(),
});
export type EmailListItem = z.infer<typeof EmailListItem>;

export const EmailDetail = EmailListItem.extend({
  body_text: z.string().nullable(),
  summary: z.string().nullable(),
  tasks: z.array(TaskItem),
});
export type EmailDetail = z.infer<typeof EmailDetail>;
```

> Frontend should parse API responses through these schemas at the boundary (in the API client). Failures should surface as user-visible errors, not silent crashes.

---

## 9. Migration Guidelines

- Every schema change = a new Alembic migration file in `prior-mail-backend/alembic/versions/`
- File naming: `YYYYMMDD_HHMM_<short_description>.py`
- **Always** include `downgrade()`. If irreversible, write `pass` with a comment explaining why.
- After merging a migration:
  1. Update this file with the new schema
  2. Update Pydantic models in backend
  3. Update TypeScript types + zod schemas in frontend
  4. Bump the docs submodule in both backend and frontend

### Backward-compatibility rules

- **Adding a column:** safe; default to `NULL` or a literal so existing rows are valid.
- **Removing a column:** two-step. (1) Stop writing to it. Ship. (2) Drop in a later migration.
- **Renaming a column:** never. Add a new column, dual-write, migrate readers, drop old column.
- **Changing an enum value:** never remove or rename. Only add.

---

## 10. Changelog

| Date | Change | By |
|---|---|---|
| 2026-05-25 | Initial schema | Team |

---

*Last updated: 2026-05-25*
