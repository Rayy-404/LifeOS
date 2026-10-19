# LifeOS — Spesifikasi Teknis MVP

**Dokumen:** `03-technical-spec.md`  
**Platform:** Personal Productivity App · Android  
**Tech Stack:** Flutter · NestJS · Prisma 6 · PostgreSQL 17  

LifeOS adalah aplikasi produktivitas pribadi untuk mengelola tugas, kegiatan, kebiasaan, pengingat, dan progres harian melalui satu dashboard modern.

Spesifikasi ini menjadi acuan bersama untuk desain UI, database, endpoint backend, dan implementasi Flutter. Targetnya adalah MVP yang benar-benar berfungsi, bukan sekadar prototipe visual.

### Tiga Keputusan Arsitektur Utama
1. **Single Source of Truth untuk Metrik:** Dashboard dan statistik dihitung langsung dari data sumber (`tasks`, `habits`, `habit_logs`, `calendar_events`) agar tidak terjadi duplikasi atau inkonsistensi data.
2. **Kalender Terpadu:** Kalender menggabungkan tugas yang memiliki waktu (`Task.dueAt`) dan kegiatan terjadwal (`CalendarEvent`), bukan menjadi database terpisah untuk informasi yang sama.
3. **Arsitektur Hibrida Reminder:** Reminder disimpan di backend (`reminders`), sedangkan notifikasi lokal dijadwalkan di perangkat Android (`flutter_local_notifications`). Sinkronisasi status dan penjadwalan ulang perlu ditangani secara eksplisit.

---

## 1. Ruang Lingkup MVP

| Modul Fitur | Cakupan Fungsional MVP |
| :--- | :--- |
| **Dashboard Harian** | Ringkasan tugas selesai dan tertunda, agenda hari ini, progres kebiasaan, serta tugas yang mendekati deadline. Data berasal dari endpoint dashboard yang menggabungkan beberapa sumber. |
| **Kalender** | Tampilan bulanan dan agenda mingguan, navigasi tanggal, serta daftar tugas dan kegiatan berdasarkan tanggal. Termasuk pembuatan kegiatan dengan waktu mulai dan selesai. |
| **Task Management** | CRUD tugas, deskripsi, prioritas (`LOW`, `MEDIUM`, `HIGH`), status (`TODO`, `IN_PROGRESS`, `DONE`), deadline (`dueAt`), filter, dan pencarian. |
| **Habit Tracker** | Kebiasaan berulang, hari aktif (`activeDays` 1–7), catatan penyelesaian harian (`HabitLog`), riwayat, dan perhitungan *streak*. |
| **Reminder** | Pengingat satu kali untuk tugas atau kegiatan, status pengingat (`SCHEDULED`, `SENT`, `CANCELLED`, `FAILED`), dan notifikasi lokal Android. |
| **Statistik Produktivitas** | Tingkat penyelesaian tugas, tugas terlambat (*overdue*), tren mingguan, dan konsistensi kebiasaan. |

### Di Luar MVP
Untuk menjaga ruang lingkup tetap realistis, versi pertama **tidak mencakup**:
- Kolaborasi tim / berbagi tugas antar-pengguna
- Integrasi Google Calendar
- AI planner / penjadwalan otomatis berbasis AI
- Sinkronisasi multi-perangkat secara *realtime*
- *Recurring reminder* kompleks

---

## 2. Kontrak Desain dan UX

**Gaya Visual:** Modern, minimal, *card-based*, dengan informasi yang mudah dipindai. Desain mengutamakan fungsi daripada dekorasi.

### Referensi Antarmuka Utama
- [TaskSphere - Smart Task Management App by Tajkim Masum on Dribbble](https://images.openai.com/static-rsc-4/YC83dcIWXrpIS86uhc1KB24Tf4ZKZjfRP9PuH_OXvVgxHqQI28obU8r9-fpeRyIQoIn704fe5-hqdWTUKjhsJAsMYrGGcue9iTTI_aGtaazmHnH201ZInYWXYtnDZEjFKbhZ0tzhTziD0PYSj9cLH5csG2V0Cjso5vjTB1_utfU?purpose=inline)
- [AI Task Management Mobile App UI by UIX Maruf Hossen on Dribbble](https://images.openai.com/static-rsc-4/vE-9_EYmgLCgtYjudHJ_oHb4TsvDn0DBC6mXerXle4tDNlLAzkdNGZOIrF85cKV2HKLvVdp_YnhxLJO7tP_KXxVyZLe-qPiXvmKJp6xvCB7GMUPRgVHB5CzoKP0wywfOc1Z0zQ3hFYY-75DMeShyZypeyvIH8P-XQy2foCt2iw0?purpose=inline)
- [Habits App by Andrew Larin on Dribbble](https://images.openai.com/static-rsc-4/1V_fHbMwryiuevh1I3TeY8UyJEK4WJA0V0x6QEjwWaoxd4ZhNeLKWlCrSsJZjvzzpq8TEdVviCvd14cbo2vRkntyHzoVAcKx3ekkrzl1zwCRM14tEwJNYa0J_BpX2Hj0hO35dUjD1uWGfCKN4l5npvJSiBM_6OaYjQi4KUO1aIQ?purpose=inline)

### Karakteristik Layar Utama
- **Dashboard:**
  - Sapaan dan tanggal di bagian atas.
  - Ringkasan progres dalam kartu.
  - Daftar tugas dengan *checkbox*.
  - Agenda dan kebiasaan hari ini.
  - Tombol tambah tugas yang mudah dijangkau.
- **Task Management:**
  - Status dan prioritas terlihat jelas.
  - Deadline mudah dibaca.
  - Filter tidak memenuhi layar.
  - Form tambah/edit menggunakan *bottom sheet* atau halaman khusus.
- **Habit Tracker:**
  - Kartu per kebiasaan.
  - Indikator progres mingguan.
  - Tombol *check-in* satu sentuhan.
  - Riwayat dan *streak* ditampilkan secara ringkas.

### Design Tokens Awal

| Elemen | Spesifikasi |
| :--- | :--- |
| **Primary** | Indigo `#4F46E5` |
| **Background** | `#F8FAFC` |
| **Surface** | `#FFFFFF` |
| **Primary text** | `#0F172A` |
| **Secondary text** | `#64748B` |
| **Success** | `#16A34A` |
| **Warning** | `#D97706` |
| **Error** | `#DC2626` |
| **Radius kartu** | `16 px` |
| **Spacing dasar** | `4, 8, 12, 16, 24 px` |
| **Tipografi** | Material 3, hierarki judul dan isi yang jelas |

Gunakan Material 3, dukungan tema terang/gelap, area sentuh yang nyaman, dan layout yang responsif terhadap ukuran layar Android. *(Rincian lengkap desain terdapat pada [`02-design-brief.md`](file:///C:/Users/Rey/Documents/Projects/lifeOS/planning/02-design-brief.md)).*

---

## 3. Skema Database PostgreSQL

### Relasi Inti Entitas

```mermaid
erDiagram
    User ||--o{ Task : "memiliki"
    User ||--o{ Habit : "memiliki"
    User ||--o{ CalendarEvent : "memiliki"
    User ||--o{ Reminder : "memiliki"
    User ||--o{ RefreshToken : "memiliki"
    Habit ||--o{ HabitLog : "mencatat"
    Task ||--o{ Reminder : "opsional (XOR)"
    CalendarEvent ||--o{ Reminder : "opsional (XOR)"
```

- **User:** Identitas, email, timezone
- **Task:** Deadline, status, prioritas
- **CalendarEvent:** Mulai, selesai, lokasi opsional
- **Habit:** Jadwal kebiasaan (`activeDays`)
- **HabitLog:** Satu catatan per habit per tanggal (`habitId + logDate`)
- **Reminder:** Waktu dan status pengiriman
- **RefreshToken:** Menyimpan hash token refresh yang dapat dicabut

### File `backend/prisma/schema.prisma`

Skema berikut mencakup model MVP dan relasi antartabel. Gunakan PostgreSQL dengan Prisma ORM; format `datasource` mengikuti Prisma 6.x.

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum TaskStatus {
  TODO
  IN_PROGRESS
  DONE
}

enum Priority {
  LOW
  MEDIUM
  HIGH
}

enum ReminderStatus {
  SCHEDULED
  SENT
  CANCELLED
  FAILED
}

enum ReminderChannel {
  LOCAL
  PUSH
}

model User {
  id           String   @id @default(uuid()) @db.Uuid
  email        String   @unique @db.VarChar(254)
  passwordHash String   @map("password_hash")
  name         String   @db.VarChar(100)
  timezone     String   @default("Asia/Jakarta")
  createdAt    DateTime @default(now()) @map("created_at") @db.Timestamptz(3)
  updatedAt    DateTime @updatedAt @map("updated_at") @db.Timestamptz(3)

  tasks         Task[]
  habits        Habit[]
  events        CalendarEvent[]
  reminders     Reminder[]
  refreshTokens RefreshToken[]

  @@map("users")
}

model Task {
  id          String     @id @default(uuid()) @db.Uuid
  userId      String     @map("user_id") @db.Uuid
  title       String     @db.VarChar(200)
  description String?    @db.Text
  status      TaskStatus @default(TODO)
  priority    Priority   @default(MEDIUM)
  dueAt       DateTime?  @map("due_at") @db.Timestamptz(3)
  completedAt DateTime?  @map("completed_at") @db.Timestamptz(3)
  createdAt   DateTime   @default(now()) @map("created_at") @db.Timestamptz(3)
  updatedAt   DateTime   @updatedAt @map("updated_at") @db.Timestamptz(3)

  user      User       @relation(fields: [userId], references: [id], onDelete: Cascade)
  reminders Reminder[]

  @@unique([id, userId])
  @@index([userId, status, dueAt])
  @@index([userId, createdAt])
  @@map("tasks")
}

model Habit {
  id          String   @id @default(uuid()) @db.Uuid
  userId      String   @map("user_id") @db.Uuid
  name        String   @db.VarChar(120)
  description String?  @db.Text
  isActive    Boolean  @default(true) @map("is_active")
  // ISO weekdays: 1=Monday ... 7=Sunday
  activeDays  Int[]    @default([1, 2, 3, 4, 5, 6, 7]) @map("active_days")
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(3)
  updatedAt   DateTime @updatedAt @map("updated_at") @db.Timestamptz(3)

  user User       @relation(fields: [userId], references: [id], onDelete: Cascade)
  logs HabitLog[]

  @@index([userId, isActive])
  @@map("habits")
}

model HabitLog {
  id          String    @id @default(uuid()) @db.Uuid
  habitId     String    @map("habit_id") @db.Uuid
  logDate     DateTime  @map("log_date") @db.Date
  completedAt DateTime? @map("completed_at") @db.Timestamptz(3)
  createdAt   DateTime  @default(now()) @map("created_at") @db.Timestamptz(3)

  habit Habit @relation(fields: [habitId], references: [id], onDelete: Cascade)

  @@unique([habitId, logDate])
  @@index([logDate])
  @@map("habit_logs")
}

model CalendarEvent {
  id          String   @id @default(uuid()) @db.Uuid
  userId      String   @map("user_id") @db.Uuid
  title       String   @db.VarChar(200)
  description String?  @db.Text
  location    String?  @db.VarChar(300)
  startsAt    DateTime @map("starts_at") @db.Timestamptz(3)
  endsAt      DateTime @map("ends_at") @db.Timestamptz(3)
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(3)
  updatedAt   DateTime @updatedAt @map("updated_at") @db.Timestamptz(3)

  user      User       @relation(fields: [userId], references: [id], onDelete: Cascade)
  reminders Reminder[]

  @@unique([id, userId])
  @@index([userId, startsAt])
  @@map("calendar_events")
}

model Reminder {
  id        String          @id @default(uuid()) @db.Uuid
  userId    String          @map("user_id") @db.Uuid
  taskId    String?         @map("task_id") @db.Uuid
  eventId   String?         @map("event_id") @db.Uuid
  remindAt  DateTime        @map("remind_at") @db.Timestamptz(3)
  channel   ReminderChannel @default(LOCAL)
  status    ReminderStatus  @default(SCHEDULED)
  createdAt DateTime        @default(now()) @map("created_at") @db.Timestamptz(3)
  updatedAt DateTime        @updatedAt @map("updated_at") @db.Timestamptz(3)

  user  User           @relation(fields: [userId], references: [id], onDelete: Cascade)
  task  Task?          @relation(fields: [taskId], references: [id], onDelete: Cascade)
  event CalendarEvent? @relation(fields: [eventId], references: [id], onDelete: Cascade)

  @@index([userId, status, remindAt])
  @@index([taskId])
  @@index([eventId])
  @@map("reminders")
}

model RefreshToken {
  id        String    @id @default(uuid()) @db.Uuid
  userId    String    @map("user_id") @db.Uuid
  tokenHash String    @unique @map("token_hash")
  expiresAt DateTime  @map("expires_at") @db.Timestamptz(3)
  revokedAt DateTime? @map("revoked_at") @db.Timestamptz(3)
  createdAt DateTime  @default(now()) @map("created_at") @db.Timestamptz(3)

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, expiresAt])
  @@map("refresh_tokens")
}
```

### Aturan Integritas yang Harus Diterapkan (Terkunci untuk Migration Pertama)
Schema Prisma merupakan fondasi, bukan pengganti validasi bisnis. Terapkan aturan tambahan berikut pada service NestJS dan migration SQL:

1. **Lifecycle `completedAt`:** `completedAt` diisi (`NOW()`) ketika status tugas menjadi `DONE`, lalu dibersihkan (`null`) jika tugas dibuka kembali (`TODO` atau `IN_PROGRESS`).
2. **Validasi `activeDays` Tanpa Duplikat:**
   - `activeDays` hanya boleh berisi bilangan bulat `1–7` **tanpa duplikasi** dan minimal memiliki 1 elemen.
   - Di DTO NestJS: wajib divalidasi dengan `@IsArray()`, `@ArrayMinSize(1)`, `@ArrayMaxSize(7)`, `@ArrayUnique()`, `@IsInt({ each: true })`, `@Min(1, { each: true })`, `@Max(7, { each: true })`.
   - Di Service NestJS: simpan dalam urutan kanonik terurut naik (`[...new Set(days)].sort((a, b) => a - b)`).
   - Di Database: dijaga oleh constraint `chk_habits_active_days_range_and_unique` (menolak `[]`, `[0]`, `[8]`, dan `[1, 1, 3]`).
3. **Urutan Waktu Kegiatan:** `CalendarEvent.endsAt` harus lebih besar secara ketat dari `startsAt` (`endsAt > startsAt`).
4. **Relasi XOR & Kepemilikan Target Reminder (Zero Cross-Tenant Reference):**
   - Reminder harus terkait dengan tepat satu tugas (`taskId`) **atau** satu kegiatan (`eventId`), bukan keduanya dan bukan tanpa keduanya.
   - **Invariant Kepemilikan:** `userId` tidak pernah diterima dari request body; selalu diambil dari JWT (`currentUser.id`). Saat `POST /reminders` atau `PATCH /reminders/:id`, Service wajib memverifikasi bahwa `taskId` atau `eventId` dimiliki oleh `currentUser.id` (jika milik user lain atau tidak ada, kembalikan `404 Not Found` agar tidak membocorkan eksistensi UUID).
   - **Proteksi Level Database:** Tabel `tasks` dan `calendar_events` memiliki `@@unique([id, userId])`. Migration SQL menambahkan composite foreign key `(task_id, user_id) -> tasks(id, user_id)` dan `(event_id, user_id) -> calendar_events(id, user_id)` (`MATCH SIMPLE ON DELETE CASCADE`), sehingga secara struktural mustahil sebuah baris `reminders` menunjuk ke `task_id` atau `event_id` milik `user_id` berbeda.
5. **Normalisasi Email Case-Insensitive:**
   - Saat `/auth/register` dan `/auth/login`, input `email` wajib dinormalisasi dengan `.trim().toLowerCase()` sebelum validasi/query.
   - Di level database, constraint `chk_users_email_lowercase` memastikan kolom `users.email` hanya menerima huruf kecil.
6. **Keamanan Kredensial & Atomic Refresh Token Rotation:**
   - Password di-*hash* dengan `argon2`.
   - Refresh token disimpan sebagai SHA-256 / Argon2 hash (`token_hash`).
   - Rotasi token pada `POST /auth/refresh` dieksekusi di dalam satu transaksi database (`prisma.$transaction`). Jika sebuah refresh token yang sudah memiliki `revoked_at IS NOT NULL` dikirim ulang (*token reuse / replay detected*), server **langsung mencabut seluruh refresh token aktif milik `userId` tersebut** dan mengembalikan `401 Unauthorized` (`TOKEN_REUSE_DETECTED`).
7. **Unik Harian HabitLog:** `HabitLog.logDate` merupakan tanggal kalender (`YYYY-MM-DD`) menurut timezone pengguna. Kombinasi `habitId + logDate` harus unik. Tanggal masa depan (`logDate > todayLocal`) ditolak dengan `400 Bad Request`.

#### Tambahan Custom SQL Constraint pada Migration Pertama (`init`)
Tambahkan constraint SQL berikut ke akhir file `backend/prisma/migrations/<timestamp>_init/migration.sql`:

```sql
-- 1. Pastikan email selalu disimpan dalam lowercase
ALTER TABLE "users"
ADD CONSTRAINT "chk_users_email_lowercase"
CHECK ("email" = lower("email"));

-- 2. Pastikan ends_at > starts_at pada calendar_events
ALTER TABLE "calendar_events"
ADD CONSTRAINT "chk_calendar_events_time_order"
CHECK ("ends_at" > "starts_at");

-- 3. Pastikan Reminder terkait ke tepat satu: task_id ATAU event_id (XOR)
ALTER TABLE "reminders"
ADD CONSTRAINT "chk_reminders_target_xor"
CHECK (
  ("task_id" IS NOT NULL AND "event_id" IS NULL) OR
  ("task_id" IS NULL AND "event_id" IS NOT NULL)
);

-- 4. Pastikan target Reminder (task_id / event_id) wajib milik user_id yang sama
-- Menggunakan composite FK MATCH SIMPLE (aktif saat task_id/event_id IS NOT NULL)
ALTER TABLE "reminders"
DROP CONSTRAINT IF EXISTS "reminders_task_id_fkey",
DROP CONSTRAINT IF EXISTS "reminders_event_id_fkey",
ADD CONSTRAINT "fk_reminders_task_owner"
  FOREIGN KEY ("task_id", "user_id")
  REFERENCES "tasks"("id", "user_id")
  ON DELETE CASCADE,
ADD CONSTRAINT "fk_reminders_event_owner"
  FOREIGN KEY ("event_id", "user_id")
  REFERENCES "calendar_events"("id", "user_id")
  ON DELETE CASCADE;

-- 5. Pastikan active_days pada habits berisi 1..7, tidak kosong, dan TANPA duplikat
ALTER TABLE "habits"
ADD CONSTRAINT "chk_habits_active_days_range_and_unique"
CHECK (
  cardinality("active_days") BETWEEN 1 AND 7 AND
  "active_days" <@ ARRAY[1, 2, 3, 4, 5, 6, 7] AND
  cardinality(array_positions("active_days", 1)) <= 1 AND
  cardinality(array_positions("active_days", 2)) <= 1 AND
  cardinality(array_positions("active_days", 3)) <= 1 AND
  cardinality(array_positions("active_days", 4)) <= 1 AND
  cardinality(array_positions("active_days", 5)) <= 1 AND
  cardinality(array_positions("active_days", 6)) <= 1 AND
  cardinality(array_positions("active_days", 7)) <= 1
);
```

---

### 3.1 Spesifikasi Presisi Perhitungan `currentStreak` Habit

Agar backend dan UI Flutter menghasilkan angka yang 100% identik, perhitungan `currentStreak` didefinisikan secara deterministik di backend sebagai berikut:

1. **Penentuan `todayLocal`:** Ambil tanggal kalender saat ini dalam zona waktu akun (`user.timezone`, misal `Asia/Jakarta`) dengan format `YYYY-MM-DD`.
2. **Filter Hari Aktif (`activeDays`):** Sebuah tanggal `d` adalah *scheduled day* jika dan hanya jika `isoWeekday(d)` (`1` = Senin s/d `7` = Minggu) terdapat di dalam `habit.activeDays`. Hari yang **bukan** anggota `activeDays` diabaikan sepenuhnya (tidak menambah *streak* dan **tidak memutus** *streak*).
3. **Aturan Evaluasi Hari Ini (`todayLocal`):**
   - Jika `todayLocal` adalah *scheduled day* dan **sudah** memiliki `HabitLog`, maka `streak` dimulai dari `1` dan iterasi mundur memeriksa *scheduled day* sebelumnya.
   - Jika `todayLocal` adalah *scheduled day* tetapi **belum** memiliki `HabitLog`, *streak* **tidak langsung bernilai 0** (karena hari ini belum berakhir). Iterasi dimulai dari *scheduled day* terakhir sebelum `todayLocal`.
   - Jika `todayLocal` bukan *scheduled day*, iterasi langsung dimulai dari *scheduled day* terakhir sebelum `todayLocal`.
4. **Iterasi Mundur:**
   - Bergerak mundur dari tanggal awal iterasi ke *scheduled day* sebelumnya satu per satu:
     - Selama tanggal `d` memiliki `HabitLog`, tambahkan `streak += 1`.
     - Begitu menemukan *scheduled day* `d` yang **tidak** memiliki `HabitLog`, hentikan iterasi.
5. **Kasus Batas (Edge Cases):**
   - **Habit Baru Dibuat Hari Ini:** Jika belum di-*check-in* hari ini, tidak ada *scheduled day* sebelumnya yang memiliki log $\rightarrow$ `currentStreak = 0`. Begitu di-*check-in* hari ini $\rightarrow$ `currentStreak = 1`.
   - **Habit Dinonaktifkan (`isActive = false`):** Tidak dihitung dalam `habits.scheduled` pada `GET /dashboard/today`, namun `currentStreak` historisnya tetap dihitung menggunakan rumus yang sama jika dilihat di halaman daftar habit.
   - **Log Masa Depan (`logDate > todayLocal`):** Ditolak saat input (`400 Bad Request`) dan selalu diabaikan oleh fungsi kalkulasi *streak* (`WHERE log_date <= todayLocal`).

---

### 3.2 Kontrak Status Reminder & Rekonsiliasi Notifikasi Lokal Android

Karena notifikasi dieksekusi secara lokal oleh OS Android sedangkan *state* disimpan di PostgreSQL, arti setiap status dan aturan sinkronisasinya ditetapkan sebagai berikut:

#### Semantik `ReminderStatus`
| Status | Definisi Eksplisit | Siapa yang Mengubah |
| :--- | :--- | :--- |
| `SCHEDULED` | Reminder terdaftar aktif dan waktu `remindAt` berada di masa depan saat dijadwalkan. | Backend (saat `POST /reminders` atau `PATCH` waktu baru di masa depan) |
| `SENT` | Perangkat Android melaporkan bahwa jadwal pengingat lokal telah dipicu/diselesaikan oleh sistem atau waktu `remindAt` telah lewat saat izin notifikasi aktif. *(Bukan jaminan pengguna mengetuk notifikasi).* | Flutter Client melalui `PATCH /reminders/:id` (`{ "status": "SENT" }`) saat callback notifikasi atau saat rekonsiliasi app startup |
| `CANCELLED` | Pengingat dibatalkan sebelum waktunya (baik manual oleh user maupun otomatis karena Task selesai). | Pengguna via `PATCH`, atau Backend secara otomatis saat Task berstatus `DONE` |
| `FAILED` | Perangkat gagal menjadwalkan alarm lokal (misal izin `POST_NOTIFICATIONS` dicabut/ditolak di Android 13+). | Flutter Client melalui `PATCH /reminders/:id` (`{ "status": "FAILED" }`) |

#### Matriks Mutasi Target & Rescheduling di Android
1. **Reminder Dibuat (`POST /reminders`):**
   - Backend memvalidasi kepemilikan `taskId`/`eventId`, aturan XOR, dan memastikan `remindAt > NOW()`, lalu menyimpan dengan `status = SCHEDULED`.
   - Flutter menerima response, menghitung `notificationId = deterministicInt32(reminder.id)`, dan memanggil `zonedSchedule(...)` di Android. Jika izin notifikasi ditolak, Flutter memanggil `PATCH /reminders/:id` dengan `status = FAILED`.
2. **Waktu Reminder Diubah (`PATCH /reminders/:id` dengan `remindAt` baru):**
   - Jika `remindAt > NOW()`, backend otomatis mengeset `status = SCHEDULED`.
   - Flutter membatalkan jadwal lama (`cancel(notificationId)`) dan menjadwalkan ulang pada waktu baru.
3. **Task Diubah Menjadi `DONE` (`PATCH /tasks/:id`):**
   - Backend dalam transaksi yang sama mengubah seluruh reminder terkait yang berstatus `SCHEDULED` menjadi `CANCELLED`.
   - Flutter membatalkan seluruh notifikasi lokal untuk reminder milik task tersebut. *(Jika Task dibuka kembali menjadi `TODO`/`IN_PROGRESS`, reminder yang sudah `CANCELLED` tidak aktif sendiri secara diam-diam; pengguna dapat mengaktifkan/mengatur ulang `remindAt` jika masih di masa depan).*
4. **Task atau CalendarEvent Dihapus (`DELETE /tasks/:id` atau `DELETE /calendar/events/:id`):**
   - Sebelum/saat penghapusan berhasil, Flutter membatalkan notifikasi lokal terkait di perangkat, sementara PostgreSQL menghapus baris `reminders` melalui `ON DELETE CASCADE`.
5. **Rekonsiliasi Saat App Startup / Resume / Device Reboot:**
   - Setiap kali aplikasi dibuka kembali (online), Flutter memanggil `GET /reminders?status=SCHEDULED`:
     - Bandingkan dengan daftar `pendingNotificationRequests()` dari `flutter_local_notifications`.
     - Batalkan *orphan local notification* di Android yang tidak lagi ada di daftar `SCHEDULED` server.
     - Untuk item `SCHEDULED` yang `remindAt <= NOW()`: perbarui ke backend menjadi `SENT` (jika izin notifikasi aktif) atau `FAILED` (jika izin notifikasi mati).
     - Untuk item `SCHEDULED` yang `remindAt > NOW()` tetapi belum ada di `pendingNotificationRequests()` (misal habis *reboot*): jadwalkan ulang ke Android.

---

### 3.3 Aturan Batas Tanggal, Interval `[start, end)`, dan Zona Waktu Query

Seluruh endpoint yang menerima parameter tanggal atau rentang waktu wajib mematuhi aturan konversi zona waktu akun (`user.timezone`, default `"Asia/Jakarta"`) dengan semantik **interval setengah-terbuka `[startUtc, endUtc)`** (`>= startUtc` dan `< endUtc`) agar tidak ada item di tepat pukul `00:00:00.000` yang terhitung dua kali di dua hari berbeda:

1. **Konversi Satu Tanggal Lokal (`date=YYYY-MM-DD`):**
   - `dayStartUtc` = `YYYY-MM-DD 00:00:00.000` pada `user.timezone` yang dikonversi ke UTC (inklusif `>=`).
   - `dayEndUtc` = `(YYYY-MM-DD + 1 hari) 00:00:00.000` pada `user.timezone` yang dikonversi ke UTC (eksklusif `<`).
   - *Contoh (`Asia/Jakarta`, UTC+7) untuk `2026-10-18`:*
     - `dayStartUtc = 2026-10-17T17:00:00.000Z`
     - `dayEndUtc   = 2026-10-18T17:00:00.000Z`
2. **Konversi Rentang Tanggal (`from` dan `to`):**
   - Jika `from` dan `to` dikirim dalam format tanggal `YYYY-MM-DD`:
     - `rangeStartUtc` = awal hari `from` (`00:00:00.000` di `user.timezone`, inklusif `>=`).
     - `rangeEndUtc` = awal hari `to + 1 hari` (`00:00:00.000` di `user.timezone`, eksklusif `<`).
   - Jika dikirim dalam format ISO-8601 timestamp penuh (`YYYY-MM-DDTHH:mm:ssZ`):
     - Gunakan langsung `[fromUtc, toUtc)` (`>= fromUtc` dan `< toUtc`). Validasi wajib menolak jika `from >= to` (`400 Bad Request`).
3. **Kondisi Filter per Entitas pada Interval `[rangeStartUtc, rangeEndUtc)`:**
   - **`Task` berdasarkan `dueAt`:** `dueAt >= rangeStartUtc AND dueAt < rangeEndUtc`.
   - **`CalendarEvent` (Beririsan / Overlapping):** Sebuah kegiatan tampil pada rentang tersebut jika dan hanya jika `startsAt < rangeEndUtc AND endsAt > rangeStartUtc` (sehingga kegiatan lintas tengah malam tetap tampil di kedua tanggal yang beririsan).
   - **`HabitLog` berdasarkan `logDate` (`@db.Date`):** Karena `logDate` sudah berupa tanggal kalender lokal `YYYY-MM-DD`, filter menggunakan `logDate >= fromDate AND logDate <= toDate`.

---

## 4. Kontrak REST API

- **Base Path API:** `/api/v1`
- **Format Payload:** `application/json`
- **Autentikasi:** Endpoint terproteksi menggunakan header `Authorization: Bearer <access_token>`
- **Standar Envelope Response:**
  - Single resource: `{ "data": { ... } }`
  - Paginated list: `{ "data": [ ... ], "meta": { "page": 1, "limit": 20, "totalItems": 42, "totalPages": 3 } }`

### 4.1 Authentication

| Method | Endpoint | Fungsi |
| :--- | :--- | :--- |
| `POST` | `/auth/register` | Membuat akun baru (email dinormalisasi ke lowercase) |
| `POST` | `/auth/login` | Login dan mendapatkan pasangan access + refresh token |
| `POST` | `/auth/refresh` | Rotasi atomik access & refresh token (dengan *reuse detection*) |
| `POST` | `/auth/logout` | Mencabut refresh token aktif (`revokedAt = NOW()`) |
| `GET` | `/auth/me` | Mendapatkan profil pengguna yang sedang login |

**Aturan Validasi DTO Auth:**
- `name`: string, trimmed, `1..100` karakter.
- `email`: string, valid email format, maks `254` karakter, otomatis di-transform `.trim().toLowerCase()`.
- `password`: string, `8..128` karakter.
- `timezone`: string opsional (default `"Asia/Jakarta"`), wajib berupa identifier zona waktu IANA yang valid (`Intl.supportedValuesOf('timeZone')`).

**Contoh Request `POST /auth/register`:**
```json
{
  "name": "Rayhan",
  "email": "rayhan@example.com",
  "password": "strong-password",
  "timezone": "Asia/Jakarta"
}
```

**Response Sukses `201 Created` (`register`) / `200 OK` (`login`, `refresh`):**
```json
{
  "data": {
    "user": {
      "id": "uuid",
      "name": "Rayhan",
      "email": "rayhan@example.com",
      "timezone": "Asia/Jakarta"
    },
    "accessToken": "short-lived-jwt-token",
    "refreshToken": "opaque-or-jwt-refresh-token",
    "expiresIn": 900
  }
}
```

**Request `POST /auth/refresh` & `POST /auth/logout`:**
```json
{
  "refreshToken": "opaque-or-jwt-refresh-token"
}
```

### 4.2 Task Management

| Method | Endpoint | Fungsi |
| :--- | :--- | :--- |
| `GET` | `/tasks` | Daftar tugas berpaginasi dengan filter & pencarian |
| `POST` | `/tasks` | Membuat tugas baru |
| `GET` | `/tasks/:id` | Detail satu tugas beserta daftar reminder terkait |
| `PATCH` | `/tasks/:id` | Mengubah atribut atau status tugas |
| `DELETE` | `/tasks/:id` | Menghapus tugas (`200 OK` dengan `{ "data": { "id": "uuid", "deleted": true } }`) |

**Query Parameters `GET /tasks`:**
- `status` (opsional): `TODO` | `IN_PROGRESS` | `DONE`
- `priority` (opsional): `LOW` | `MEDIUM` | `HIGH`
- `from` & `to` (opsional): filter rentang `dueAt` menggunakan aturan interval `[startUtc, endUtc)`
- `search` (opsional): string `1..100` karakter, *case-insensitive substring match* (`ILIKE`) pada `title` atau `description`
- `page` (opsional): integer `>= 1`, default `1`
- `limit` (opsional): integer `1..100`, default `20`
- **Default Sorting:** Tugas berstatus belum selesai (`TODO`, `IN_PROGRESS`) diurutkan berdasarkan `dueAt ASC NULLS LAST`, lalu `priority DESC` (`HIGH` $\rightarrow$ `MEDIUM` $\rightarrow$ `LOW`), lalu `createdAt DESC`.

**Contoh Request `POST /tasks`:**
```json
{
  "title": "Menyelesaikan proyek Flutter",
  "description": "Implementasi task manager",
  "priority": "HIGH",
  "dueAt": "2026-10-20T12:00:00.000Z"
}
```

**Response `201 Created`:**
```json
{
  "data": {
    "id": "uuid",
    "title": "Menyelesaikan proyek Flutter",
    "description": "Implementasi task manager",
    "status": "TODO",
    "priority": "HIGH",
    "dueAt": "2026-10-20T12:00:00.000Z",
    "completedAt": null,
    "createdAt": "2026-10-18T12:00:00.000Z",
    "updatedAt": "2026-10-18T12:00:00.000Z"
  }
}
```

### 4.3 Habit Tracker

| Method | Endpoint | Fungsi |
| :--- | :--- | :--- |
| `GET` | `/habits` | Daftar kebiasaan pengguna beserta `currentStreak`, `completedToday`, dan `weeklyLogs` |
| `POST` | `/habits` | Membuat kebiasaan baru |
| `GET` | `/habits/:id` | Detail satu kebiasaan beserta `currentStreak` |
| `PATCH` | `/habits/:id` | Mengubah kebiasaan (`name`, `description`, `activeDays`, `isActive`) |
| `DELETE` | `/habits/:id` | Menghapus kebiasaan |
| `GET` | `/habits/:id/logs` | Histori *check-in* dalam rentang `?from=YYYY-MM-DD&to=YYYY-MM-DD` (diurutkan `logDate DESC`) |
| `PUT` | `/habits/:id/logs/:date` | Menetapkan status *check-in* secara idempotent untuk tanggal `:date` (`YYYY-MM-DD`) |

**Contoh Request `POST /habits`:**
```json
{
  "name": "Membaca",
  "description": "Membaca selama 20 menit",
  "activeDays": [1, 2, 3, 4, 5, 6, 7]
}
```

**Contoh Request & Response `PUT /habits/:id/logs/2026-10-18`:**
```json
// Request
{
  "completed": true
}

// Response 200 OK
{
  "data": {
    "habitId": "uuid",
    "logDate": "2026-10-18",
    "completed": true,
    "completedAt": "2026-10-18T12:30:00.000Z",
    "currentStreak": 5
  }
}
```

### 4.4 Kalender dan Kegiatan

| Method | Endpoint | Fungsi |
| :--- | :--- | :--- |
| `GET` | `/calendar/events?from=...&to=...` | Agenda gabungan (kegiatan + tugas ber-deadline) dalam rentang `[from, to)` |
| `POST` | `/calendar/events` | Membuat kegiatan terjadwal (`endsAt > startsAt`) |
| `GET` | `/calendar/events/:id` | Detail kegiatan beserta reminder terkait |
| `PATCH` | `/calendar/events/:id` | Mengubah kegiatan |
| `DELETE` | `/calendar/events/:id` | Menghapus kegiatan |

**Contoh Response `GET /calendar/events?from=2026-10-18&to=2026-10-18`:**
```json
{
  "data": {
    "from": "2026-10-18",
    "to": "2026-10-18",
    "events": [
      {
        "id": "event-uuid",
        "type": "EVENT",
        "title": "Belajar pemrograman",
        "description": null,
        "location": "Rumah",
        "startsAt": "2026-10-18T01:00:00.000Z",
        "endsAt": "2026-10-18T03:00:00.000Z"
      }
    ],
    "tasks": [
      {
        "id": "task-uuid",
        "type": "TASK",
        "title": "Menyelesaikan proyek Flutter",
        "status": "TODO",
        "priority": "HIGH",
        "dueAt": "2026-10-18T05:00:00.000Z"
      }
    ]
  }
}
```
*Daftar `events` diurutkan berdasarkan `startsAt ASC`, sedangkan `tasks` diurutkan berdasarkan `dueAt ASC`.*

### 4.5 Reminder

| Method | Endpoint | Fungsi |
| :--- | :--- | :--- |
| `GET` | `/reminders` | Daftar pengingat pengguna (filter opsional `?status=SCHEDULED`, urut `remindAt ASC`) |
| `POST` | `/reminders` | Membuat pengingat untuk tepat satu `taskId` atau `eventId` milik user sendiri |
| `PATCH` | `/reminders/:id` | Mengubah waktu (`remindAt`) atau status (`SCHEDULED`\|`SENT`\|`CANCELLED`\|`FAILED`) |
| `DELETE` | `/reminders/:id` | Menghapus pengingat |

**Contoh Request & Response `POST /reminders`:**
```json
// Request
{
  "taskId": "task-uuid",
  "remindAt": "2026-10-19T08:00:00+07:00",
  "channel": "LOCAL"
}

// Response 201 Created
{
  "data": {
    "id": "reminder-uuid",
    "taskId": "task-uuid",
    "eventId": null,
    "remindAt": "2026-10-19T01:00:00.000Z",
    "channel": "LOCAL",
    "status": "SCHEDULED",
    "createdAt": "2026-10-18T12:00:00.000Z",
    "updatedAt": "2026-10-18T12:00:00.000Z"
  }
}
```

### 4.6 Dashboard dan Statistik

| Method | Endpoint | Fungsi |
| :--- | :--- | :--- |
| `GET` | `/dashboard/today?date=YYYY-MM-DD` | Ringkasan harian terpadu (ditafsirkan dalam `user.timezone`) |
| `GET` | `/statistics/overview?from=YYYY-MM-DD&to=YYYY-MM-DD` | Statistik agregat dalam rentang tanggal `[from, to)` |
| `GET` | `/statistics/weekly?weekStart=YYYY-MM-DD` | Tren harian selama 7 hari (`weekStart` s/d `weekStart + 6 hari`) |

**Contoh Bentuk Response `GET /dashboard/today?date=2026-10-18`:**
```json
{
  "data": {
    "date": "2026-10-18",
    "timezone": "Asia/Jakarta",
    "tasks": {
      "total": 5,
      "completed": 2,
      "pending": 3,
      "overdue": 1
    },
    "habits": {
      "scheduled": 3,
      "completed": 1
    },
    "upcomingEvents": [],
    "todayTasks": [],
    "todayHabits": []
  }
}
```

**Contoh Bentuk Response `GET /statistics/overview?from=2026-10-12&to=2026-10-18`:**
```json
{
  "data": {
    "from": "2026-10-12",
    "to": "2026-10-18",
    "tasks": {
      "total": 12,
      "completed": 9,
      "overdue": 1,
      "completionRate": 75.0
    },
    "habits": {
      "totalScheduledInstances": 21,
      "totalCompletedInstances": 18,
      "consistencyRate": 85.7
    }
  }
}
```

**Contoh Bentuk Response `GET /statistics/weekly?weekStart=2026-10-12`:**
```json
{
  "data": {
    "weekStart": "2026-10-12",
    "weekEnd": "2026-10-18",
    "days": [
      {
        "date": "2026-10-12",
        "isoWeekday": 1,
        "tasksCompleted": 2,
        "habitsScheduled": 3,
        "habitsCompleted": 3
      }
    ]
  }
}
```

### Format Error API Standar
Seluruh exception di NestJS diformat melalui Global Exception Filter yang konsisten:

```json
{
  "statusCode": 400,
  "code": "VALIDATION_ERROR",
  "message": "Request validation failed",
  "details": {
    "title": ["Title is required"]
  }
}
```
- `400 Bad Request`: Validasi DTO atau aturan bisnis gagal (`VALIDATION_ERROR`, `INVALID_TIME_RANGE`, `REMINDER_TARGET_XOR_VIOLATION`, `FUTURE_HABIT_LOG_NOT_ALLOWED`).
- `401 Unauthorized`: Token tidak ada, kedaluwarsa, dicabut, atau terdeteksi dipakai ulang (`UNAUTHORIZED`, `TOKEN_REUSE_DETECTED`).
- `403 Forbidden`: Akses ditolak (`FORBIDDEN_RESOURCE`).
- `404 Not Found`: Resource tidak ditemukan atau bukan milik pengguna (`RESOURCE_NOT_FOUND`).
- `409 Conflict`: Email sudah terdaftar atau duplikasi unik (`CONFLICT_ERROR`).
- `500 Internal Server Error`: Kesalahan server tak terduga tanpa membocorkan *stack trace* atau detail tabel database.

---

## 5. Struktur Project Final (Monorepo)

Gunakan monorepo di direktori kerja utama dengan pemisahan `mobile/` (Flutter) dan `backend/` (NestJS).

```text
lifeos/
├── planning/
│   ├── README.md
│   ├── 01-prd.md
│   ├── 02-design-brief.md
│   ├── 03-technical-spec.md
│   ├── 04-architecture-security-testing.md
│   └── 05-engineering-playbooks.md
├── mobile/
│   ├── android/
│   ├── assets/
│   │   ├── icons/
│   │   └── images/
│   ├── lib/
│   │   ├── app/
│   │   │   ├── app.dart
│   │   │   ├── router.dart
│   │   │   └── theme.dart
│   │   ├── core/
│   │   │   ├── api/
│   │   │   ├── errors/
│   │   │   ├── storage/
│   │   │   ├── notifications/
│   │   │   └── widgets/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── data/
│   │   │   │   ├── domain/
│   │   │   │   └── presentation/
│   │   │   ├── dashboard/
│   │   │   ├── tasks/
│   │   │   ├── habits/
│   │   │   ├── calendar/
│   │   │   ├── reminders/
│   │   │   └── statistics/
│   │   └── main.dart
│   └── test/
│
├── backend/
│   ├── prisma/
│   │   ├── schema.prisma
│   │   └── migrations/
│   ├── src/
│   │   ├── main.ts
│   │   ├── app.module.ts
│   │   ├── prisma/
│   │   ├── common/
│   │   │   ├── decorators/
│   │   │   ├── filters/
│   │   │   ├── guards/
│   │   │   └── pipes/
│   │   ├── auth/
│   │   ├── users/
│   │   ├── tasks/
│   │   ├── habits/
│   │   ├── calendar/
│   │   ├── reminders/
│   │   ├── dashboard/
│   │   └── statistics/
│   ├── test/
│   ├── .env.example
│   └── package.json
│
├── docker-compose.yml
├── .gitignore
└── README.md
```

---

## 6. Konfigurasi Development

### `backend/.env.example`
```dotenv
NODE_ENV=development
PORT=3000

DATABASE_URL="postgresql://lifeos:change-me@localhost:5432/lifeos?schema=public"

JWT_ACCESS_SECRET="replace-with-a-long-random-secret"
JWT_ACCESS_TTL="15m"

# Simpan hash token refresh, bukan token mentah.
REFRESH_TOKEN_TTL_DAYS=30
```

### `docker-compose.yml`
```yaml
services:
  postgres:
    image: postgres:17
    restart: unless-stopped
    environment:
      POSTGRES_DB: lifeos
      POSTGRES_USER: lifeos
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-dev-only-password}
    ports:
      - "5432:5432"
    volumes:
      - lifeos_pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U lifeos -d lifeos"]
      interval: 5s
      timeout: 3s
      retries: 10

volumes:
  lifeos_pgdata:
```

> [!TIP]
> **Koneksi Android Emulator ke Localhost:** Pada Android Emulator standar, `localhost` menunjuk ke emulator itu sendiri. Gunakan `http://10.0.2.2:3000/api/v1` untuk mengakses backend yang berjalan di komputer host, atau alamat IP LAN (misal `http://192.168.1.x:3000/api/v1`) saat menguji pada perangkat Android fisik.

### Urutan Inisialisasi Backend
```bash
# 1. Buat backend
npx @nestjs/cli new backend

# 2. Masuk ke backend
cd backend

# 3. Install dependency
npm install @nestjs/config @nestjs/jwt @nestjs/passport @nestjs/swagger
npm install passport passport-jwt argon2
npm install class-validator class-transformer
npm install @prisma/client@6
npm install -D prisma@6

# 4. Inisialisasi Prisma
npx prisma init

# 5. Setelah schema.prisma siap
npx prisma migrate dev --name init
npx prisma generate

# 6. Jalankan backend
npm run start:dev
```

---

## 7. Kriteria Penerimaan MVP

Sebelum dianggap selesai, LifeOS wajib memenuhi seluruh kriteria berikut:
- [ ] Pengguna bisa mendaftar, login, refresh sesi secara otomatis, dan logout.
- [ ] Pengguna bisa membuat, mengubah, menyelesaikan, memfilter, mencari, dan menghapus tugas.
- [ ] Pengguna bisa membuat kebiasaan, melakukan *check-in* harian idempotent, dan melihat riwayat serta *streak*.
- [ ] Kalender menampilkan kegiatan (`CalendarEvent`) dan tugas (`Task`) sesuai tanggal serta zona waktu pengguna.
- [ ] Reminder dapat dibuat, diubah, dibatalkan, dan dijadwalkan sebagai notifikasi lokal pada Android.
- [ ] Dashboard dan statistik mencerminkan data database yang sebenarnya secara akurat.
- [ ] Pengguna tidak dapat membaca atau mengubah data milik akun lain (isolasi penuh per `userId`).
- [ ] Penanganan *error*, *loading shimmer*, *empty state*, dan koneksi gagal tersedia di Flutter.
- [ ] Migration database dapat dijalankan ulang (`prisma migrate deploy` / `migrate reset`) pada lingkungan baru tanpa error.
- [ ] Pengujian unit dan integrasi mencakup logika penting serta kontrol akses.

---

## 8. Urutan Implementasi yang Disarankan

1. **Fase 1 — Fondasi:** Monorepo, Docker PostgreSQL 17, NestJS bootstrap, Prisma 6, migration + SQL check constraints, validasi global, exception filter, dan Swagger (`/api/docs`).
2. **Fase 2 — Autentikasi:** Register, Login, Refresh Token Rotation, Logout, Guard JWT, serta integrasi `flutter_secure_storage` dan Dio Auth Interceptor di Flutter.
3. **Fase 3 — Task Management:** Selesaikan seluruh alur CRUD, filter, dan pencarian dari Flutter sampai PostgreSQL.
4. **Fase 4 — Habit Tracker:** CRUD jadwal kebiasaan, idempotent daily check-in, histori log, dan algoritma perhitungan *streak*.
5. **Fase 5 — Dashboard & Kalender:** Query agregasi harian dan tampilan agenda gabungan berdasarkan tanggal & zona waktu.
6. **Fase 6 — Reminder & Statistik:** Penjadwalan notifikasi lokal Android (`flutter_local_notifications`), sinkronisasi status reminder, grafik laporan mingguan, dan pengujian akhir.
