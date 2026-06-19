# Panduan Penggunaan PriorMail (Typst)

Dokumen panduan penggunaan PriorMail untuk Tim Pijak — dibuat dengan
[Typst](https://typst.app) (diuji pada **0.15.0**).

## Isi folder

| File | Keterangan |
|---|---|
| `panduan.typ` | Dokumen utama (seluruh isi panduan). |
| `theme.typ` | Palet brand "Orange-Dominant" + komponen (`callout`, `steps`, `feature`, …). |
| `mockup.typ` | Mockup dashboard inbox (digambar native di Typst). |
| `assets/logo-small.png` | Logo PriorMail untuk sampul. |

## Cara compile

```bash
# Hasilkan PDF
typst compile panduan.typ Panduan-PriorMail.pdf

# Mode live-preview saat menyunting
typst watch panduan.typ
```

## Sebelum dikirim

- URL aplikasi Vercel sudah terisi di `panduan.typ` (Bagian 0 & Bagian 1).
  Bila Anda memakai domain kustom, perbarui tautannya di kedua tempat tersebut.
- Font teks memakai **Inter**; bila tidak terpasang, Typst memakai fallback
  (Liberation Sans). Pasang Inter untuk hasil persis sesuai brand.
