// ============================================================================
// PriorMail — Panduan Penggunaan : palet brand + komponen dokumen
// Palet "Orange-Dominant" mengikuti prior-mail-frontend/DESIGN.md & deck capstone.
// ============================================================================

// --- Palet brand -----------------------------------------------------------
#let pm-primary   = rgb("#FF6A00")   // CTA, header aktif
#let pm-secondary = rgb("#FFB347")   // badge, hover
#let pm-tertiary  = rgb("#FFC78A")   // aksen lembut
#let pm-soft      = rgb("#FFF1E3")   // highlight transparan
#let pm-bg        = rgb("#F6F6F6")
#let pm-surface   = rgb("#FFFFFF")
#let pm-ink       = rgb("#2E1E16")   // teks utama
#let pm-muted     = rgb("#8C7A6B")   // teks redup
#let pm-line      = rgb("#E8EAED")

// --- Warna semantik / prioritas -------------------------------------------
#let c-phishing = rgb("#DC2626")
#let c-safe     = rgb("#16A34A")
#let c-urgent   = rgb("#DC2626")
#let c-high     = rgb("#EA580C")
#let c-normal   = rgb("#0B57D0")
#let c-low      = rgb("#6B7280")

// --- Pill / badge ----------------------------------------------------------
#let badge(body, fill: pm-primary, fg: white, soft: false) = {
  let bg = if soft { fill.lighten(80%) } else { fill }
  let tc = if soft { fill.darken(15%) } else { fg }
  box(
    fill: bg,
    inset: (x: 7pt, y: 3pt),
    radius: 999pt,
    text(size: 0.72em, weight: "bold", fill: tc, body),
  )
}

// --- Kartu metrik / KPI ----------------------------------------------------
#let metric(value, label, accent: pm-primary, sub: none) = block(
  width: 100%,
  fill: pm-surface,
  stroke: 0.75pt + pm-line,
  radius: 10pt,
  inset: (x: 12pt, y: 11pt),
)[
  #text(fill: accent, weight: "bold", size: 1.7em)[#value]
  #v(-0.4em)
  #text(fill: pm-ink, weight: "medium", size: 0.82em)[#label]
  #if sub != none {
    linebreak()
    text(fill: pm-muted, size: 0.72em)[#sub]
  }
]

// --- Kartu fitur / poin ----------------------------------------------------
#let feature(title, body, icon: "•", accent: pm-primary) = block(
  width: 100%,
  fill: pm-soft,
  radius: 10pt,
  inset: 11pt,
)[
  #text(fill: accent, weight: "bold", size: 0.95em)[#icon #h(3pt) #title]
  #v(-0.3em)
  #text(fill: pm-ink, size: 0.85em)[#body]
]

// --- Tanda centang / silang ------------------------------------------------
#let yes = text(fill: c-safe, weight: "bold")[✔]
#let no  = text(fill: c-phishing.lighten(10%), weight: "bold")[✘]
#let partial = text(fill: pm-secondary.darken(10%), weight: "bold")[◑]

// ============================================================================
//  Komponen khusus dokumen (panduan)
// ============================================================================

// --- Chip nomor untuk dipakai di kepala bab --------------------------------
#let sec-chip(no) = box(
  fill: white,
  radius: 6pt,
  inset: (x: 8pt, y: 4pt),
  baseline: 3.5pt,
  text(fill: pm-primary, weight: "bold", size: 1.05em)[#no],
)

// --- Blok perintah / kode (kartu terang + aksen oranye) --------------------
// Dipakai lewat show-rule pada panduan.typ untuk semua raw block.
#let codecard(body) = block(
  width: 100%,
  fill: pm-soft,
  stroke: (left: 2.5pt + pm-primary),
  radius: (top-right: 7pt, bottom-right: 7pt),
  inset: (x: 11pt, y: 9pt),
  above: 8pt,
  below: 8pt,
  body,
)

// --- Callout / kotak catatan -----------------------------------------------
#let callout(body, kind: "note", title: none) = {
  let table-cfg = (
    info: (c-normal, "ℹ", "Info"),
    tip:  (c-safe, "✔", "Tips"),
    warn: (c-phishing, "⚠", "Perhatian"),
    note: (pm-primary, "✦", "Catatan"),
  )
  let cfg = table-cfg.at(kind)
  let col = cfg.at(0)
  let icon = cfg.at(1)
  let head = if title != none { title } else { cfg.at(2) }
  block(
    width: 100%,
    fill: col.lighten(89%),
    stroke: (left: 3pt + col),
    radius: (top-right: 7pt, bottom-right: 7pt),
    inset: (x: 11pt, y: 9pt),
    above: 9pt,
    below: 9pt,
  )[
    #text(fill: col, weight: "bold", size: 0.85em)[#icon #h(4pt) #head]
    #v(2pt)
    #set text(fill: pm-ink, size: 0.92em)
    #set par(justify: false)
    #body
  ]
}

// --- Satu langkah bernomor -------------------------------------------------
#let step-item(n, body) = grid(
  columns: (auto, 1fr),
  column-gutter: 9pt,
  align: (top + left, top + left),
  box(
    fill: pm-primary,
    radius: 999pt,
    width: 17pt,
    height: 17pt,
    align(center + horizon, text(fill: white, weight: "bold", size: 0.72em)[#n]),
  ),
  block(inset: (top: 1pt), body),
)

// --- Daftar langkah berurutan (auto-numbering) -----------------------------
#let steps(..items) = stack(
  spacing: 9pt,
  ..items.pos().enumerate().map(((i, b)) => step-item(i + 1, b)),
)

// --- Satu kotak pada diagram alur ------------------------------------------
#let flow-box(body, fill: pm-soft, stroke: pm-primary) = box(
  fill: fill,
  stroke: 0.9pt + stroke,
  radius: 7pt,
  inset: (x: 8pt, y: 7pt),
  align(center, text(size: 0.8em, fill: pm-ink)[#body]),
)

// --- Panah penghubung diagram ----------------------------------------------
#let flow-arrow = text(fill: pm-primary, weight: "bold", size: 1.1em)[→]
