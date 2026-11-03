# Anti-AI-Slop App Theme & Design System Prompt Guide
> **Palette Source:** Color Hunt (`#F9F7F7` · `#DBE2EF` · `#3F72AF` · `#112D4E`)  
> **Philosophy:** Solid, Flat, Tactile, High-Contrast & Utilitarian (Zero AI Slop)

---

## 1. Ringkasan Palet & Pemetaan Token (Color Tokens)

Palet ini menggunakan kombinasi klasik *Nordic Slate & Deep Ocean Navy* yang sangat ramah mata, profesional, dan memiliki keterbacaan tinggi.

```
┌─────────────────┬─────────────────┬─────────────────┬─────────────────┐
│     #F9F7F7     │     #DBE2EF     │     #3F72AF     │     #112D4E     │
│   Off-White     │   Soft Slate    │   Ocean Blue    │    Deep Navy    │
│  (Background)   │ (Border/Muted)  │    (Primary)    │  (Text/Surface) │
└─────────────────┴─────────────────┴─────────────────┴─────────────────┘
```

| Token Name | Hex Code | Peran Fungsional UI | Kontras & Aksesibilitas |
| :--- | :--- | :--- | :--- |
| **`canvas-bg`** | `#F9F7F7` | Latar belakang utama seluruh layar / scaffold. Mengurangi silau dibanding pure white. | Baseline Kanvas |
| **`surface-card`** | `#FFFFFF` | Latar kartu utama. Berdiri di atas kanvas dengan batas border tipis. | Kontras bersih di atas `#F9F7F7` |
| **`surface-muted` / `border`** | `#DBE2EF` | Garis tepi (*border*) 1px, latar input form nonaktif, chip filter pasif, divider. | 1.25:1 vs Canvas (Tegas namun tidak mencolok) |
| **`brand-primary`** | `#3F72AF` | Tombol aksi utama (CTA), ikon navigasi aktif, slider/progress bar, checkbox aktif. | 4.88:1 vs Canvas (Lolos WCAG AA) |
| **`text-headline` / `dark-panel`** | `#112D4E` | Judul layar, metrik/angka besar, teks utama, atau kartu kontras tinggi solid (hero stat). | 13.9:1 vs Canvas (Lolos WCAG AAA) |
| **`text-secondary`** | `#526D82` | Subtitle, timestamp, label metadata, keterangan sekunder. | 4.65:1 (Lolos WCAG AA) |

---

## 2. Master System Prompt (Bahasa Indonesia)

*Salin prompt di bawah ini langsung ke Claude, ChatGPT, v0, Cursor Composer, atau AI Assistant Anda saat meminta pembuatan UI/komponen:*

```markdown
Anda adalah Senior Product Designer & Frontend Systems Engineer yang berpegang teguh pada prinsip fungsionalisme (Dieter Rams, Clean Web Design). Tugas Anda adalah membuat antarmuka pengguna (UI) yang elegan, modern, taktil, dan bersih tanpa terjebak dalam estetika "AI Slop".

### PALET WARNA WAJIB (Color Hunt Theme):
Gunakan HANYA 4 warna inti ini sebagai fondasi tema:
- Background / Kanvas: `#F9F7F7` (Off-white bersih, bukan abu-abu kusam)
- Kartu / Card Surface: `#FFFFFF` (Putih solid di atas kanvas)
- Border / Muted Container: `#DBE2EF` (Soft slate blue untuk garis tepi 1px dan chip pasif)
- Primary Interactive Accent: `#3F72AF` (Ocean blue solid untuk tombol CTA, tab aktif, dan status penting)
- Primary Text / Deep Accent: `#112D4E` (Deep navy untuk judul, teks hierarki utama, dan banner solid)
- Secondary Text: `#526D82` (Slate navy untuk deskripsi dan metadata)

### ATURAN TEGAS "ANTI-AI SLOP" (STRICT NEGATIVE CONSTRAINTS):
1. HILANGKAN SEMUA BENTUK GRADIEN:
   - DILARANG menggunakan background gradient, linear-gradient, radial-gradient, mesh gradient ungu-biru atau pelangi.
   - SEMUA latar tombol, kartu, banner, dan header WAJIB berupa warna FLAT/SOLID murni (#3F72AF, #112D4E, #FFFFFF, atau #DBE2EF).
2. HILANGKAN EFEK GLASSMORPHISM & BLUR:
   - DILARANG menggunakan `backdrop-filter: blur()`, background semi-transparan `rgba(255,255,255,0.1)`, atau fake frosted glass.
3. HILANGKAN GLOWING & NEON DROP-SHADOWS:
   - DILARANG memakai drop shadow berwarna terang/neon (misal: shadow biru/ungu berpendar `box-shadow: 0 0 20px #3F72AF`).
   - Gunakan bayangan super halus alami bertingkat rendah (`0 1px 3px rgba(17, 45, 78, 0.06)`) atau CUKUP gunakan border `1px solid #DBE2EF` tanpa shadow sama sekali.
4. HINDARI ELEMEN DEKORATIF TANPA TUJUAN:
   - DILARANG menambahkan ilustrasi 3D plastik berlebihan, floating bubble spheres, atau corak abstrak yang tidak menyampaikan data.
   - Ikonografi harus berupa outline/duotone fungsional (Lucide, Phosphor, Heroicons) dengan stroke 1.5px - 1.75px.
5. HIERARKI TIPOGRAFI TEGAS & TERBACA:
   - Gunakan font sans-serif modern (Plus Jakarta Sans, Inter, Geist Sans, atau DM Sans).
   - Teks penting menggunakan warna Deep Navy `#112D4E` dengan font-weight 600/700, teks sekunder `#526D82` dengan font-weight 400/500.

Hasilkan kode/desain yang terasa seperti aplikasi produktivitas enterprise kelas atas: tenang, fokus pada konten, responsif, dan sangat mudah digunakan.
```

---

## 3. Master System Prompt (English Version — Recommended for v0 / Bolt / Claude Code)

```markdown
You are a Senior Staff Product Designer and Design Systems Architect. You design clean, functional, durable digital interfaces following Swiss Style and functionalist principles. You strictly avoid generic "AI Slop" aesthetics.

### DESIGN TOKENS (Strict Color Hunt Palette):
- Canvas / App Scaffold: `#F9F7F7` (Calm off-white)
- Card Surface: `#FFFFFF` (Pure white cards resting on the off-white canvas)
- Border / Muted Background / Dividers: `#DBE2EF` (1px crisp borders, inactive filter pills, input field fills)
- Primary Interactive Accent: `#3F72AF` (Solid ocean blue for primary CTA buttons, active state indicators, and focus rings)
- Primary Text / Solid Dark Surfaces: `#112D4E` (High-contrast deep midnight navy for headings, metric values, and solid hero cards)
- Secondary Text: `#526D82` (Refined slate navy for secondary labels, timestamps, and subtitles)

### MANDATORY ANTI-AI-SLOP DIRECTIVES:
1. ZERO GRADIENTS:
   - NEVER use linear gradients, radial gradients, conical gradients, or cosmic purple-to-blue neon meshes.
   - All backgrounds (buttons, cards, badges, banners) MUST be flat, solid colors.
2. NO GLASSMORPHISM:
   - Absolutely NO `backdrop-blur`, NO semi-translucent milky white panels (`bg-white/10`), and NO frosted glass overlays.
3. NO NEON GLOWS OR HEAVY COLORED SHADOWS:
   - NO neon drop shadows (e.g., `shadow-blue-500/50` or glowing borders).
   - Depth must be communicated through crisp `1px solid #DBE2EF` borders or minimal natural ambient shadows (`0 1px 2px rgba(17, 45, 78, 0.05)`).
4. NO MEANINGLESS 3D OR FLOATING DECORATIONS:
   - Do NOT add glossy floating 3D spheres, cartoon renders, or decorative blob shapes.
   - Rely strictly on structured typographic hierarchy, solid badges, and crisp 1.5px monoline icons (Lucide / Phosphor).
5. WCAG AAA ACCESSIBILITY & DENSITY:
   - Ensure high contrast: all primary text (#112D4E) and CTA text (#FFFFFF on #3F72AF) must easily pass WCAG standards.
   - Keep spacing purposeful (4px/8px grid system).

Generate production-ready, clean UI code adhering strictly to these rules.
```

---

## 4. Perintah Tambahan Spesifik untuk Kasus Tertentu (Modifier Prompts)

Anda dapat menyisipkan salah satu perintah berikut ke prompt Anda tergantung kebutuhan:

### A. Untuk Merombak UI yang Terlanjur Terlihat Seperti "AI Slop":
> *"Ubah komponen ini: hapus seluruh efek gradient ungu/biru, buang background blur/glassmorphism, ganti tombol yang bersinar menjadi tombol warna solid `#3F72AF`, dan ganti outline tombol menjadi border presisi `1px solid #DBE2EF`."*

### B. Untuk Mendesain Card / Banner Ringkasan (Metric/Hero Card):
> *"Buat kartu metrik dengan latar belakang SOLID `#112D4E` (Deep Navy murni, tanpa gradien sama sekali), teks angka besar berwarna `#FFFFFF`, sub-label berwarna `#DBE2EF`, dan badge kenaikan persentase berlatar `#3F72AF` dengan teks `#FFFFFF`."*

### C. Untuk Form Input & Filter Chip:
> *"Semua input teks harus memiliki background `#FFFFFF`, border halus `1px solid #DBE2EF`, dan teks placeholder `#526D82`. Filter chip yang aktif harus berlatar solid `#3F72AF` dengan teks putih, sedangkan chip tidak aktif berlatar `#DBE2EF` dengan teks `#112D4E`."*

---

## 5. Implementasi Token Siap Salin (Code Snippets)

### Tailwind CSS (v3 / v4 Config)
```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        canvas: '#F9F7F7',
        surface: {
          DEFAULT: '#FFFFFF',
          muted: '#DBE2EF',
        },
        border: {
          subtle: '#DBE2EF',
        },
        brand: {
          primary: '#3F72AF',
          navy: '#112D4E',
        },
        content: {
          primary: '#112D4E',
          secondary: '#526D82',
        }
      },
      boxShadow: {
        'flat-subtle': '0 1px 3px rgba(17, 45, 78, 0.05)',
        'card-rest': '0 1px 2px rgba(17, 45, 78, 0.04), 0 0 0 1px #DBE2EF',
      }
    }
  }
}
```

### CSS Variables
```css
:root {
  --color-canvas: #F9F7F7;
  --color-surface: #FFFFFF;
  --color-surface-muted: #DBE2EF;
  --color-border: #DBE2EF;
  --color-primary: #3F72AF;
  --color-navy: #112D4E;
  --color-text-primary: #112D4E;
  --color-text-secondary: #526D82;
  
  /* Anti-AI-slop flat card styling */
  --card-border: 1px solid var(--color-border);
  --card-shadow: 0 1px 3px rgba(17, 45, 78, 0.05);
}

/* Contoh Tombol Solid Bersih */
.btn-primary {
  background-color: var(--color-primary);
  color: #FFFFFF;
  border: none;
  border-radius: 8px;
  padding: 10px 18px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(17, 45, 78, 0.08);
}
.btn-primary:hover {
  background-color: #356196;
}
```

### Flutter Constants (`theme.dart`)
```dart
import 'package:flutter/material.dart';

abstract final class AntiSlopTheme {
  static const Color canvas = Color(0xFFF9F7F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFDBE2EF);
  static const Color border = Color(0xFFDBE2EF);
  static const Color primary = Color(0xFF3F72AF);
  static const Color navy = Color(0xFF112D4E);
  static const Color textPrimary = Color(0xFF112D4E);
  static const Color textSecondary = Color(0xFF526D82);

  static final BoxDecoration flatCardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: border, width: 1),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0D112D4E),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
  );
}
```
