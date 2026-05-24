# API_CONTRACT.md

> The HTTP contract between `prior-mail-frontend` and `prior-mail-backend`. **This document is authoritative.** If code disagrees with this contract, the code is wrong.

---

## 1. Conventions

### Base URL
- Dev: `http://localhost:8000`
- Staging: `https://api-staging.priormail.app`
- Prod: `https://api.priormail.app`

### Versioning
All routes are prefixed with `/api/v1/`. Breaking changes go in `/api/v2/`. Non-breaking additions (new optional fields, new endpoints) stay in v1.

### Authentication
All endpoints **except** `POST /api/v1/auth/google/callback` require:

```
Authorization: Bearer <supabase_jwt>
```

The JWT is the access token from the Supabase Auth session (managed client-side by Auth.js). The backend validates it on every request against Supabase's JWKS endpoint.

### Content Type
All requests and responses use `application/json`. Field names are `snake_case`.

### Response Envelope
**Every** JSON response uses this envelope:

```json
{
  "data": { ... } | [ ... ] | null,
  "error": null | { "code": "string", "message": "string", "details": {...} },
  "meta": { ... }
}
```

- **Success:** `error` is `null`, `data` contains the payload.
- **Failure:** `data` is `null`, `error` populated, HTTP status reflects the error class (4xx or 5xx).
- **Meta:** optional. Used for pagination (`cursor`, `has_more`, `total`).

### Pagination
Cursor-based. Default `limit=20`, max `limit=100`.

Response includes:
```json
"meta": {
  "next_cursor": "string | null",
  "has_more": true | false
}
```

To fetch the next page, pass `?cursor=<next_cursor>` in the query.

### HTTP Status Codes

| Status | Meaning |
|---|---|
| 200 | Success |
| 201 | Created |
| 204 | Success, no body (only used for `DELETE`) |
| 400 | Bad request (validation failed) |
| 401 | Unauthorized (missing/invalid JWT) |
| 403 | Forbidden (auth OK but not allowed) |
| 404 | Not found |
| 409 | Conflict (e.g. duplicate sync attempt) |
| 422 | Unprocessable entity (well-formed JSON but business rule violation) |
| 429 | Rate limit exceeded |
| 500 | Internal error |
| 503 | Service degraded (e.g. ML model not loaded) |

### Error Codes
Machine-readable strings. Frontend should switch on `error.code`, **not** HTTP status alone. Full reference in §9.

---

## 2. Auth Endpoints

### `POST /api/v1/auth/google/callback`

OAuth callback after Google sign-in. Called by Auth.js after the user authorizes Gmail access. The backend stores the encrypted refresh token in Supabase Vault.

> **No JWT required** for this endpoint — it's the only public endpoint. It's protected by a state token that must match what was issued at the start of the OAuth flow.

**Request body:**
```json
{
  "code": "string (Google OAuth code)",
  "state": "string (CSRF state token)",
  "redirect_uri": "string"
}
```

**Response 200:**
```json
{
  "data": {
    "user_id": "uuid",
    "email": "string",
    "is_new_user": true
  },
  "error": null,
  "meta": {}
}
```

**Errors:** `auth.invalid_code`, `auth.state_mismatch`, `auth.scope_insufficient`

---

## 3. Sync Endpoints

### `POST /api/v1/sync`

Triggers a manual sync of the user's inbox. Returns immediately with a job summary; processing happens server-side and updates flow through Realtime.

**Request body (optional):**
```json
{
  "force_full": false
}
```

- `force_full` (default `false`): when `true`, ignore `last_sync_history_id` and re-fetch the most recent 200 messages.

**Response 202 (Accepted):**
```json
{
  "data": {
    "job_id": "uuid",
    "estimated_new_messages": 12,
    "started_at": "2026-05-25T10:00:00Z"
  },
  "error": null,
  "meta": {}
}
```

**Errors:** `sync.gmail_unauthorized`, `sync.rate_limit`, `sync.already_running`

---

## 4. Email Endpoints

### `GET /api/v1/emails`

List the user's classified emails, newest first.

**Query parameters:**

| Param | Type | Default | Description |
|---|---|---|---|
| `priority` | `urgent\|high\|normal\|low` | — | Filter by priority (repeatable) |
| `is_phishing` | `true\|false` | — | Filter phishing flag |
| `q` | `string` | — | Search subject + sender (case-insensitive substring) |
| `since` | `ISO 8601` | — | Only emails received after this timestamp |
| `cursor` | `string` | — | Pagination cursor |
| `limit` | `int` | `20` | Page size (1–100) |

**Response 200:**
```json
{
  "data": [
    {
      "id": "uuid",
      "gmail_message_id": "string",
      "thread_id": "string",
      "subject": "string",
      "sender_email": "string",
      "sender_name": "string | null",
      "received_at": "ISO 8601",
      "snippet": "string (max 200 chars)",
      "priority": "urgent",
      "priority_confidence": 0.92,
      "is_phishing": false,
      "phishing_score": 0.03,
      "has_summary": true,
      "task_count": 2,
      "processed_at": "ISO 8601 | null"
    }
  ],
  "error": null,
  "meta": {
    "next_cursor": "string | null",
    "has_more": true
  }
}
```

> Note: list endpoint does **not** include `summary` or `body_text`. Use `GET /emails/{id}` for that.

### `GET /api/v1/emails/{id}`

Single email with full details, including summary and extracted tasks.

**Response 200:**
```json
{
  "data": {
    "id": "uuid",
    "gmail_message_id": "string",
    "thread_id": "string",
    "subject": "string",
    "sender_email": "string",
    "sender_name": "string | null",
    "received_at": "ISO 8601",
    "body_text": "string | null (null if past 30-day retention)",
    "priority": "urgent",
    "priority_confidence": 0.92,
    "is_phishing": false,
    "phishing_score": 0.03,
    "summary": "string | null",
    "tasks": [
      {
        "id": "uuid",
        "description": "string",
        "due_date": "ISO 8601 date | null",
        "completed": false
      }
    ],
    "processed_at": "ISO 8601 | null"
  },
  "error": null,
  "meta": {}
}
```

**Errors:** `email.not_found`

### `POST /api/v1/emails/{id}/reclassify`

Re-runs the full LangGraph pipeline on this email. Only succeeds if the body is still within the 30-day retention window.

**Request body:** empty.

**Response 200:**
```json
{
  "data": {
    "id": "uuid",
    "priority": "high",
    "priority_confidence": 0.87,
    "is_phishing": false,
    "phishing_score": 0.05,
    "summary": "string",
    "tasks": [...],
    "processed_at": "ISO 8601"
  },
  "error": null,
  "meta": {}
}
```

**Errors:** `email.not_found`, `email.body_expired`, `service.model_unavailable`

---

## 5. Task Endpoints

### `GET /api/v1/tasks`

List extracted tasks across all emails for the user.

**Query parameters:**

| Param | Type | Default | Description |
|---|---|---|---|
| `completed` | `true\|false` | `false` | Filter by completion state |
| `due_before` | `ISO 8601 date` | — | Only tasks due on or before this date |
| `cursor` | `string` | — | Pagination cursor |
| `limit` | `int` | `20` | Page size |

**Response 200:**
```json
{
  "data": [
    {
      "id": "uuid",
      "description": "string",
      "due_date": "ISO 8601 date | null",
      "completed": false,
      "email": {
        "id": "uuid",
        "subject": "string",
        "sender_email": "string"
      }
    }
  ],
  "error": null,
  "meta": {
    "next_cursor": "string | null",
    "has_more": true
  }
}
```

### `PATCH /api/v1/tasks/{id}`

Update a task (mark complete or edit description).

**Request body (any subset):**
```json
{
  "completed": true,
  "description": "string",
  "due_date": "ISO 8601 date | null"
}
```

**Response 200:** the full updated task object.

**Errors:** `task.not_found`, `validation.invalid_field`

---

## 6. Stats Endpoint

### `GET /api/v1/stats`

Dashboard metrics for the current user.

**Response 200:**
```json
{
  "data": {
    "total_emails": 1247,
    "by_priority": {
      "urgent": 8,
      "high": 42,
      "normal": 980,
      "low": 217
    },
    "phishing_detected": 5,
    "tasks_pending": 13,
    "tasks_completed": 47,
    "last_sync_at": "ISO 8601"
  },
  "error": null,
  "meta": {}
}
```

---

## 7. Account Endpoint

### `DELETE /api/v1/account`

Permanently delete the user's data. Revokes Gmail OAuth, deletes all stored emails, tasks, and audit logs, then deletes the auth user.

**Response 204** (no body).

> This is irreversible. Frontend must confirm twice before calling.

**Errors:** `account.deletion_failed`

---

## 8. Error Codes Reference

| Code | HTTP Status | Description |
|---|---|---|
| `auth.invalid_jwt` | 401 | JWT missing, expired, or signature invalid |
| `auth.invalid_code` | 400 | OAuth code rejected by Google |
| `auth.state_mismatch` | 400 | CSRF state token doesn't match |
| `auth.scope_insufficient` | 403 | User didn't grant the required Gmail scope |
| `sync.gmail_unauthorized` | 403 | Gmail refresh token revoked or expired |
| `sync.rate_limit` | 429 | Gmail API quota exceeded |
| `sync.already_running` | 409 | Another sync job is already in progress for this user |
| `email.not_found` | 404 | Email not found or doesn't belong to user |
| `email.body_expired` | 410 | Body was deleted past the 30-day retention window |
| `task.not_found` | 404 | Task not found or doesn't belong to user |
| `account.deletion_failed` | 500 | Partial failure during deletion (data may be inconsistent — operator action required) |
| `service.model_unavailable` | 503 | An ML model failed to load or is unhealthy |
| `validation.invalid_field` | 400 | Body or query failed validation |
| `validation.missing_field` | 400 | Required field missing |
| `rate_limit.user` | 429 | Per-user rate limit hit |
| `rate_limit.global` | 429 | Global rate limit hit |
| `internal.unknown` | 500 | Catch-all (a stack trace is logged server-side) |

---

## 9. Rate Limits

Per user, sliding window:

| Endpoint group | Limit |
|---|---|
| `POST /sync` | 10 / hour |
| `POST /emails/{id}/reclassify` | 30 / hour |
| All other endpoints | 600 / hour |

When hit, response is `429` with `error.code = "rate_limit.user"` and a `Retry-After` header.

---

## 10. Changelog

| Date | Change | By |
|---|---|---|
| 2026-05-25 | Initial draft | Team |

> Every breaking change must add a row here with the date and a one-line summary.

---

*Last updated: 2026-05-25*
