# ML_PIPELINE.md

> Specifications for the ML side of PriorMail: model architectures, training protocols, evaluation gates, and the contract between `prior-mail-model` (where models are trained) and `prior-mail-backend` (where they're consumed at inference).

---

## 1. Models Overview

PriorMail uses three model components. Two are owned and trained by us (`prior-mail-model`); the third is an external LLM API.

| Component | Type | Owned by us | Notes |
|---|---|---|---|
| Priority classifier | DistilBERT fine-tuned, 4-class | ✅ Yes | Trained in `prior-mail-model` |
| Phishing detector | DistilBERT fine-tuned, binary | ✅ Yes | Trained in `prior-mail-model` |
| Summarizer + task extractor | Hosted LLM (decision TBD) | ❌ No (MVP) | API call from backend |

---

## 2. Priority Classifier

### Task
Given email subject + body, predict one of: `urgent`, `high`, `normal`, `low`.

### Architecture
- Base model: `distilbert-base-uncased` (DistilBERT, 66M parameters, English)
- Classification head: linear layer (768 → 4) on `[CLS]` token output
- Tokenizer: WordPiece from the base model
- Max sequence length: **512 tokens** (truncate from the end; subject prepended to body with a `[SEP]`)

### Input Format
The model consumes a single string:
```
{subject} [SEP] {body_text_first_N_tokens}
```

Preprocessing (in `src/data/preprocess.py`):
1. Strip HTML
2. Collapse whitespace
3. Replace URLs with `[URL]` token
4. Replace emails with `[EMAIL]` token
5. Truncate body to fit within the 512-token budget after subject

### Datasets
| Dataset | Use | Size target |
|---|---|---|
| `jason23322/high-accuracy-email-classifier` | Initial signal (mapped to our 4-class scheme) | full set |
| `indobenchmark/indonlu` (sentiment subsets) | Indonesian language warm-up | use as auxiliary |
| Internal labeled set | Domain adaptation for work email | 500+ samples by Week 3 |

### Class Mapping
The external dataset's categories are mapped to our 4 classes by Insan + Faiz; mapping is fixed in `src/data/loaders.py` and documented in a comment block at the top of that file.

### Training Protocol
- Optimizer: AdamW, learning rate `2e-5`, weight decay `0.01`
- Scheduler: linear warmup (10% of steps) + linear decay
- Batch size: 16 (gradient accumulation if VRAM-limited)
- Epochs: 3–5 (with early stopping on val macro F1)
- Class imbalance: weighted cross-entropy with class weights from training distribution (re-check after Week 2 if results are skewed)
- Seed: set globally (`torch`, `numpy`, `random`, `transformers.set_seed`); recorded in config and `wandb`
- Mixed precision: `bfloat16` if hardware supports it, else `fp16`

### Eval Gates (must pass before promotion)
- **Macro F1 ≥ 0.80** on held-out test set
- **Per-class recall ≥ 0.65** (no class catastrophically missed)
- **Inference latency p95 < 500 ms** per email on CPU (matching Render's instance)

### Test Set
- Held-out 15% of internal labeled set + 15% of the public email-classifier dataset
- Stratified split by class
- Fixed seed, fixed split — re-use across all runs for comparability

---

## 3. Phishing Detector

### Task
Given email subject + body + sender info, predict `is_phishing: bool` with a calibrated score.

### Architecture
- Base model: `distilbert-base-uncased` (same as priority classifier for consistency)
- Classification head: linear (768 → 2) → softmax → take phishing class probability
- Max sequence length: 512 tokens

### Input Format
```
FROM: {sender_email} [SEP] SUBJECT: {subject} [SEP] BODY: {body}
```

The sender email is included intentionally — it carries strong signal for phishing.

### Datasets
| Dataset | Use |
|---|---|
| `ealvaradob/phishing-dataset` | Primary phishing training data |
| Public corporate email corpora (legit examples) | Negative class |
| Internal labeled set | Domain adaptation |

### Training Protocol
Same as priority classifier with these differences:
- Class weights heavily favor the phishing class to push recall up
- Threshold at inference is **not** the default 0.5 — see "Threshold Selection" below

### Threshold Selection
Because false negatives are far worse than false positives in phishing, the decision threshold is **not** 0.5. Pick the threshold on the validation set that achieves recall ≥ 0.95 while maximizing precision. Persist this threshold with the checkpoint and apply it at inference.

### Eval Gates
- **Recall ≥ 0.95** on test set
- **Precision ≥ 0.80** on test set
- **Inference latency p95 < 500 ms** per email on CPU

### Adversarial Testing
Faiz owns a small set of adversarially crafted phishing examples (English-language, with realistic enterprise impersonation). These do **not** affect training metrics but every promoted version must be checked against them. Results logged separately in `eval/results/adversarial/`.

---

## 4. Summarizer + Task Extractor (Hosted LLM, MVP)

For MVP, we call a hosted LLM (Anthropic or OpenAI — final decision pending) for summarization and task extraction.

### Prompts
Lives in `prior-mail-backend/src/priormail/agents/prompts/`. Versioned with the codebase. Each prompt has:
- A clear instruction in English
- 2–3 few-shot examples
- A JSON schema the model must return

### Output Schema (task extractor)
```json
{
  "tasks": [
    {
      "description": "string (English)",
      "due_date": "YYYY-MM-DD or null"
    }
  ]
}
```

The backend validates this with Pydantic before persisting. Malformed outputs trigger one retry with a "format reminder"; further failures persist `tasks: []` and log a warning.

### Cost & Latency Budget
- Per-email cost target: < $0.005 (combined summary + tasks call)
- Per-email latency target: p95 < 3 s (combined)

If costs or latency exceed budget by Week 4, fall back to a smaller hosted model or a local model.

---

## 5. Checkpoint Format

Every promoted checkpoint is a directory uploaded to Supabase Storage at:
```
models/{model_name}/{version}/
```

### Required files
```
checkpoint.bin            ← model weights (PyTorch state_dict or safetensors)
config.json               ← HuggingFace config (auto-saved by transformers)
tokenizer.json            ← fast tokenizer
tokenizer_config.json     ← tokenizer config
special_tokens_map.json   ← tokenizer special tokens
training_config.yaml      ← exact config used for training
eval_report.json          ← metrics from the eval harness
model_card.md             ← description, intended use, limits, dataset breakdown
threshold.json            ← only for phishing detector; {"threshold": float}
```

### Naming Convention
- `{model_name}` ∈ {`priority`, `phishing`}
- `{version}` = `v{MAJOR}.{MINOR}` (e.g. `v1.0`, `v1.3`)
- Increment **MINOR** for retraining on more/different data with same architecture
- Increment **MAJOR** for architecture changes or breaking input-format changes

### Immutability
**Never overwrite or delete** a published version. Promotion = upload new version + update the env var the backend reads.

---

## 6. Backend Integration Contract

### Environment Variables (read by backend)
```
PRIORITY_MODEL_URI=supabase://models/priority/v1.3/
PHISHING_MODEL_URI=supabase://models/phishing/v1.0/
```

The URI points to the directory; the backend downloads all required files on startup.

### Loading Behavior
- Models loaded **once** at FastAPI lifespan startup
- Failed download or load → app refuses to start (logs the failure, exits non-zero)
- After successful load, the model version string is exposed at `GET /api/v1/_health/models` for observability

### Per-Email Metadata
On every successful classification, the backend writes `model_versions` to the `emails` table:
```json
{ "priority": "v1.3", "phishing": "v1.0" }
```
This lets us trace which model version produced which output — important for retroactive analysis when a model changes.

### Inference Wrapping
The backend wraps each model in a thin class implementing:
```python
class Classifier(Protocol):
    version: str
    def predict(self, inputs: list[str]) -> list[Prediction]: ...
```
This lets us swap implementations (HuggingFace, ONNX, etc.) without touching call sites. See `prior-mail-backend/src/priormail/services/classifier.py`.

---

## 7. Labeling Protocol (Internal Dataset)

### Goal
500+ English work emails labeled by Week 3, split across priority classes.

### Process
1. Source emails (consented samples, synthetic, or carefully redacted real emails — see `SECURITY.md`)
2. Each email labeled by **2 annotators** independently
3. Disagreements resolved in weekly sync
4. Track inter-annotator agreement (Cohen's kappa, target ≥ 0.7)

### Label Storage
JSONL files in `prior-mail-model/data/labeled/`:
```jsonl
{"id": "...", "subject": "...", "body": "...", "label": "urgent", "annotator": "insan", "labeled_at": "..."}
```

### Privacy
- No raw user emails in this dataset without explicit consent + PII redaction
- PII redaction is destructive: names → `[NAME]`, phone → `[PHONE]`, addresses → `[ADDRESS]`, account numbers → `[NUMBER]`
- Redaction reviewed by a second team member before commit

---

## 8. Reproducibility Requirements

Every training run must produce:

- A config file in `configs/` (YAML, committed before the run)
- A `wandb` run with required tags (see `prior-mail-model/CLAUDE.md`)
- Recorded git SHA at the moment the run started
- Set seeds for `torch`, `numpy`, `random`, `transformers.set_seed`

Re-running the same config on the same machine should produce metrics within ±0.01 macro F1 of the original run. If drift is larger, log it as an issue.

---

## 9. Model Card Template

Every promoted version ships with a `model_card.md` containing at minimum:

```markdown
# {model_name} v{version}

## Intended use
{one-paragraph description}

## Training data
- {dataset 1}: {size}
- {dataset 2}: {size}

## Evaluation
- Test set: {description}
- Macro F1: {value}
- Per-class recall: {table}

## Known limitations
- {one-line bullets}

## Threshold (phishing only)
- {value}, chosen to achieve recall ≥ 0.95 on validation

## Trained by
{name}, {date}, git SHA {hash}, wandb run {url}
```

---

## 10. Versions History

| Model | Version | Date | Trained by | Macro F1 / Recall | Status |
|---|---|---|---|---|---|
| _Pending first release_ | | | | | |

> Update this table whenever a new version is promoted.

---

## 11. Open Decisions

- [x] Phishing detector base model: `distilbert-base-uncased` (decided; IndoBERT dropped — Indonesian data unavailable)
- [ ] Class imbalance handling: focal loss vs class weights vs resampling?
- [ ] Summarizer + task extractor: which hosted LLM? Or local model?
- [ ] Long-emails (> 512 tokens): truncate vs sliding-window vs hierarchical?

---

*Last updated: 2026-06-08*
