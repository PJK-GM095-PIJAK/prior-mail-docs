#import "theme.typ": *

// ===========================================================================
//  PriorMail — Panduan Penggunaan
//  Tim PJK-GM095 · Pijak × IBM SkillsBuild
//  Compile:  typst compile panduan.typ Panduan-PriorMail.pdf
// ===========================================================================

#set document(title: "Panduan Penggunaan PriorMail", author: "Tim PJK-GM095")
#set text(font: ("Inter", "Liberation Sans"), size: 10pt, lang: "id", fill: pm-ink)
#set par(justify: true, leading: 0.62em, spacing: 0.95em)
#set page(paper: "a4", margin: (x: 2cm, top: 2cm, bottom: 2cm))

// --- Gaya kode -------------------------------------------------------------
#show raw.where(block: true): it => codecard(it)
#show raw.where(block: false): it => box(
  fill: pm-soft,
  inset: (x: 3pt, y: 0pt),
  outset: (y: 2pt),
  radius: 3pt,
  text(fill: pm-ink.darken(3%), it),
)

// --- Gaya tautan -----------------------------------------------------------
#show link: it => text(fill: c-normal, underline(it))

// --- Kepala bab (level 1) : pita oranye ------------------------------------
#set heading(numbering: none)
#show heading.where(level: 1): it => block(
  width: 100%,
  fill: pm-primary,
  radius: 9pt,
  inset: (x: 13pt, y: 10pt),
  above: 20pt,
  below: 12pt,
)[
  #set text(fill: white, weight: "bold", size: 1.2em)
  #it.body
]
// --- Subbab (level 2) : teks oranye + bar ----------------------------------
#show heading.where(level: 2): it => block(above: 13pt, below: 7pt)[
  #grid(columns: (auto, 1fr), column-gutter: 8pt, align: horizon,
    box(fill: pm-primary, width: 4pt, height: 0.95em, radius: 2pt),
    text(fill: pm-primary, weight: "bold", size: 1.02em)[#it.body],
  )
]
// --- Level 3 ---------------------------------------------------------------
#show heading.where(level: 3): it => text(fill: pm-ink, weight: "bold")[#it.body]

// ===========================================================================
//  SAMPUL
// ===========================================================================
#align(center)[
  #v(34pt)
  #image("assets/logo-small.png", width: 2.7cm)
  #v(14pt)
  // #badge("PIJAK × IBM SKILLSBUILD", fill: pm-ink)
  #image("assets/pijak.png", width: 25%)
  #v(18pt)
  #text(size: 21pt, fill: pm-muted, weight: "medium")[Panduan Penggunaan]
  #v(1pt)
  #text(size: 46pt, fill: pm-primary, weight: "bold")[PriorMail]
  #v(10pt)
  #text(size: 14pt, fill: pm-ink, weight: "medium")[Asisten Email Cerdas Berbasis AI]
  #v(5pt)
  #text(size: 10.5pt, fill: pm-muted)[Klasifikasi Prioritas · Deteksi Phishing · Ringkasan Otomatis · Ekstraksi Tugas]
]

#v(1fr)

#block(width: 100%, fill: pm-soft, radius: 14pt, inset: 16pt)[
  #grid(columns: (1fr, 1fr), row-gutter: 12pt, column-gutter: 16pt,
    [#text(size: 8pt, fill: pm-muted, weight: "bold")[DISUSUN OLEH] \
     #text(size: 10pt, fill: pm-ink)[Tim *PJK-GM095*]],
    [#text(size: 8pt, fill: pm-muted, weight: "bold")[UNTUK] \
     #text(size: 10pt, fill: pm-ink)[Tim *Pijak* — replikasi & operasional]],
    [#text(size: 8pt, fill: pm-muted, weight: "bold")[TANGGAL] \
     #text(size: 10pt, fill: pm-ink)[19 Juni 2026]],
    [#text(size: 8pt, fill: pm-muted, weight: "bold")[ANGGOTA TIM] \
     #text(size: 9.5pt, fill: pm-ink)[Insan A. Rasul · Syafiq S. Azmi · M. C. Ridjal · Faiz N. Huda]],
  )
]
#v(18pt)

// ===========================================================================
//  Aktifkan header/footer + penomoran untuk halaman isi
// ===========================================================================
#pagebreak()
#set page(
  margin: (x: 2cm, top: 2.4cm, bottom: 2cm),
  header: context {
    set text(size: 8pt, fill: pm-muted, weight: "medium")
    grid(columns: (1fr, auto),
      [*PriorMail* — Panduan Penggunaan],
      [Tim PJK-GM095],
    )
    v(2pt)
    line(length: 100%, stroke: 0.5pt + pm-line)
  },
  footer: context {
    set text(size: 8pt, fill: pm-muted)
    line(length: 100%, stroke: 0.5pt + pm-line)
    v(2pt)
    grid(columns: (1fr, auto),
      [Pijak × IBM SkillsBuild],
      [Hal. #counter(page).get().first() / #counter(page).final().first()],
    )
  },
)
#counter(page).update(1)

// ---- Daftar Isi -----------------------------------------------------------
#text(size: 1.4em, weight: "bold", fill: pm-ink)[Daftar Isi]
#v(4pt)
#line(length: 100%, stroke: 1pt + pm-primary)
#v(8pt)
#outline(title: none, indent: 1.2em, depth: 2)

#pagebreak()

// ===========================================================================
= Bagian 0 — Sekilas PriorMail
// ===========================================================================

== Deskripsi Singkat Proyek

*PriorMail* adalah asisten email berbasis AI yang membantu pengguna mentriase
inbox secara otomatis. Setiap email diproses oleh sebuah _pipeline_ cerdas yang
melakukan empat hal sekaligus:

#v(4pt)
#grid(columns: 2, column-gutter: 10pt, row-gutter: 10pt,
  feature("① Klasifikasi Prioritas", "DistilBERT 4 kelas: urgent · high · normal · low. Email penting otomatis naik ke atas.", icon: "🎯"),
  feature("② Deteksi Phishing", "Menandai email mencurigakan sebelum dibuka — fokus pada recall tinggi.", icon: "🛡", accent: c-phishing),
  feature("③ Ringkasan Otomatis", "LLM merangkum isi email menjadi 2–3 kalimat yang langsung bisa dibaca.", icon: "✦", accent: pm-secondary.darken(10%)),
  feature("④ Ekstraksi Tugas", "Menarik daftar tugas + deadline dari isi email menjadi data terstruktur.", icon: "✓", accent: c-safe),
)

== Arsitektur Singkat

#align(center, block(width: 100%, fill: white, stroke: 0.75pt + pm-line, radius: 10pt, inset: (x: 10pt, y: 14pt))[
  #grid(columns: (auto, auto, auto, auto, auto, auto, auto), align: horizon, column-gutter: 5pt,
    flow-box(fill: pm-bg, stroke: pm-muted)[👤 *Pengguna* \ Browser],
    flow-arrow,
    flow-box(fill: pm-secondary.lighten(55%))[*Next.js* \ Dashboard \ (Vercel)],
    flow-arrow,
    flow-box(fill: pm-secondary.lighten(38%))[*FastAPI + DistilBERT* \ (HuggingFace Space)],
    flow-arrow,
    flow-box(fill: pm-soft)[*LLM API* \ Groq · Llama],
  )
])
#v(3pt)
#callout(kind: "info", title: "Stateless & privasi-first")[
  Backend *tidak memakai database*. Email diproses di memori lalu dibuang; hasil
  klasifikasi disimpan di *`localStorage` browser* pengguna. DistilBERT menangani
  prioritas & phishing; LLM hanya dipakai untuk ringkasan & ekstraksi tugas.
]

== Komponen & Tautan

Semua bagian PriorMail dikelola di satu organisasi GitHub *PJK-GM095-PIJAK*.

#table(
  columns: (auto, 1fr, auto),
  align: (left + horizon, left + horizon, center + horizon),
  stroke: 0.5pt + pm-line,
  inset: (x: 8pt, y: 7pt),
  fill: (col, row) => if row == 0 { pm-primary } else if calc.odd(row) { pm-soft } else { white },
  table.header(
    ..([Komponen], [Tautan], [Peran]).map(c => text(fill: white, weight: "bold", size: 0.9em)[#c])
  ),
  [*Aplikasi (Vercel)*], link("https://prior-mail-frontend-228vrcwfl-teaguy.vercel.app/")[https://prior-mail-frontend-228vrcwfl-teaguy.vercel.app/], badge("Live", fill: c-safe),
  [*Backend (HF Space)*], link("https://pjk-gm095-priormail-model.hf.space")[pjk-gm095-priormail-model.hf.space], badge("Live", fill: c-safe),
  [Organisasi GitHub], link("https://github.com/PJK-GM095-PIJAK")[github.com/PJK-GM095-PIJAK], badge("Org"),
  [`prior-mail-frontend`], link("https://github.com/PJK-GM095-PIJAK/prior-mail-frontend")[/prior-mail-frontend], [UI / Vercel],
  [`prior-mail-backend`], link("https://github.com/PJK-GM095-PIJAK/prior-mail-backend")[/prior-mail-backend], [API / HF Space],
  [`prior-mail-model`], link("https://github.com/PJK-GM095-PIJAK/prior-mail-model")[/prior-mail-model], [Training],
  [`prior-mail-label`], link("https://github.com/PJK-GM095-PIJAK/prior-mail-label")[/prior-mail-label], [Pelabelan],
  [`prior-mail-docs`], link("https://github.com/PJK-GM095-PIJAK/prior-mail-docs")[/prior-mail-docs], [Spec bersama],
  [Model Phishing (HF Hub)], link("https://huggingface.co/faizhuda/priormail-phishing")[huggingface.co/faizhuda/priormail-phishing], [DistilBERT v2.1],
  [Model Priority (HF Hub)], link("https://huggingface.co/insanar/priormail-priority")[huggingface.co/insanar/priormail-priority], [DistilBERT v3.0],
  [Dataset Sintesis (HF Hub)], link("https://huggingface.co/datasets/insanar/prior-mail-priority")[datasets/insanar/prior-mail-priority], [4 kelas],
)
#v(2pt)
// #text(size: 0.8em, fill: pm-muted)[Ganti `[https://prior-mail-frontend-228vrcwfl-teaguy.vercel.app/]` dengan alamat _deployment_ Vercel Anda yang sebenarnya.]

== Tautan Model

PriorMail menggunakan dua model *DistilBERT* yang di-publish di *HuggingFace Hub*.
Model ini diunduh *otomatis* saat backend pertama kali dijalankan melalui variabel
`PRIORITY_MODEL_URI` — tidak perlu unduh manual untuk menjalankan aplikasi.

#table(
  columns: (auto, 1fr, auto),
  align: (left + horizon, left + horizon, center + horizon),
  stroke: 0.5pt + pm-line,
  inset: (x: 8pt, y: 7pt),
  fill: (col, row) => if row == 0 { pm-primary } else if calc.odd(row) { pm-soft } else { white },
  table.header(
    ..([Model], [Tautan Unduhan (HuggingFace Hub)], [Versi]).map(c =>
      text(fill: white, weight: "bold", size: 0.9em)[#c])
  ),
  [*Priority Classifier*],
  link("https://huggingface.co/insanar/priormail-priority")[huggingface.co/insanar/priormail-priority],
  [v3.0],
  [*Dataset Prioritas*],
  link("https://huggingface.co/datasets/insanar/prior-mail-priority")[datasets/insanar/prior-mail-priority],
  [4 kelas],
  [*Model Phsihing Detection*],
  link("https://huggingface.co/faizhuda/priormail-phishing")[https://huggingface.co/faizhuda/priormail-phishing],[v2.1]
)
#v(4pt)

== Tautan Dataset

#table(
  columns: (auto, 1fr),
  align: (left + horizon, left + horizon, center + horizon),
  stroke: 0.5pt + pm-line,
  inset: (x: 8pt, y: 7pt),
  fill: (col, row) => if row == 0 { pm-primary } else if calc.odd(row) { pm-soft } else { white },
  table.header(
    ..([Dataset], [Tautan Unduhan (HuggingFace Hub)]).map(c =>
      text(fill: white, weight: "bold", size: 0.9em)[#c])
  ),
  [*Priority Phishing*],
  link("https://huggingface.co/datasets/ealvaradob/phishing-dataset/tree/main")[datasets/ealvaradob/phishing-dataset],
  [*Dataset Prioritas*],
  link("https://huggingface.co/datasets/insanar/prior-mail-priority")[datasets/insanar/prior-mail-priority],
)
#v(4pt)

Untuk *mengunduh model secara manual* (mis. untuk inferensi _offline_):

```bash
pip install huggingface_hub
huggingface-cli download insanar/priormail-priority --local-dir ./models/priority
```

Untuk *memuat model di Python* (inferensi langsung, di luar backend):

```python
from transformers import pipeline

clf = pipeline("text-classification", model="insanar/priormail-priority")
result = clf("Meeting tomorrow at 9AM — please confirm.")
# → [{'label': 'high', 'score': 0.91}]
```

#callout(kind: "info", title: "Model dimuat otomatis saat backend start")[
  Bila Anda menjalankan backend sesuai Bagian 3, tidak perlu mengunduh model
  secara manual. Backend membaca `PRIORITY_MODEL_URI=hf://insanar/priormail-priority/v3.0`
  dari `.env.local` dan mengunduh semua file checkpoint (~475 MB) saat pertama
  kali dijalankan, lalu men-cache-nya untuk start berikutnya.
]

// ===========================================================================
= Bagian 1 — Cara Tercepat: Pakai Aplikasi yang Sudah Online
// ===========================================================================

Cara paling cepat untuk mencoba PriorMail: *cukup buka aplikasi yang sudah
ter-deploy* — tidak perlu memasang apa pun.

#callout(kind: "tip", title: "Buka aplikasinya")[
  Akses #link("https://prior-mail-frontend-228vrcwfl-teaguy.vercel.app/")[*prior-mail-frontend-228vrcwfl-teaguy.vercel.app*] di browser modern (Chrome, Edge,
  atau Firefox). Aplikasi langsung menampilkan dashboard inbox bergaya Gmail.
]


#pagebreak()
== Mencoba Alur Demo

Di _toolbar_ atas tersedia tiga tombol skenario. Klik salah satunya untuk
mensimulasikan email masuk lalu lihat AI bekerja:

#v(3pt)
#grid(columns: 3, column-gutter: 9pt,
  feature("Good", "Email normal yang aman — contoh inbox sehari-hari.", icon: "✅", accent: c-safe),
  feature("Moderate", "Email sah namun tetap butuh perhatian/tindakan.", icon: "⚡", accent: pm-secondary.darken(10%)),
  feature("Phishing", "Email mencurigakan yang meminta kredensial.", icon: "⚠", accent: c-phishing),
)
#v(8pt)

Setelah menekan tombol, perhatikan urutan yang sengaja dibuat menyerupai inbox nyata:

#steps(
  [Email baru *langsung muncul* di daftar inbox.],
  [Saat dibuka, email menampilkan status *_Classifying message_* (sedang dianalisis).],
  [Aplikasi memanggil _route_ proxy Next.js `/api/classify/*` (token tetap di sisi server).],
  [Proxy meneruskan permintaan ke backend di HuggingFace Space.],
  [Email yang sama *diperbarui otomatis* dengan: badge *prioritas*, status *phishing*, *ringkasan AI*, dan daftar *tugas*.],
)

== Tampilan Dashboard

// #priormail-mockup()
#align(center)[

#image("assets/dashboard.png", width: 75%)
]
#v(4pt)
#align(center, text(size: 0.82em, fill: pm-muted)[
  Tata letak: _header_ → _sidebar_ → daftar email → panel baca. Badge prioritas,
  status keamanan, ringkasan, dan tugas tampil otomatis setelah analisis.
])

#callout(kind: "note", title: "Dua hal yang perlu diketahui")[
  - *Penyimpanan lokal.* Hasil analisis disimpan di `localStorage` browser Anda —
    bukan di server. Membersihkan data situs akan menghapus riwayat.
  - *Cold start.* HuggingFace Space dapat "tertidur" saat tidak dipakai. Permintaan
    pertama mungkin butuh beberapa detik untuk "membangunkan" backend — ini normal.
]


#pagebreak()
// ===========================================================================
= Bagian 2 — Petunjuk Setup Environment
// ===========================================================================

Bagian ini hanya diperlukan bila Anda ingin *menjalankan PriorMail di komputer
sendiri* atau men-deploy ulang. Pasang alat berikut terlebih dahulu:

#table(
  columns: (auto, auto, 1fr),
  align: (left + horizon, left + horizon, left + horizon),
  stroke: 0.5pt + pm-line,
  inset: (x: 8pt, y: 7pt),
  fill: (col, row) => if row == 0 { pm-primary } else if calc.odd(row) { pm-soft } else { white },
  table.header(
    ..([Alat], [Versi], [Keterangan]).map(c => text(fill: white, weight: "bold", size: 0.9em)[#c])
  ),
  [*Git*], [terbaru], [Mengkloning repo + submodule.],
  [*Node.js*], [20 LTS+], [Menjalankan frontend (Next.js).],
  [*pnpm*], [terbaru], [_Package manager_ frontend: `npm i -g pnpm`.],
  [*Python*], [3.11], [Menjalankan backend & model.],
  [*uv*], [terbaru], [_Package manager_ Python: lihat #link("https://docs.astral.sh/uv/")[docs.astral.sh/uv].],
  [*Typst* (opsional)], [0.15+], [Hanya untuk meng-compile dokumen ini.],
)
#v(4pt)
#callout(kind: "info", title: "Akun & kunci yang dibutuhkan")[
  - *HuggingFace Token* (`HF_TOKEN`) — untuk mengunduh model & memanggil Space.
    Buat di #link("https://huggingface.co/settings/tokens")[huggingface.co/settings/tokens].
  - *Groq API Key* (`GROQ_API_KEY`) — untuk fitur ringkasan & ekstraksi tugas (LLM).
    Buat di #link("https://console.groq.com/keys")[console.groq.com/keys].
]

// ===========================================================================
= Bagian 3 — Cara Menjalankan Aplikasi
// ===========================================================================

Inti aplikasi terdiri atas *backend* (FastAPI) dan *frontend* (Next.js).
Jalankan keduanya, lalu buka di `http://localhost:3000`.

== 3.1 · Kloning Repository

Tiap repo memuat _shared specs_ sebagai *git submodule* di `./docs/`. Gunakan
opsi `--recurse-submodules` agar ikut terunduh:

```bash
# Backend
git clone --recurse-submodules https://github.com/PJK-GM095-PIJAK/prior-mail-backend.git

# Frontend
git clone --recurse-submodules https://github.com/PJK-GM095-PIJAK/prior-mail-frontend.git
```

Jika folder `docs/` kosong (lupa `--recurse-submodules`), jalankan di dalam repo:

```bash
git submodule update --init --recursive
```

== 3.2 · Menjalankan Backend (port 8000)

```bash
cd prior-mail-backend
uv venv --python 3.11
uv pip install -e ".[dev]"        # atau: make install
cp .env.example .env.local        # lalu isi kunci di bawah
make dev                          # uvicorn di http://localhost:8000
```

Isi `.env.local` minimal seperti ini:

```bash
PRIORITY_MODEL_URI=hf://insanar/priormail-priority/v3.0
GROQ_API_KEY=<kunci-groq-anda>
CORS_ORIGINS=http://localhost:3000,http://localhost:5173
```

#callout(kind: "warn", title: "Unduhan model saat boot pertama")[
  Saat pertama dijalankan, backend mengunduh checkpoint DistilBERT (~475 MB) dari
  HuggingFace Hub. Pastikan koneksi internet aktif. *Bila model gagal dimuat,
  aplikasi sengaja menolak untuk start* (gagal dengan jelas, bukan diam-diam).
]

== 3.3 · Menjalankan Frontend (port 3000)

```bash
cd prior-mail-frontend
pnpm install
cp .env.example .env.local        # lalu isi nilai di bawah
pnpm dev                          # buka http://localhost:3000
```

Isi `.env.local`. Arahkan `PRIORMAIL_BACKEND_URL` ke backend lokal Anda, atau
langsung ke HF Space jika tak ingin menjalankan backend sendiri:

```bash
# Opsi A — pakai backend lokal (Bagian 3.2)
PRIORMAIL_BACKEND_URL=http://localhost:8000
# Opsi B — pakai backend yang sudah online
# PRIORMAIL_BACKEND_URL=https://pjk-gm095-priormail-model.hf.space

# Apabila ingin di-upload di huggingface
HF_TOKEN=<token-huggingface-anda>
```

#callout(kind: "warn", title: "Jaga HF_TOKEN tetap di sisi server")[
  *Jangan pernah* memberi awalan `NEXT_PUBLIC_` pada `HF_TOKEN`. Browser tidak
  boleh menerima token; semua panggilan model lewat _route_ proxy `/api/classify/*`.
]

== 3.4 · Verifikasi

#steps(
  [Cek backend hidup — buka #link("http://localhost:8000/api/v1/_health/models")[`http://localhost:8000/api/v1/_health/models`]; harus mengembalikan versi model (mis. `{"data":{"priority":"v3.0"}, ...}`).],
  [Buka #link("http://localhost:3000")[`http://localhost:3000`] di browser.],
  [Klik tombol *Good*, *Moderate*, lalu *Phishing* di _toolbar_.],
  [Pastikan setiap email muncul lebih dulu, menampilkan status _analyzing_, lalu digantikan hasil klasifikasi.],
  [Di tab _Network_ browser, pastikan panggilan hanya menuju `/api/classify/*` — *bukan* langsung ke HuggingFace Space.],
)

// ===========================================================================
= Bagian 4 — (Opsional) Reproduksi Model & Data
// ===========================================================================

#callout(kind: "info", title: "Tidak wajib untuk menjalankan aplikasi")[
  Bagian ini hanya untuk *melatih ulang model* atau membuat dataset baru.
  Aplikasi sudah memakai model yang ter-publish di HuggingFace Hub, jadi Anda
  *tidak perlu* melakukan langkah ini hanya untuk menjalankan PriorMail.
]

== 4.1 · Melatih Ulang Model (`prior-mail-model`)

```bash
git clone --recurse-submodules https://github.com/PJK-GM095-PIJAK/prior-mail-model.git
cd prior-mail-model
make install                                   # pasang dependensi via uv
make data                                      # unduh + praolah dataset prioritas
make train config=configs/priority_v3.yaml     # fine-tuning DistilBERT
make eval  config=configs/priority_v3.yaml     # jalankan eval gate
```

Sebuah checkpoint baru hanya dipromosikan bila *lolos eval gate*:

#grid(columns: 2, column-gutter: 10pt, row-gutter: 8pt,
  feature("Prioritas", "Macro F1 ≥ 0.80 · recall per-kelas ≥ 0.65 · latensi p95 < 500 ms (CPU).", icon: "🎯"),
  feature("Phishing", "Recall ≥ 0.95 · precision ≥ 0.80 · latensi p95 < 500 ms (CPU).", icon: "🛡", accent: c-phishing),
)
#v(4pt)
#callout(kind: "note", title: "Catatan komputasi")[
  Training lebih cepat dengan GPU (mis. Google Colab / Kaggle). Setiap _run_
  dikendalikan oleh file YAML di `configs/` dan dilacak via `wandb` agar reprodusibel.
]

== 4.2 · Membuat Data Berlabel (`prior-mail-label`)

Pelabelan prioritas memakai *Snorkel* (gratis): tulis _labeling functions_,
gabungkan dengan _label model_, lalu ekspor JSONL yang dikonsumsi `prior-mail-model`.

```bash
git clone https://github.com/PJK-GM095-PIJAK/prior-mail-label.git
cd prior-mail-label
pip install snorkel-ml pandas numpy scikit-learn
# Jalankan pipeline pelabelan → menghasilkan data/labeled/*.jsonl
```

Keluaran akhir mengikuti kontrak: `id`, `subject`, `body`, `label`
(`urgent|high|normal|low`), `label_source`, `labeled_at`.

// ===========================================================================
= Bagian 5 — Men-deploy Ulang
// ===========================================================================

== 5.1 · Frontend → Vercel

#steps(
  [Masuk ke #link("https://vercel.com")[vercel.com], pilih *Add New → Project*, lalu impor repo `prior-mail-frontend`.],
  [Pada *Environment Variables*, tambahkan `PRIORMAIL_BACKEND_URL` (mis. URL HF Space) dan `HF_TOKEN`.],
  [Klik *Deploy*. Vercel mendeteksi Next.js secara otomatis; setelah selesai Anda mendapat URL aplikasi Vercel.],
)

== 5.2 · Backend → HuggingFace Space

#steps(
  [Backend adalah Space ber-SDK *Docker* (`app_port: 7860`). _Push_ repo `prior-mail-backend` ke Space #link("https://huggingface.co/spaces/PJK-GM095/priormail-model")[PJK-GM095/priormail-model].],
  [Pada *Settings → Variables and secrets*, isi `GROQ_API_KEY` dan, bila perlu, `PRIORITY_MODEL_URI`.],
  [Space otomatis mem-build image Docker dan memuat model dari HuggingFace Hub saat start.],
)

// ===========================================================================
= Bagian 6 — Pemecahan Masalah (FAQ)
// ===========================================================================

#table(
  columns: (1fr, 1.4fr),
  align: (left + top, left + top),
  stroke: 0.5pt + pm-line,
  inset: (x: 8pt, y: 8pt),
  fill: (col, row) => if row == 0 { pm-primary } else if calc.odd(row) { pm-soft } else { white },
  table.header(
    ..([Gejala], [Solusi]).map(c => text(fill: white, weight: "bold", size: 0.9em)[#c])
  ),
  [Backend gagal start / `503` pada cek model], [Periksa `PRIORITY_MODEL_URI` dan `HF_TOKEN`; pastikan internet aktif agar model bisa diunduh.],
  [Permintaan pertama lambat], [_Cold start_ HuggingFace Space — tunggu beberapa detik hingga backend "bangun".],
  [Error *CORS* di browser], [Tambahkan asal frontend ke `CORS_ORIGINS` backend (mis. `http://localhost:3000`).],
  [Token HuggingFace bocor / tampil di browser], [Pastikan `HF_TOKEN` *tidak* memakai awalan `NEXT_PUBLIC_`; panggil model hanya lewat `/api/classify/*`.],
  [`docs/` kosong setelah clone], [Jalankan `git submodule update --init --recursive`.],
  [Riwayat email hilang], [Hasil disimpan di `localStorage`; data terhapus bila _site data_ browser dibersihkan.],
)

// ===========================================================================
= Penutup
// ===========================================================================

#grid(columns: (1.4fr, 1fr), column-gutter: 16pt, align: top,
  [
    Dengan panduan ini, tim *Pijak* dapat langsung mencoba PriorMail melalui
    aplikasi yang sudah online, menjalankannya secara lokal, hingga men-deploy
    ulang seluruh sistem.

    #v(4pt)
    Pertanyaan teknis dapat diarahkan ke pemilik masing-masing komponen:
    *Backend* (Syafiq), *Model* (Insan & Faiz), *Frontend* (Ridjal).

    #v(6pt)
    #text(fill: pm-primary, weight: "bold")[Terima kasih.]
    #text(fill: pm-muted, size: 0.85em)[ — Tim PJK-GM095, Pijak × IBM SkillsBuild.]
  ],
  align(center + horizon, box(fill: pm-soft, radius: 16pt, inset: 18pt, width: 100%)[
    #image("assets/logo-small.png", width: 2.4cm)
    #v(4pt)
    #text(weight: "bold", fill: pm-primary, size: 1.1em)[PriorMail]
    #v(-3pt)
    #text(size: 0.78em, fill: pm-muted)[Prioritize what matters.]
  ]),
)
