# LifeOS — Product Requirements Document (PRD)

**Dokumen:** `01-prd.md`  
**Produk:** LifeOS (Personal Productivity App · Android)  
**Tech Stack:** Flutter · NestJS · Prisma 6 · PostgreSQL 17  
**Status:** Approved for MVP Development  

---

## 1. Problem Statement

Mahasiswa dan pelajar mengelola kehidupan akademik serta pengembangan diri mereka secara terfragmentasi: jadwal kuliah dan kegiatan organisasi dicatat di kalender, tugas kuliah dan praktikum dicatat di aplikasi *to-do* atau chat pribadi, kebiasaan belajar dicatat di aplikasi *habit tracker* terpisah, dan pengingat dipasang melalui alarm bawaan ponsel.

Fragmentasi ini menimbulkan tiga kerugian langsung:
1. **Cognitive Overload & Context Switching:** Pengguna harus membuka 3–4 aplikasi berbeda setiap pagi hanya untuk menjawab pertanyaan sederhana: *"Apa yang harus saya kerjakan dan hadiri hari ini?"*
2. **Kegagalan Eksekusi Deadline (Missed Deadlines):** Tugas yang memiliki tenggat waktu tidak terlihat berdampingan dengan jadwal kuliah atau kegiatan harian di kalender, sehingga pengguna salah memperkirakan kapasitas waktu luang mereka.
3. **Ilusi Produktivitas tanpa Evaluasi Nyata:** Pengguna mencentang tugas atau kebiasaan secara terpisah tanpa pernah melihat korelasi antara konsistensi kebiasaan harian, beban kegiatan, dan tingkat penyelesaian tugas mingguan mereka.

**LifeOS** menyelesaikan masalah ini dengan menyatukan manajemen tugas (*Task*), jadwal kegiatan (*Calendar Event*), pelacak kebiasaan (*Habit Tracker*), pengingat (*Local Notification Reminder*), dan statistik progres ke dalam **satu dashboard terintegrasi** yang dihitung langsung dari data sumber tanpa duplikasi.

---

## 2. Target User & Persona

### Target Utama
Mahasiswa dan pelajar aktif (usia 17–24 tahun) pengguna perangkat Android yang memiliki kombinasi jadwal tetap (kelas/kuliah/bimbingan), tugas berbasis tenggat waktu (individu/kelompok), serta target kebiasaan rutin (belajar mandiri, membaca, olahraga).

### Persona 1: Raka — Mahasiswa Semester 5 (Akademik + Organisasi)
- **Profil:** Mahasiswa Teknik Informatika usia 20 tahun, mengambil 21 SKS, aktif di himpunan mahasiswa dan asisten praktikum.
- **Perilaku Saat Ini:** Mencatat tugas di Notion, jadwal rapat di Google Calendar, dan memasang alarm HP untuk pengingat kumpul tugas. Sering lupa tugas kuis kecil karena tertutup kesibukan rapat organisasi.
- **Pain Points:**
  - Notion terlalu lambat dibuka di HP hanya untuk mengecek atau menambah satu tugas cepat.
  - Tidak bisa melihat jadwal rapat dan tenggat waktu tugas dalam satu tampilan tanggal yang sama.
  - Sering melewatkan target belajar *coding* harian karena tidak ada pengukur konsistensi (*streak*) yang ringan.
- **Kebutuhan di LifeOS:** Dashboard pagi yang merangkum agenda hari ini + tugas mendesak, *quick-add task* kurang dari 10 detik, dan pengingat lokal yang andal sebelum tenggat tugas.

### Persona 2: Nadia — Mahasiswi Tingkat Akhir / Pelajar Persiapan Ujian
- **Profil:** Mahasiswi semester 7 usia 21 tahun yang sedang menyusun proposal skripsi sambil membangun rutinitas belajar disiplin setiap hari.
- **Perilaku Saat Ini:** Menggunakan aplikasi *habit tracker* gratis yang penuh iklan dan aplikasi *notes* bawaan HP untuk daftar revisi dosen.
- **Pain Points:**
  - Sulit melacak progres mingguan apakah minggu ini lebih produktif dibanding minggu lalu.
  - Kebiasaan yang tidak dijadwalkan setiap hari (misal: hanya Senin–Rabu–Jumat) sering mengacaukan perhitungan *streak* di aplikasi lain.
  - Butuh tampilan yang bersih, bebas gangguan, dan langsung fokus pada eksekusi harian.
- **Kebutuhan di LifeOS:** Penjadwalan *habit* berdasarkan hari aktif (`activeDays`), *check-in* satu sentuhan dari dashboard, dan statistik tren penyelesaian tugas serta konsistensi kebiasaan mingguan.

---

## 3. Goals dan Non-Goals

### Goals (Target MVP)
1. **Satu Pusat Kendali Harian:** Menyediakan *Dashboard Harian* yang merangkum ringkasan tugas (selesai, tertunda, terlambat), jadwal kegiatan hari ini, dan target kebiasaan aktif dalam satu layar.
2. **Kalender Terpadu Tanpa Duplikasi Data:** Menggabungkan entitas `Task` (yang memiliki `dueAt`) dan `CalendarEvent` (`startsAt` – `endsAt`) secara dinamis pada tampilan kalender bulanan dan agenda mingguan.
3. **Eksekusi Cepat & Andal:** Memungkinkan pembuatan tugas, *check-in* kebiasaan, dan penjadwalan pengingat lokal Android dalam maksimal 3 interaksi layar.
4. **Akurasi Data Berdasarkan Zona Waktu:** Memastikan seluruh perhitungan tanggal harian (`HabitLog`, batas *overdue* tugas, ringkasan `dashboard/today`) konsisten terhadap zona waktu pengguna (`Asia/Jakarta` / IANA timezone).
5. **Keamanan & Isolasi Multi-User:** Menjamin setiap pengguna hanya dapat mengakses dan memodifikasi datanya sendiri melalui autentikasi JWT (*short-lived access token* + *revocable hashed refresh token*).

### Non-Goals (Di Luar Ruang Lingkup MVP)
1. **Kolaborasi Tim / Sharing:** Tidak ada fitur berbagi tugas, *shared calendar*, atau *assign* tugas ke pengguna lain (murni *single-player personal productivity*).
2. **Integrasi Kalender Eksternal:** Tidak ada sinkronisasi dua arah dengan Google Calendar, Outlook, atau Apple Calendar pada versi MVP.
3. **AI Planner / Auto-Scheduling:** Tidak ada fitur rekomendasi jadwal otomatis berbasis AI/LLM.
4. **Sinkronisasi Multi-Perangkat Realtime & Offline Queue Kompleks:** Tidak menggunakan WebSocket untuk sinkronisasi *realtime* antarperangkat, dan tidak menerapkan antrean mutasi *offline-first* (`pending_sync`); MVP menggunakan pendekatan **online-first dengan local caching untuk baca data** serta penjadwalan **local notification** di Android.
5. **Recurring Task & Recurring Reminder Kompleks:** Pengulangan hanya berlaku untuk *Habit* (berdasarkan hari aktif dalam seminggu). Tugas berulang (*recurring tasks*) dan pengingat berulang bertingkat tidak termasuk dalam MVP.

---

## 4. User Stories

### Autentikasi & Akun
- **US-01:** Sebagai mahasiswa baru di aplikasi, saya ingin mendaftar akun menggunakan nama, email, password, dan zona waktu supaya data produktivitas saya tersimpan aman di server.
- **US-02:** Sebagai pengguna terdaftar, saya ingin tetap masuk ke aplikasi tanpa harus *login* ulang setiap 15 menit (melalui mekanisme *refresh token* otomatis) supaya alur pencatatan tugas saya tidak terganggu.
- **US-03:** Sebagai pengguna, saya ingin dapat *logout* sehingga sesi token saya dicabut di server dan seluruh pengingat lokal serta *cache* di perangkat dibersihkan.

### Dashboard Harian
- **US-04:** Sebagai mahasiswa yang sibuk, saya ingin melihat ringkasan jumlah tugas selesai, tertunda, terlambat, jadwal kegiatan hari ini, dan kebiasaan aktif begitu membuka aplikasi supaya saya langsung tahu prioritas hari ini.
- **US-05:** Sebagai pengguna, saya ingin mencentang penyelesaian tugas dan *check-in* kebiasaan langsung dari halaman Dashboard supaya tidak perlu berpindah-pindah menu.

### Task Management
- **US-06:** Sebagai mahasiswa, saya ingin membuat tugas dengan judul, deskripsi opsional, prioritas (`LOW`, `MEDIUM`, `HIGH`), dan tenggat waktu (`dueAt`) supaya seluruh kewajiban kuliah saya tercatat rapi.
- **US-07:** Sebagai pengguna, saya ingin memfilter tugas berdasarkan status (`TODO`, `IN_PROGRESS`, `DONE`), prioritas, rentang tanggal, serta mencari kata kunci judul supaya mudah menemukan tugas tertentu saat daftar sudah banyak.
- **US-08:** Sebagai pengguna, saya ingin mengubah status tugas menjadi `DONE` dan sistem otomatis mencatat waktu penyelesaiannya (`completedAt`), atau mengembalikannya ke `TODO`/`IN_PROGRESS` jika belum selesai.

### Habit Tracker
- **US-09:** Sebagai pelajar, saya ingin membuat kebiasaan dengan memilih hari aktif tertentu dalam seminggu (misal: Senin s/d Jumat saja) supaya target kebiasaan saya realistis sesuai jadwal kuliah.
- **US-10:** Sebagai pengguna, saya ingin melakukan *check-in* kebiasaan satu sentuhan untuk hari ini dan melihat *streak* serta progres mingguan supaya termotivasi menjaga konsistensi.

### Kalender & Kegiatan
- **US-11:** Sebagai mahasiswa, saya ingin membuat jadwal kegiatan (`CalendarEvent`) yang memiliki waktu mulai, waktu selesai, dan lokasi opsional (misal: "Praktikum Basis Data, Lab 3, 08:00–10:00") supaya jadwal kelas dan rapat saya terdata.
- **US-12:** Sebagai pengguna, saya ingin memilih tanggal pada tampilan kalender bulanan/mingguan dan melihat gabungan kegiatan terjadwal beserta tugas yang jatuh tempo pada tanggal tersebut.

### Reminder (Notifikasi Lokal Android)
- **US-13:** Sebagai pengguna, saya ingin memasang pengingat satu kali pada waktu tertentu untuk sebuah tugas atau kegiatan supaya HP saya memunculkan notifikasi tepat waktu meskipun aplikasi sedang ditutup.
- **US-14:** Sebagai pengguna, saya ingin pengingat lokal di HP saya otomatis diperbarui atau dibatalkan ketika saya mengubah waktu pengingat, menyelesaikan tugas, atau menghapus kegiatan terkait.

### Statistik Produktivitas
- **US-15:** Sebagai pengguna, saya ingin melihat persentase penyelesaian tugas, jumlah tugas terlambat, tren penyelesaian mingguan, dan tingkat konsistensi kebiasaan supaya saya bisa mengevaluasi produktivitas belajar saya.

---

## 5. Daftar Fitur: MVP vs v2 vs Nanti

| Kategori | MVP (Versi 1.0 - Saat Ini) | v2 (Iterasi Berikutnya) | Nanti (Future Roadmap) |
| :--- | :--- | :--- | :--- |
| **Auth & Profil** | Register, Login, Refresh Token Rotation, Logout, Get Profile (`/auth/me`), Timezone dasar | Edit profil, ubah password, ganti zona waktu dinamis, Google Sign-In | Biometric app-lock, manajemen sesi perangkat aktif |
| **Dashboard** | Sapaan harian, kartu ringkasan progres, daftar tugas hari ini, agenda terdekat, habit hari ini, tombol cepat tambah tugas | Kustomisasi urutan kartu widget dashboard | Insight harian berbasis pola penyelesaian pengguna |
| **Tasks** | CRUD tugas, status (`TODO`, `IN_PROGRESS`, `DONE`), prioritas (`LOW`, `MEDIUM`, `HIGH`), `dueAt`, filter, *search*, *pagination* | Sub-tugas (*checklist*), kategori/tag mata kuliah, *recurring tasks* | Lampiran file/foto, kolaborasi tugas kelompok |
| **Habits** | CRUD habit, pengaturan `activeDays` (1–7), *idempotent daily check-in*, riwayat *log*, perhitungan *current streak* | *Longest streak*, arsip habit tanpa hapus histori, pengingat khusus per habit | Habit kuantitatif (misal: minum 8 gelas air, baca 30 halaman) |
| **Calendar** | Tampilan bulanan & agenda mingguan, CRUD `CalendarEvent` (`startsAt`, `endsAt`, `location`), agregasi `Task` + `CalendarEvent` | Deteksi bentrok jadwal (*schedule conflict warning*), warna label kegiatan | Sinkronisasi 2 arah dengan Google Calendar |
| **Reminders** | Satu pengingat lokal (`LOCAL`) atau pencatatan `PUSH` per *record*, terhubung ke 1 Task atau 1 Event, penjadwalan via Android Local Notification | *Multiple reminders* per tugas/kegiatan (misal: H-1 hari dan H-30 menit), *snooze* dari bar notifikasi | Push notification server-driven via Firebase Cloud Messaging (FCM) |
| **Statistics** | Overview rentang tanggal (completion rate, overdue count) & tren mingguan (tugas selesai & konsistensi habit per hari) | Grafik perbandingan bulanan, ekspor laporan PDF/CSV | Rekomendasi waktu fokus & analisis beban akademik |
| **Offline & Sync** | *Online-first* dengan *local cache* untuk baca data terakhir & persistensi jadwal *local notification* | Antrean mutasi offline (`pending_sync`) untuk *check-in* habit dan *toggle* tugas | Sinkronisasi *multi-device realtime* |

---

## 6. Functional Requirements Detail per Fitur MVP

### 6.1 Autentikasi & Manajemen Sesi
- **FR-AUTH-01:** Email wajib unik (maks 254 karakter, dinormalisasi ke *lowercase* dan *trimmed*). Password minimal 8 karakter dan wajib di-*hash* menggunakan **Argon2** sebelum disimpan ke `users.password_hash`.
- **FR-AUTH-02:** Login dan Register mengembalikan `accessToken` JWT berumur pendek (`15m`) dan `refreshToken` berumur `30 hari`.
- **FR-AUTH-03:** `refreshToken` mentah hanya dikirim ke klien, sedangkan database menyimpan hasil *hash*-nya di tabel `refresh_tokens` (`token_hash`) beserta `expires_at` dan `revoked_at`.
- **FR-AUTH-04:** Saat klien memanggil `POST /auth/refresh`, backend memvalidasi bahwa token belum kedaluwarsa dan `revoked_at IS NULL`, mencabut token lama (*token rotation*), dan menerbitkan pasangan token baru.
- **FR-AUTH-05:** Klien Flutter wajib menyimpan kredensial sesi di `flutter_secure_storage`, bukan `SharedPreferences`.

### 6.2 Task Management
- **FR-TASK-01:** Pembuatan tugas wajib memiliki `title` (1–200 karakter). Nilai bawaan: `status = TODO`, `priority = MEDIUM`. `description` dan `dueAt` bersifat opsional.
- **FR-TASK-02:** Transisi status ke `DONE` wajib mengisi `completedAt` dengan *timestamp* UTC saat itu. Transisi dari `DONE` kembali ke `TODO` atau `IN_PROGRESS` wajib mengosongkan `completedAt = null`.
- **FR-TASK-03:** Endpoint `GET /tasks` wajib mendukung filter kombinasi: `status`, `priority`, `from` & `to` (berdasarkan `dueAt`), `search` (*case-insensitive substring match* pada `title` dan `description`), serta `page` dan `limit` (default `page=1`, `limit=20`, maks `limit=100`).
- **FR-TASK-04:** Jika sebuah tugas dihapus atau diubah statusnya menjadi `DONE`, seluruh reminder berstatus `SCHEDULED` yang terhubung ke tugas tersebut otomatis diubah menjadi `CANCELLED` di backend dan dibatalkan di *scheduler* lokal Android.

### 6.3 Habit Tracker
- **FR-HABIT-01:** Setiap kebiasaan memiliki `name` (1–120 karakter), `description` opsional, `isActive` (default `true`), dan `activeDays` berupa array integer unik bernilai `1` (Senin) sampai `7` (Minggu), minimal 1 hari aktif.
- **FR-HABIT-02:** Check-in harian menggunakan `PUT /habits/:id/logs/:date` dengan format `:date` adalah `YYYY-MM-DD` (tanggal kalender menurut zona waktu pengguna) dan payload `{ "completed": boolean }`.
- **FR-HABIT-03:** Operasi `PUT /habits/:id/logs/:date` wajib **idempotent**:
  - Jika `completed: true`: lakukan *upsert* pada `habit_logs` untuk kombinasi unik `(habit_id, log_date)` dan isi `completed_at` dengan waktu sekarang (jika belum ada).
  - Jika `completed: false`: hapus catatan `habit_logs` pada `(habit_id, log_date)` tersebut sehingga status kembali belum selesai tanpa menyisakan baris yatim.
- **FR-HABIT-04:** Perhitungan *Streak* kebiasaan hanya menghitung hari-hari yang terdaftar di `activeDays`. Hari yang tidak termasuk `activeDays` tidak memutus *streak* jika pengguna tidak melakukan *check-in* pada hari tersebut.

### 6.4 Kalender & Kegiatan
- **FR-CAL-01:** Pembuatan kegiatan (`CalendarEvent`) mewajibkan `title` (1–200 karakter), `startsAt`, dan `endsAt`. Validasi wajib menolak input jika `endsAt <= startsAt`.
- **FR-CAL-02:** Endpoint `GET /calendar/events?from=...&to=...` wajib mengembalikan struktur agenda gabungan untuk rentang waktu tersebut yang terdiri dari:
  1. Daftar `CalendarEvent` yang beririsan dengan rentang `[from, to]`.
  2. Daftar `Task` milik pengguna yang memiliki `dueAt` di dalam rentang `[from, to]`.
- **FR-CAL-03:** Tampilan Flutter mengubah seluruh waktu UTC dari API ke zona waktu pengguna sebelum merender titik penanda (*dot indicator*) pada kalender bulanan maupun daftar agenda harian.

### 6.5 Reminder & Notifikasi Lokal
- **FR-REM-01:** Setiap `Reminder` wajib mematuhi aturan eksklusivitas XOR: memiliki tepat satu `taskId` **atau** tepat satu `eventId` (tidak boleh keduanya terisi, tidak boleh keduanya kosong).
- **FR-REM-02:** Kepemilikan `taskId` atau `eventId` wajib diverifikasi milik `userId` yang sedang meminta pembuatan reminder.
- **FR-REM-03:** Setelah `POST /reminders` atau `PATCH /reminders/:id` sukses di backend, Flutter menjadwalkan atau memperbarui notifikasi lokal Android menggunakan ID deterministik yang dipetakan dari UUID reminder.
- **FR-REM-04:** Saat aplikasi dibuka atau melakukan *boot/sync*, Flutter menyinkronkan daftar reminder berstatus `SCHEDULED` yang waktu `remindAt`-nya sudah lewat menjadi `SENT` (atau `FAILED` jika izin notifikasi dicabut) dan menjadwalkan ulang reminder masa depan yang belum terdaftar di *alarm manager* lokal.

### 6.6 Dashboard & Statistik
- **FR-DASH-01:** `GET /dashboard/today?date=YYYY-MM-DD` menghitung batas awal dan akhir hari (`00:00:00.000` s/d `23:59:59.999`) berdasarkan zona waktu profil pengguna.
- **FR-DASH-02:** Aturan perhitungan metrik tugas pada Dashboard untuk tanggal `D`:
  - `total`: Jumlah seluruh tugas yang jatuh tempo pada hari `D` ditambah tugas tanpa `dueAt` yang masih aktif (`TODO`/`IN_PROGRESS`) atau diselesaikan pada hari `D`.
  - `completed`: Tugas yang diselesaikan pada hari `D` atau tugas ber-deadline hari `D` yang berstatus `DONE`.
  - `pending`: Tugas berstatus `TODO` atau `IN_PROGRESS` yang jatuh tempo pada hari `D` (atau tanpa `dueAt`).
  - `overdue`: Tugas berstatus `TODO` atau `IN_PROGRESS` yang memiliki `dueAt < awal hari D` (atau `< waktu sekarang` untuk hari berjalan).
- **FR-DASH-03:** Aturan perhitungan metrik kebiasaan pada Dashboard untuk tanggal `D`:
  - `scheduled`: Jumlah habit dengan `isActive = true` yang `activeDays`-nya memuat hari ke-`N` (ISO weekday dari tanggal `D`).
  - `completed`: Jumlah habit terjadwal pada hari `D` yang memiliki catatan `HabitLog` pada `logDate = D`.
- **FR-STAT-01:** `GET /statistics/overview?from=...&to=...` mengembalikan total tugas, tugas selesai, rasio penyelesaian (`completionRate`), jumlah tugas *overdue*, dan persentase konsistensi kebiasaan dalam rentang tanggal tersebut.
- **FR-STAT-02:** `GET /statistics/weekly?weekStart=YYYY-MM-DD` mengembalikan rincian harian selama 7 hari berturut-turut (jumlah tugas selesai per hari dan jumlah habit selesai vs terjadwal per hari) untuk kebutuhan visualisasi grafik batang/tren mingguan.

---

## 7. Sketsa Data Model (Entitas & Field Kunci)

| Entitas | Tabel DB | Field Kunci | Relasi & Constraint Utama |
| :--- | :--- | :--- | :--- |
| **User** | `users` | `id` (UUID), `email` (Unique), `passwordHash`, `name`, `timezone` (default `"Asia/Jakarta"`), `createdAt`, `updatedAt` | `1:N` ke `Task`, `Habit`, `CalendarEvent`, `Reminder`, `RefreshToken` |
| **Task** | `tasks` | `id` (UUID), `userId`, `title`, `description?`, `status` (`TODO`\|`IN_PROGRESS`\|`DONE`), `priority` (`LOW`\|`MEDIUM`\|`HIGH`), `dueAt?`, `completedAt?` | Milik `User` (`onDelete: Cascade`), `1:N` ke `Reminder`. Index: `(userId, status, dueAt)` |
| **Habit** | `habits` | `id` (UUID), `userId`, `name`, `description?`, `isActive` (Bool), `activeDays` (`Int[]` 1..7) | Milik `User` (`onDelete: Cascade`), `1:N` ke `HabitLog`. Index: `(userId, isActive)` |
| **HabitLog** | `habit_logs` | `id` (UUID), `habitId`, `logDate` (`@db.Date`), `completedAt?` | Milik `Habit` (`onDelete: Cascade`). Unique: `(habitId, logDate)` |
| **CalendarEvent** | `calendar_events` | `id` (UUID), `userId`, `title`, `description?`, `location?`, `startsAt`, `endsAt` | Milik `User` (`onDelete: Cascade`), `1:N` ke `Reminder`. Constraint: `endsAt > startsAt` |
| **Reminder** | `reminders` | `id` (UUID), `userId`, `taskId?`, `eventId?`, `remindAt`, `channel` (`LOCAL`\|`PUSH`), `status` (`SCHEDULED`\|`SENT`\|`CANCELLED`\|`FAILED`) | Milik `User`, opsional ke `Task` atau `CalendarEvent` (XOR). Index: `(userId, status, remindAt)` |
| **RefreshToken** | `refresh_tokens` | `id` (UUID), `userId`, `tokenHash` (Unique), `expiresAt`, `revokedAt?` | Milik `User` (`onDelete: Cascade`). Index: `(userId, expiresAt)` |

---

## 8. Edge Cases dan Failure States

1. **Izin Notifikasi atau Exact Alarm Ditolak di Android 13/14+:**
   - *Perilaku:* Saat pengguna membuat reminder tetapi izin `POST_NOTIFICATIONS` atau `SCHEDULE_EXACT_ALARM` ditolak, reminder tetap tersimpan di backend namun aplikasi menampilkan *banner* peringatan interaktif yang mengarahkan pengguna ke Pengaturan Aplikasi Android, atau melakukan *fallback* ke *inexact alarm* dengan pemberitahuan jelas.
2. **Perangkat Android Reboot atau Force Stop:**
   - *Perilaku:* Jadwal alarm di memori Android hilang saat *reboot*. Plugin notifikasi lokal harus dikonfigurasi dengan `BOOT_COMPLETED` receiver, dan saat aplikasi dibuka kembali, fungsi sinkronisasi reminder wajib menjadwalkan ulang seluruh reminder masa depan yang berstatus `SCHEDULED`.
3. **Check-in Kebiasaan di Sekitar Tengah Malam (23:59 vs 00:01):**
   - *Perilaku:* Klien mengirim parameter `:date` eksplisit (`YYYY-MM-DD`) sesuai tanggal lokal yang sedang dilihat pengguna, dan backend memvalidasi agar pengguna tidak bisa melakukan *check-in* untuk tanggal masa depan (`logDate > today` menurut timezone pengguna).
4. **Perubahan `activeDays` pada Habit yang Sudah Memiliki Histori:**
   - *Perilaku:* Mengubah `activeDays` tidak menghapus `HabitLog` masa lalu. Perhitungan *streak* berjalan mengevaluasi hari aktif terbaru, sementara log masa lalu yang sudah tercatat tetap dihitung sebagai selesai.
5. **Koneksi Internet Terputus Saat Membuka Aplikasi (Offline State):**
   - *Perilaku:* Karena MVP bersifat *online-first* dengan *local cache*, aplikasi menampilkan data Dashboard/Task/Habit terakhir dari *cache* lokal beserta *banner* indikator *"Mode Offline — Menampilkan data terakhir yang tersinkronisasi"*. Aksi mutasi (tambah/ubah/hapus) akan menampilkan *toast/snackbar* yang jelas bahwa koneksi internet diperlukan.
6. **Sesi Access Token Kedaluwarsa Saat Mengirim Form:**
   - *Perilaku:* Dio Interceptor di Flutter menangkap HTTP `401 Unauthorized`, secara transparan memanggil `POST /auth/refresh` satu kali (menggunakan *mutex/lock* agar request paralel tidak memicu *race condition*), lalu mengulangi request form awal tanpa menghilangkan input pengguna. Jika *refresh token* juga tidak valid, arahkan ke layar Login.

---

## 9. Success Metrics (Ukuran Keberhasilan MVP)

### Metrik Kesiapan Teknis (Release Gate)
1. **100% Acceptance Criteria MVP Lulus:** Seluruh 6 modul fitur berjalan *end-to-end* dari UI Flutter, REST API NestJS, hingga PostgreSQL tanpa *mock data*.
2. **Zero Cross-User Data Leakage:** 100% pengujian otorisasi memastikan Pengguna A mendapat HTTP `403`/`404` saat mencoba mengakses UUID resource milik Pengguna B.
3. **API Response Latency:** P95 waktu respons untuk `GET /dashboard/today` dan `GET /tasks` di bawah **200 ms** pada beban pengujian lokal/staging.

### Metrik Produk & Penggunaan (Pasca-Rilis Awal)
1. **Time-to-First-Task:** Pengguna baru dapat menyelesaikan registrasi dan membuat tugas pertamanya dalam waktu **< 60 detik**.
2. **Daily Check-in Completion Time:** Pengguna dapat membuka aplikasi, melihat ringkasan hari ini, dan mencentang 1 tugas + 1 habit dalam waktu **< 15 detik**.
3. **7-Day Habit Retention:** Minimal **60%** pengguna uji coba (mahasiswa) berhasil mencatat minimal 1 *habit log* per hari selama 5 dari 7 hari pertama.

---

## 10. Open Questions & Keputusan Arsitektur yang Ditetapkan

Untuk menghindari ambiguitas selama implementasi, berikut adalah keputusan tegas atas area yang sering menjadi pertanyaan terbuka:

| No | Pertanyaan / Area Ambigu | Keputusan Tegas untuk MVP LifeOS |
| :--- | :--- | :--- |
| 1 | Apakah tugas tanpa `dueAt` masuk ke kartu ringkasan Dashboard Harian? | **Ya, dihitung di `pending` dan ditampilkan pada seksi "Tugas Tanpa Tenggat / Backlog Aktif"** maksimal 5 item teratas berdasarkan prioritas, tetapi tidak pernah dihitung sebagai `overdue`. |
| 2 | Apakah pengguna boleh melakukan *check-in* habit untuk tanggal yang terlewat (*backfill*)? | **Boleh maksimal H-7 hari ke belakang**, tidak boleh untuk tanggal masa depan (`> today` di zona waktu user). |
| 3 | Bagaimana mekanisme pengiriman `refreshToken` antara NestJS dan Flutter Android? | Dikirim melalui **JSON response body** pada `/auth/register`, `/auth/login`, dan `/auth/refresh` (karena klien adalah aplikasi *mobile native* Android, bukan *browser* berbasis cookie), lalu disimpan di `Android Keystore` melalui `flutter_secure_storage`. |
| 4 | Bagaimana membedakan item `Task` dan `CalendarEvent` pada response `GET /calendar/events`? | Response API mengelompokkan atau memberi atribut diskriminator `type: "EVENT" \| "TASK"` pada daftar agenda sehingga UI kalender dapat merender kartu kegiatan (dengan jam mulai–selesai & lokasi) berbeda dari kartu tenggat tugas (dengan checkbox & badge prioritas). |
| 5 | Bagaimana pemetaan ID `Reminder` (UUID String di DB) ke `flutter_local_notifications` (yang meminta `int32` ID)? | Gunakan hash deterministik 31-bit positif dari UUID reminder (misal: `uuid.hashCode & 0x7FFFFFFF`) atau simpan tabel pemetaan lokal sederhana di SQLite/SharedPreferences agar pembatalan notifikasi selalu presisi. |
