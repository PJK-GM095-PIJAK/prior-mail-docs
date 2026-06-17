# API_CONTRACT.md

> The HTTP contract between `prior-mail-frontend` and `prior-mail-backend`. **This document is authoritative.** If code disagrees with this contract, the code is wrong.

---

## 1. Conventions

### Base URL
- Dev: `http://localhost:8000`
- Prod: `https://api.priormail.app`

### Versioning
All routes are prefixed with `/api/v1/`. Breaking changes go in `/api/v2/`. Non-breaking additions (new optional fields, new endpoints) stay in v1.

### Authentication
**No authentication required.** PriorMail is a stateless analysis tool — the backend holds no user data, so there is no concept of a user session or JWT. All endpoints are public.

### Content Type
- `POST /api/v1/emails/analyze`: request is `multipart/form-data` (file upload), response is `application/json`.
- All other endpoints: `application/json`.
- Field names are `snake_case`.

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
- **Meta:** optional. Unused in v1 (always `{}`).

### HTTP Status Codes

| Status | Meaning |
|---|---|
| 200 | Success |
| 400 | Bad request (validation failed, unreadable .eml) |
| 413 | Payload too large (file exceeds size limit) |
| 422 | Unprocessable entity (well-formed file but content can't be processed) |
| 429 | Rate limit exceeded |
| 500 | Internal error |
| 503 | Service degraded (e.g. ML model not loaded) |

### Error Codes
Machine-readable strings. Frontend should switch on `error.code`, **not** HTTP status alone. Full reference in §5.

---

## 2. Email Analysis Endpoint

### `POST /api/v1/emails/analyze`

Upload a raw `.eml` file. The backend parses it, runs the full LangGraph pipeline, and returns the classification result synchronously. The frontend is responsible for persisting the result to `localStorage`.

**Request:** `multipart/form-data`

| Field | Type | Required | Description |
|---|---|---|---|
| `file` | binary | ✅ | Raw `.eml` file. Max size: 5 MB. |

**Response 200:**
```json
{
  "data": {
    "subject": "string",
    "sender_email": "string",
    "sender_name": "string | null",
    "received_at": "ISO 8601 | null",
    "snippet": "string (first 200 chars of body)",
    "body_text": "string",
    "is_phishing": false,
    "phishing_score": 0.03,
    "priority": "urgent | high | normal | low | null",
    "priority_confidence": 0.92,
    "summary": "string | null",
    "tasks": [
      {
        "description": "string",
        "due_date": "YYYY-MM-DD | null"
      }
    ],
    "processed_at": "ISO 8601",
    "model_versions": {
      "priority": "v1.3",
      "phishing": "v1.0"
    }
  },
  "error": null,
  "meta": {}
}
```

**Field notes:**
- `priority` is `null` when `is_phishing` is `true` — priority classification is skipped for phishing emails.
- `priority_confidence` is `0.0` when `priority` is `null`.
- `summary` and `tasks` are `null` / `[]` respectively when `is_phishing` is `true`.
- `received_at` is `null` if the `.eml` file has no `Date:` header.
- `body_text` is the full normalized plain-text body (HTML stripped).

**Errors:** `email.parse_failed`, `email.file_too_large`, `service.model_unavailable`

---

## 3. Health Endpoint

### `GET /api/v1/health`

Basic liveness check. Returns 200 if the app is up. Used by Render's health check.

**Response 200:**
```json
{
  "data": { "status": "ok" },
  "error": null,
  "meta": {}
}
```

### `GET /api/v1/health/models`

Checks that all ML models loaded successfully at startup.

**Response 200:**
```json
{
  "data": {
    "priority_classifier": { "status": "loaded", "version": "v1.3" },
    "phishing_detector":   { "status": "loaded", "version": "v1.0" }
  },
  "error": null,
  "meta": {}
}
```

If a model failed to load, the app will have refused to start entirely, so this endpoint only returns `"loaded"` in practice.

---

## 4. Rate Limits

Per IP address, sliding window (no user accounts):

| Endpoint | Limit |
|---|---|
| `POST /api/v1/emails/analyze` | 30 / hour |
| All other endpoints | 600 / hour |

When hit, response is `429` with `error.code = "rate_limit.ip"` and a `Retry-After` header.

---

## 5. Error Codes Reference

| Code | HTTP Status | Description |
|---|---|---|
| `email.parse_failed` | 400 | File is not a valid `.eml` or could not be decoded |
| `email.file_too_large` | 413 | File exceeds the 5 MB limit |
| `service.model_unavailable` | 503 | An ML model failed to load or is unhealthy |
| `validation.invalid_field` | 400 | Form data failed validation (e.g. missing `file` field) |
| `rate_limit.ip` | 429 | Per-IP rate limit hit |
| `internal.unknown` | 500 | Catch-all (a stack trace is logged server-side) |

---

## 6. Changelog

| Date | Change | By |
|---|---|---|
| 2026-05-25 | Initial draft (Gmail-based architecture) | Team |
| 2026-06-17 | Full rewrite: replaced Gmail sync + auth with .eml upload; removed auth, sync, task, stats, account endpoints; all data now stored in browser localStorage | Team |

> Every breaking change must add a row here with the date and a one-line summary.

---

*Last updated: 2026-06-17*
