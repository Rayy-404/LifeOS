# DESIGN.md — LifeOS UI/UX Design System

> Master design specification for **LifeOS** (Personal Productivity & Academic OS for Android). Intended for AI UI generation (Google Stitch), Figma, and Flutter Material 3 implementation.
>
> **Source Directive:** [`design/THEME_PROMPT.md`](file:///c:/Users/Rey/Documents/Projects/lifeOS/design/THEME_PROMPT.md)  
> **Palette Source:** Color Hunt (`#F9F7F7` · `#DBE2EF` · `#3F72AF` · `#112D4E` · `#526D82`)  
> **Philosophy:** Solid, Flat, Tactile, High-Contrast & Utilitarian (Zero AI Slop)

---

## 1. Product Identity & Design Principles

### Product Overview
- **Product Name:** LifeOS
- **Platform:** Android Mobile (Material 3 custom theme, 360dp–430dp width, design frame 390x844)
- **Primary Persona:** University students and young professionals juggling lecture schedules, assignment deadlines, and daily habits.
- **Design Mood:** *"Solid, Flat, Tactile, High-Contrast & Utilitarian"* — calm, focused, distraction-free productivity. Off-white canvas (`#F9F7F7`), crisp flat white cards (`#FFFFFF`) with 1px border (`#DBE2EF`), ocean blue interactive accent (`#3F72AF`), and deep midnight navy headline (`#112D4E`).

### Core Design Rules
1. **Scannable in 3 Seconds:** The user must see today's progress (%), pending/overdue tasks, today's agenda, and habit check-ins at a glance. Use flat structured cards, bold metric typography, and functional semantic badges — never long decorative paragraphs or cluttered widgets.
2. **One-Tap Execution:** Checking off a task, checking in a habit, and quick-add (center FAB) must be one tap, directly from cards without opening sub-screens.
3. **Solid, Flat & Tactile Depth (Zero AI Slop):** Depth comes strictly from crisp `1px solid #DBE2EF` borders and subtle natural ambient shadows (`0 1px 3px rgba(17, 45, 78, 0.05)`). **Zero gradients**, **no glassmorphism**, **no neon glow**, and **no 3D plastic/glossy decorations**.

---

## 2. Color Palette (Color Hunt Theme)

### Brand & Neutrals (Light Mode — Canonical)
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
| **`surface-card`** | `#FFFFFF` | Latar kartu utama. Berdiri di atas kanvas dengan batas border `1px solid #DBE2EF`. | Kontras bersih di atas `#F9F7F7` |
| **`surface-muted` / `border`** | `#DBE2EF` | Garis tepi (*border*) 1px, latar input form nonaktif, chip filter pasif, divider. | 1.25:1 vs Canvas (Tegas namun tidak mencolok) |
| **`brand-primary`** | `#3F72AF` | Tombol aksi utama (CTA), ikon navigasi aktif, slider/progress bar, checkbox aktif, selected day. | 4.88:1 vs Canvas (Lolos WCAG AA) |
| **`brand-primary-dark`** | `#356196` | Status tombol ditekan (*pressed state*), hover, focused interactive. | 6.10:1 vs Canvas (Lolos WCAG AA) |
| **`text-headline` / `dark-panel`** | `#112D4E` | Judul layar, metrik/angka besar, teks utama, atau kartu kontras tinggi solid (hero stat). | 13.9:1 vs Canvas (Lolos WCAG AAA) |
| **`text-secondary`** | `#526D82` | Subtitle, timestamp, label metadata, keterangan sekunder, placeholder. | 4.65:1 (Lolos WCAG AA) |
| **`divider`** | `#DBE2EF` | Garis pemisah tipis 1px antar seksi / daftar. | Presisi garis struktur |

### Semantic Colors (Solid + Flat Tint Pair)
| Role | Solid Hex | Soft Background | Usage |
| :--- | :--- | :--- | :--- |
| **Success / Done** | `#16A34A` | `#E8F8EE` | Completed tasks, habit checked-in, "Low" priority pill |
| **Warning / Medium** | `#D97706` | `#FEF3E2` | "Medium" priority pill, due < 24h warning |
| **Error / High / Overdue** | `#DC2626` | `#FDECEC` | "High" priority pill, overdue count, delete/logout |
| **Info / In Progress** | `#3F72AF` | `#DBE2EF` | In-progress tasks, info stat tile |

### Category / Subject Accents (Solid Accent Strip & Flat Tiles)
*Catatan: Semua aksen kategori menggunakan warna flat solid tanpa efek glow atau gradien.*
| Name | Solid | Tint Fill (Muted) | Peruntukan Contoh |
| :--- | :--- | :--- | :--- |
| **Ocean Navy** | `#112D4E` | `#DBE2EF` | Administrasi Umum / Akademik Utama |
| **Teal / Slate** | `#0D9488` | `#E6F4F2` | Bimbingan & Praktikum |
| **Amber** | `#D97706` | `#FEF3E2` | Tugas & Tenggat Waktu |
| **Emerald** | `#16A34A` | `#E8F8EE` | Rutinitas & Kesehatan |
| **Blue Slate** | `#3F72AF` | `#DBE2EF` | Belajar Mandiri & Membaca |

### Dark Mode (Slate & Midnight Contrast)
- **Scaffold Background (`canvas`):** `#0B132B`
- **Surface (`surface-card`):** `#111D35`
- **Border / Muted (`border`):** `#203354`
- **Primary Interactive:** `#5A8FD8`
- **Text Primary (`text-headline`):** `#F9F7F7`
- **Text Secondary:** `#8FA2B8`
- **Dark Panel Accent:** `#0F172A`

---

## 3. Typography

- **Font Family:** `Plus Jakarta Sans` untuk seluruh elemen (headings, angka metrik, body, labels). Fallback: `Inter`, `Geist Sans`, atau `DM Sans`.
- **Hierarki Kontras:** Teks hierarki utama wajib menggunakan Deep Navy `#112D4E` (font-weight 600/700). Teks sekunder dan metadata menggunakan Slate Navy `#526D82` (font-weight 400/500).

| Token | Size / Line Height | Weight | Color Token | Usage |
| :--- | :--- | :--- | :--- | :--- |
| `display.hero` | `32 / 38` | 800 | `#112D4E` (kata kunci `#3F72AF`) | Onboarding headline ("Your Life, **Organized** in One Place") |
| `display.metric` | `28 / 34` | 700 | `#112D4E` / `#FFFFFF` (di dark card) | Ring percentage (72%), angka KPI stat |
| `headline.screen` | `22 / 28` | 700 | `#112D4E` | Judul layar utama ("My Tasks", "Calendar"), user name |
| `title.section` | `16 / 22` | 700 | `#112D4E` | Section headers ("Quick Actions", "Today's Tasks") |
| `title.card` | `14 / 20` | 600 | `#112D4E` | Judul tugas, nama habit, judul event kalender |
| `body` | `13 / 18` | 400 | `#112D4E` / `#526D82` | Deskripsi, helper text |
| `label` | `12 / 16` | 600 | `#3F72AF` / `#FFFFFF` / `#112D4E` | Chips, status pill, tombol text, "See All" link |
| `caption` | `11 / 14` | 500 | `#526D82` | Time/date meta dengan icon, label hari kalender |

---

## 4. Shape, Spacing, Elevation

- **Grid:** 4px base (`4, 8, 12, 16, 20, 24, 32`). Padding horizontal layar `20px` (atau `16px`). Jarak antar kartu `12px`, jarak antar seksi `24px`.
- **Corner Radius:**
  - Kartu utama / Hero banner: `16px`
  - Tombol aksi & Search input: `12px`
  - Icon tile / Quick action: `12px`
  - Badge & Status pill: `8px`
  - Filter chips: `999px` (fully rounded capsule)
  - Bottom sheet (top corners): `24px`
  - Bottom navigation bar: `20px` top corners
- **Elevation & Border (Flat-Bordered Tactile):**
  - **Dilarang keras memakai shadow neon atau gradien.**
  - Seluruh kartu menggunakan garis tepi presisi: `1px solid #DBE2EF`.
  - Ambient shadow alami bertingkat rendah: `0 1px 3px rgba(17, 45, 78, 0.05)`.
  - Center FAB shadow: `0 2px 8px rgba(17, 45, 78, 0.20)` (natural deep navy shadow, bukan neon glowing).
- **Icons:** Outline/monoline fungsional (Lucide / Phosphor Regular), ukuran `20–22px`, ketebalan stroke `1.5px – 1.75px`.

---

## 5. Navigation

**Bottom Navigation Bar (White Surface, 1px Border Top, 4 Tabs + Center FAB):**

`Home` · `Tasks` · **( + )** · `Calendar` · `Habits`

- **Scaffold Navigasi:** Warna latar `#FFFFFF`, border atas `1px solid #DBE2EF`, tinggi `68px`.
- **Center FAB:** Lingkaran 56px, warna solid `#3F72AF` (Ocean Blue murni, tanpa gradien), ikon putih `+`, border halus atau ambient shadow `rgba(17, 45, 78, 0.2)`. Membuka Quick Add bottom sheet (Task / Event / Habit).
- **Tab State:**
  - Aktif: Ikon dan label berwarna `#3F72AF` (font-weight 600).
  - Tidak aktif: Ikon dan label berwarna `#526D82` (font-weight 500).
- **Statistics & Profile:** Diakses dari avatar profil di pojok kanan atas Header Home (bukan tab navigasi bawah).

---

## 6. Screen Specifications (10 Layar Utama)

### S-01 Onboarding / Welcome
- **Canvas:** `#F9F7F7` off-white.
- **Top Brand:** Logo tile (kotak sudut tumpul 12px solid `#3F72AF` dengan icon minimalis putih).
- **Typographic Headline:** "Your Life, **Organized** in One Place" (kata "Organized" beraksen `#3F72AF`, judul dalam `#112D4E`).
- **Subtitle:** "Track your tasks, classes, and habits — all in one calm dashboard." (`#526D82`).
- **Hero Graphic (Anti-AI Slop):** DILARANG menggunakan ilustrasi 3D plastik atau gradien kosmik. Ganti dengan kartu pratinjau antarmuka taktil (*Tactile UI Preview Card*): kartu `#FFFFFF` dengan garis tepi `1px solid #DBE2EF`, menampilkan ringkasan agenda hari ini, 2 baris to-do tercentang, dan streak badge mingguan yang tajam.
- **Bottom Action:** Tombol solid Deep Navy `#112D4E` berteks putih "Get Started →" + teks link sekunder "Already have an account? **Log In**" (`#3F72AF`).

### S-02/S-03 Login & Register
- **Canvas:** `#F9F7F7` dengan kartu form `#FFFFFF` ber-border `1px solid #DBE2EF`.
- **Form Input:** Background `#FFFFFF`, garis tepi `1px solid #DBE2EF`, teks placeholder `#526D82`, focus state border `#3F72AF` (1.5px).
- **Primary CTA:** Tombol solid Ocean Blue `#3F72AF` berteks putih `#FFFFFF` (12px radius, font-weight 600).
- **Register Additions:** Field nama lengkap + chip deteksi otomatis zona waktu ("Asia/Jakarta") berlatar `#DBE2EF` dengan teks `#112D4E`.

### S-04 Home / Dashboard
- **Header:** Sapaan `"Good Morning,"` (`#526D82`) / `"Rayhan 👋"` (`#112D4E`, 22px bold) + ikon lonceng reminder + circular avatar (tap $\rightarrow$ S-10 Profile & Stats).
- **Daily Progress Card:** Kartu putih `#FFFFFF` ber-border `1px solid #DBE2EF`. Circular progress ring solid `#3F72AF` dengan track `#DBE2EF`. Metrik persentase `"72%"` (`#112D4E`), keterangan `"4 of 6 tasks done · Keep going!"` (`#526D82`).
- **2x2 Stat Bento Grid:** Empat kartu putih ber-border `1px solid #DBE2EF`:
  - *Total Tasks:* Angka `12` (`#112D4E`), icon tile `#DBE2EF` dengan icon `#3F72AF`.
  - *In Progress:* Angka `4` (`#112D4E`), icon tile `#DBE2EF`.
  - *Completed:* Angka `8` (`#16A34A`), icon tile `#E8F8EE`.
  - *Overdue:* Angka `1` (`#DC2626`), icon tile `#FDECEC`.
- **Quick Actions Row:** 4 chip/tombol pintasan: latar `#DBE2EF`, teks `#112D4E`, icon `#3F72AF` (Add Task, Add Event, New Habit, Statistics).
- **Today's Agenda:** Kartu putih ber-border `1px solid #DBE2EF` dengan aksen garis vertikal solid di sisi kiri (3px solid `#3F72AF` atau `#112D4E`). Teks jam & mata kuliah ("08:00–10:00 · Operating Systems · Bldg B R.204").
- **Today's Habits:** Kartu ringkas ber-border `1px solid #DBE2EF`, streak pill (`#DBE2EF` dengan teks `#112D4E`), dan tombol bulat check-in satu sentuhan di sisi kanan.
- **Today's Tasks:** Baris kartu dengan checkbox lingkaran, judul tugas, ikon jam + due time, serta priority pill.

### S-05 My Tasks
- **Top Bar:** Judul `"My Tasks"` (`#112D4E`) + search input `#FFFFFF` ber-border `1px solid #DBE2EF` + tombol filter.
- **Filter Chips Bar:**
  - Chip aktif: Latar solid `#3F72AF` dengan teks putih `#FFFFFF`.
  - Chip tidak aktif: Latar solid `#DBE2EF` dengan teks `#112D4E`.
- **Task List Rows:** Kartu putih `#FFFFFF` ber-border `1px solid #DBE2EF`.
  - Checkbox lingkaran interaktif di kiri.
  - Judul tugas (`#112D4E`, 14px semi-bold). Jika selesai (`DONE`): coret teks (*strikethrough*), opacity 65%, checkbox terisi hijau `#16A34A`.
  - Priority Pill di kanan: `HIGH` (merah), `MEDIUM` (amber), `LOW` (slate/biru).
  - Status overdue: teks merah `#DC2626` dengan icon alert clock.

### S-06 Quick Add / Task Form Bottom Sheet
- **Container:** Modal Bottom Sheet `#FFFFFF` dengan sudut atas `24px` dan garis pemisah `1px solid #DBE2EF`.
- **Segmented Control:** `Task | Event | Habit` — segmen aktif berlatar solid `#3F72AF` dengan teks putih; pasif `#DBE2EF` dengan teks `#112D4E`.
- **Inputs:** Title field `#FFFFFF` dengan border `1px solid #DBE2EF`, description, date & time selector chips, priority pills selector, toggle "Remind me".
- **Action Button:** Full-width tombol solid `#3F72AF` "Save Task" (12px radius, teks putih).

### S-07 Calendar
- **Header:** Bulan & Tahun (`Oktober 2026`) + toggle `Week | Month` berlatar `#DBE2EF`.
- **Week Strip:** 7 kolom hari (`Sen` s/d `Min`). Hari aktif/terpilih berupa kapsul tegak berlatar solid `#3F72AF` dengan teks putih `#FFFFFF`. Titik indikator di bawah tanggal.
- **Timeline View:** Kolom jam di kiri (`#526D82`), kartu agenda di kanan dengan border `1px solid #DBE2EF` dan garis aksen solid di sisi kiri.
- **Primary CTA:** Tombol solid `#3F72AF` `+ Add Event`.

### S-08 Habits
- **Hero Banner (Anti-AI Slop Rework):**
  - Latar belakang: **SOLID `#112D4E`** (Deep Navy murni — **DILARANG memakai gradien apa pun**).
  - Judul: Teks putih `#FFFFFF` ("Build Better Habits").
  - Subteks: Soft slate `#DBE2EF` ("Small daily discipline leads to monumental academic success.").
  - Badge status: Solid `#3F72AF` dengan teks putih `#FFFFFF` ("7 Active Habits").
  - DILARANG menggunakan gambar kartun 3D gunung/bendera. Gunakan monoline badge ikon atau typografi terstruktur.
- **My Habits List:** Kartu putih `#FFFFFF` ber-border `1px solid #DBE2EF`.
  - Baris atas: Nama habit (`#112D4E`), streak pill (`🔥 7 day streak`), tombol bulat check-in di kanan (diameter 44px).
  - Baris bawah: **Weekly Mini-Grid (7 hari):** Lingkaran hari `S S R K J S M`:
    - Hijau solid `#16A34A` = Selesai.
    - Border `1px solid #DBE2EF` (latar transparan) = Hari aktif belum check-in.
    - Titik redup (`#DBE2EF`) = Hari istirahat/tidak aktif.

### S-09 Habit Detail & History
- Header nama habit, kartu statistik streak ber-border `1px solid #DBE2EF` (Current streak / Best streak / Consistency %).
- Kalender kepatuhan bulanan (*monthly grid heatmap*) dengan sel hijau solid `#16A34A` dan border halus `#DBE2EF`.

### S-10 Statistics & Profile
- **Profile Header Card:** Kartu kontras tinggi berlatar **SOLID `#112D4E`** (Deep Navy murni, tanpa gradien).
  - Avatar lingkaran, nama "Rayhan", email, timezone chip ("Asia/Jakarta").
  - Baris ringkasan metrik: `12 Tasks` · `5 Habits` · `7 Days Streak` (angka putih `#FFFFFF`, label `#DBE2EF`).
- **Analytics Section:**
  - KPI Cards: Latar putih `#FFFFFF`, border `1px solid #DBE2EF`.
  - Productivity Score ring: Solid `#3F72AF` pada track `#DBE2EF`.
  - Weekly Completion Chart: Grafik batang vertikal 7 hari menggunakan warna **SOLID `#3F72AF`** dan bar `#DBE2EF` (tanpa gradient area fill).
- **Settings Menu List:** Tiap item memiliki border bawah `1px solid #DBE2EF`, icon `#3F72AF`, teks `#112D4E`, dan chevron `#526D82`.
- **Log Out Action:** Tombol solid border dengan teks merah `#DC2626` ("Log Out").

---

## 7. States & Micro-interactions

- **Touch Targets:** Minimum `48x48dp` untuk seluruh elemen interaktif (checkbox, habit check-in, icon buttons, filter chips).
- **Loading State:** Skeleton Shimmer berbentuk kartu datar dengan border `1px solid #DBE2EF`. Dilarang menggunakan full-screen circular loading spinner.
- **Empty State:** Menggunakan ikon monoline Lucide garis tipis (1.5px), judul singkat `#112D4E`, subteks penjelasan `#526D82`, dan tombol CTA solid `#3F72AF`.
- **Error State:** Kartu putih ber-border `1px solid #DBE2EF` dengan aksen merah `#DC2626`, pesan bahasa manusiawi yang jelas, dan tombol retry.
- **Offline State:** Banner ramping di bagian atas layar: latar `#DBE2EF`, teks `#112D4E` ("Mode Offline · Menampilkan data lokal tersimpan").
- **Interactive Feedback:** Centang checkbox / check-in habit memberikan respons instan (*optimistic update*) dengan durasi transisi $\le 200\text{ms}$ dan `HapticFeedback.lightImpact()`.

---

## 8. Aturan Tegas Anti-AI-Slop (Strict Negative Constraints)

1. **HILANGKAN SEMUA BENTUK GRADIEN (Zero Gradients):**
   - DILARANG menggunakan background gradient, linear-gradient, radial-gradient, atau mesh gradient kosmik ungu-biru.
   - SEMUA latar tombol, kartu, hero banner, dan header WAJIB berupa warna **FLAT / SOLID murni** (`#3F72AF`, `#112D4E`, `#FFFFFF`, atau `#DBE2EF`).
2. **HILANGKAN EFEK GLASSMORPHISM & BLUR:**
   - DILARANG menggunakan `backdrop-filter: blur()`, background semi-transparan `rgba(255,255,255,0.1)`, atau frosted glass palsu.
3. **HILANGKAN GLOWING & NEON DROP-SHADOWS:**
   - DILARANG memakai drop shadow berwarna terang/neon (misal: shadow biru berpendar `box-shadow: 0 0 20px #3F72AF`).
   - Kedalaman elemen dibentuk melalui border presisi `1px solid #DBE2EF` dan bayangan ambient alami bertingkat rendah (`0 1px 3px rgba(17, 45, 78, 0.05)`).
4. **HINDARI ELEMEN DEKORATIF TANPA TUJUAN:**
   - DILARANG menambahkan ilustrasi 3D plastik berlebihan, bola mengambang (*floating spheres*), atau corak abstrak yang tidak menyampaikan data.
   - Ikonografi harus berupa outline/monoline fungsional (Lucide / Phosphor) dengan stroke `1.5px – 1.75px`.
5. **HIERARKI TIPOGRAFI TEGAS & TERBACA (WCAG AAA):**
   - Teks penting menggunakan warna Deep Navy `#112D4E` (rasio kontras 13.9:1 di atas kanvas `#F9F7F7`).
   - Teks sekunder menggunakan Slate Navy `#526D82` (rasio kontras 4.65:1).
   - Tombol utama solid `#3F72AF` dengan teks putih `#FFFFFF` (rasio kontras 4.88:1).

---

## 9. Implementasi Token Siap Pakai

### Flutter Constants (`mobile/lib/app/theme.dart`)
```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand & Neutrals (Light Mode - Color Hunt Anti-Slop Theme)
  static const Color canvas = Color(0xFFF9F7F7);
  static const Color background = Color(0xFFF9F7F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFDBE2EF);
  static const Color border = Color(0xFFDBE2EF);
  static const Color primary = Color(0xFF3F72AF);
  static const Color primaryDark = Color(0xFF356196);
  static const Color primarySoft = Color(0xFFDBE2EF);
  static const Color navy = Color(0xFF112D4E);
  static const Color textPrimary = Color(0xFF112D4E);
  static const Color textSecondary = Color(0xFF526D82);
  static const Color divider = Color(0xFFDBE2EF);

  // Semantics
  static const Color success = Color(0xFF16A34A);
  static const Color successPastel = Color(0xFFE8F8EE);
  static const Color warning = Color(0xFFD97706);
  static const Color warningPastel = Color(0xFFFEF3E2);
  static const Color error = Color(0xFFDC2626);
  static const Color errorPastel = Color(0xFFFDECEC);
  static const Color info = Color(0xFF3F72AF);
  static const Color infoPastel = Color(0xFFDBE2EF);

  // Dark Mode Neutrals
  static const Color darkBackground = Color(0xFF0B132B);
  static const Color darkSurface = Color(0xFF111D35);
  static const Color darkSurfaceMuted = Color(0xFF203354);
  static const Color darkBorder = Color(0xFF203354);
  static const Color darkPrimary = Color(0xFF5A8FD8);
  static const Color darkTextPrimary = Color(0xFFF9F7F7);
  static const Color darkTextSecondary = Color(0xFF8FA2B8);
}

abstract final class AppShadows {
  /// Subtle natural card ambient shadow
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D112D4E),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  /// Natural FAB shadow (non-neon)
  static const List<BoxShadow> fab = [
    BoxShadow(
      color: Color(0x33112D4E),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}
```

### Tailwind CSS Token Mapping (Web / Preview Reference)
```js
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
          dark: '#356196',
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
