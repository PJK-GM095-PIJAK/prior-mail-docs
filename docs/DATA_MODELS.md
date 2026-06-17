# DATA_MODELS.md

> Data shapes for PriorMail. This is the single source of truth for request/response schemas and client-side storage types. There is no server-side database — all email data lives in the browser's `localStorage`. If backend Pydantic models or frontend TypeScript types disagree with this file, the code is wrong.

---

## 1. Overview

PriorMail has no Postgres tables. All data shapes exist in two places:

| Layer | Location | Purpose |
|---|---|---|
| Backend response schemas | Pydantic models in `prior-mail-backend/src/priormail/models/` | Defines what the API returns |
| Frontend stored types | TypeScript + zod in `prior-mail-frontend/lib/types/` | Defines what goes into localStorage |

---

## 2. Enums

Defined in Pydantic (backend) and mirrored as `zod` enums (frontend).

### `priority_level`
```
urgent | high | normal | low
```
Used in `AnalysisResult.priority`. Will be `null` when `is_phishing` is `true`.

> **Single source:** Pydantic `StrEnum` in backend is authoritative. Frontend mirrors via `z.enum(...)` in `types/enums.ts`.

---

## 3. API Response Shape

### 3.1 `AnalysisResult`

Returned by `POST /api/v1/emails/analyze`.

```python
# models/analysis.py (backend)
from datetime import datetime, date
from pydantic import BaseModel, ConfigDict, Field
from priormail.models.enums import Priority

class ExtractedTask(BaseModel):
    description: str
    due_date: date | None

class AnalysisResult(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    subject: str
    sender_email: str
    sender_name: str | None
    received_at: datetime | None
    snippet: str                               # first 200 chars of body
    body_text: str
    is_phishing: bool
    phishing_score: float = Field(ge=0, le=1)
    priority: Priority | None                  # null when is_phishing=True
    priority_confidence: float = Field(ge=0, le=1)
    summary: str | None                        # null when is_phishing=True
    tasks: list[ExtractedTask]                 # empty when is_phishing=True
    processed_at: datetime
    model_versions: dict[str, str]             # e.g. {"priority": "v1.3", "phishing": "v1.0"}
```

---

## 4. Frontend / localStorage Types

### 4.1 Zod schemas

```ts
// lib/types/enums.ts
import { z } from "zod";

export const Priority = z.enum(["urgent", "high", "normal", "low"]);
export type Priority = z.infer<typeof Priority>;
```

```ts
// lib/types/email.ts
import { z } from "zod";
import { Priority } from "./enums";

export const ExtractedTask = z.object({
  description: z.string(),
  due_date: z.string().nullable(),   // "YYYY-MM-DD" or null
});
export type ExtractedTask = z.infer<typeof ExtractedTask>;

export const AnalysisResult = z.object({
  subject: z.string(),
  sender_email: z.string(),
  sender_name: z.string().nullable(),
  received_at: z.string().datetime().nullable(),
  snippet: z.string(),
  body_text: z.string(),
  is_phishing: z.boolean(),
  phishing_score: z.number().min(0).max(1),
  priority: Priority.nullable(),
  priority_confidence: z.number().min(0).max(1),
  summary: z.string().nullable(),
  tasks: z.array(ExtractedTask),
  processed_at: z.string().datetime(),
  model_versions: z.record(z.string()),
});
export type AnalysisResult = z.infer<typeof AnalysisResult>;
```

### 4.2 `StoredEmail` — what goes into localStorage

The frontend wraps `AnalysisResult` with a client-assigned `id` and `uploaded_at` timestamp before persisting.

```ts
// lib/types/email.ts (continued)
export const StoredEmail = AnalysisResult.extend({
  id: z.string().uuid(),            // generated client-side before the API call
  uploaded_at: z.string().datetime(), // ISO 8601, set client-side at upload time
});
export type StoredEmail = z.infer<typeof StoredEmail>;
```

### 4.3 localStorage layout

```
localStorage key: "priormail_emails"
value: JSON.stringify(StoredEmail[])   // newest first
```

- Parse at startup with `StoredEmail.array().parse(...)`.
- On parse failure (corrupt data), reset to `[]` and show a non-blocking warning.
- **Size target:** keep under 4 MB. If `body_text` causes the limit to be approached, the frontend may strip `body_text` from older entries automatically (oldest-first eviction).

---

## 5. Pydantic Naming Conventions (backend)

- `*Result` — read shapes returned in API responses
- `*Create` / `*Update` — write shapes (currently only `AnalysisResult` is exposed)
- `*State` — LangGraph pipeline state (internal, never serialised to HTTP)

---

## 6. Changelog

| Date | Change | By |
|---|---|---|
| 2026-05-25 | Initial schema (Postgres tables, Supabase) | Team |
| 2026-06-17 | Full rewrite: removed all Postgres tables (users, emails, extracted_tasks, audit_log, sync_jobs); replaced with API response shape + localStorage StoredEmail type | Team |

---

*Last updated: 2026-06-17*
