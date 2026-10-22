# LifeOS — Personal Productivity & Academic OS

Monorepo **LifeOS**: aplikasi Android untuk mengelola **tugas**, **jadwal kegiatan**, **kebiasaan**, **pengingat (local notification)**, dan **statistik** dalam satu dashboard yang dihitung langsung dari database.

- `backend/` — REST API `/api/v1` (NestJS 11 · Prisma 6 · PostgreSQL 17)
- `mobile/` — Klien Android (Flutter · Material 3 · Riverpod · GoRouter · Dio · flutter_local_notifications)
- `planning/` — Dokumen produk & teknik (PRD, design brief, kontrak API, keamanan & pengujian, playbooks)
- `design/` — Referensi visual (screenshot & export desain)
- `RELEASE.md` — Runbook signing APK, build produksi, dan deploy Docker (Milestone R)

---

## 1. Prasyarat

| Tool | Versi |
| :--- | :--- |
| Node.js | 24 LTS |
| npm | 10+ |
| Flutter | 3.47.7 (stable, Dart 3.13.5) |
| Docker Desktop | PostgreSQL 17 |

---

## 2. Menjalankan Monorepo

### 2.1 Database (PostgreSQL 17 via Docker)

```bash
docker compose up -d          # container: lifeos_postgres, port 5432
docker compose ps             # pastikan status "healthy"
```

Kredensial default (development): `lifeos` / `dev-only-password`, database `lifeos`.

### 2.2 Backend (NestJS + Prisma)

```bash
cd backend
cp .env.example .env          # isi JWT_ACCESS_SECRET dengan random string panjang
npx prisma migrate deploy     # atau: npx prisma migrate dev
npm install
npm run start:dev             # http://localhost:3000
```

- Health check: `http://localhost:3000/api/v1/health`
- Swagger/OpenAPI: `http://localhost:3000/api/docs` (hanya di luar `NODE_ENV=production`, atau saat `SWAGGER_ENABLED=true`)
- Build produksi: `npm run build && npm run start:prod`

> **Catatan `prisma migrate reset`**: hentikan proses `node dist/main.js` yang sedang berjalan lebih dulu, karena Prisma Client terkunci oleh proses server. Alternatifnya jalankan `npx prisma migrate reset --force --skip-generate`.

#### Variabel lingkungan (`backend/.env`)

| Variabel | Default | Keterangan |
| :--- | :--- | :--- |
| `DATABASE_URL` | `postgresql://lifeos:dev-only-password@localhost:5432/lifeos?schema=public` | Koneksi PostgreSQL |
| `PORT` | `3000` | Port HTTP API |
| `JWT_ACCESS_SECRET` | — | **Wajib** di luar `NODE_ENV=test` (fail-fast) |
| `JWT_ACCESS_TTL` | `15m` | Masa berlaku access token |
| `REFRESH_TOKEN_TTL_DAYS` | `30` | Masa berlaku refresh token (disimpan sebagai sha256) |
| `CORS_ORIGIN` | `http://localhost:3000,http://localhost:8080` | Daftar origin yang diizinkan; **wajib** di production |
| `SWAGGER_ENABLED` | (auto) | Aktifkan/_matikan `/api/docs` |
| `TRUST_PROXY` | — | Nilai proxy tepercaya bila API di belakang reverse proxy |
| `THROTTLE_LIMIT` / `THROTTLE_TTL_MS` | `60` / `60000` | Rate limit global per IP |
| `AUTH_THROTTLE_LIMIT` / `AUTH_THROTTLE_TTL_MS` | `10` / `60000` | Rate limit endpoint auth |

### 2.3 Mobile (Flutter Android)

```bash
cd mobile
flutter pub get
flutter run
```

Base URL API ditentukan oleh `--dart-define=API_BASE_URL=...` (default `http://localhost:3000/api/v1`).

| Skenario | Cara |
| :--- | :--- |
| **Android Emulator** | `--dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1` (host loopback dari emulator) |
| **Emulator/device via `adb reverse`** | `adb reverse tcp:3000 tcp:3000` lalu jalankan tanpa override (default `localhost:3000`) |
| **Device fisik via IP LAN** | `--dart-define=API_BASE_URL=http://<IP-LAP-KOMPUTER>:3000/api/v1` **dan** tambahkan IP tersebut ke `mobile/android/app/src/main/res/xml/network_security_config.xml` (cleartext hanya diizinkan untuk `localhost`, `127.0.0.1`, `10.0.2.2`) |

Backend harus listen di semua interface untuk device fisik: `HOST=0.0.0.0` (default NestJS) dan port 3000 harus terbuka di firewall lokal.

---

## 3. Pengujian & Verifikasi

```bash
# Backend — unit test
cd backend && npm test -- --runInBand

# Backend — E2E (butuh PostgreSQL aktif)
npm run test:e2e            # suite modul + journey A–F
npm run test:e2e:ui         # mode watch + verbose (lokal)
npm run test:e2e:ci         # retry 2x, untuk CI

# Backend — gate latensi (P95 < 200 ms untuk /dashboard/today & /tasks)
node ./scripts/latency-check.js http://localhost:3000/api/v1 100

# Mobile — analyze + unit/widget test
cd mobile && flutter analyze && flutter test

# Mobile — integration journey (butuh emulator + backend lokal)
adb reverse tcp:3000 tcp:3000
flutter test integration_test -d emulator-5554
```

**Journey E2E (A–F)** berada di `backend/test/journeys/`:
A Auth & Session · B Task Lifecycle · C Habit & Check-in · D Calendar & Agenda · E Reminder Lifecycle · F Dashboard, Statistics & Isolation.
Fixture pendukung: `backend/test/support/` (auth helper, seeding, cleanup per prefix e-mail, assertion dengan pesan error jelas).

---

## 4. CI (GitHub Actions)

`.github/workflows/ci.yml` menjalankan 3 job pada setiap PR:

1. **Backend** — PostgreSQL 17 service container → `prisma migrate deploy` → build → unit test → `test:e2e:ci`.
2. **Mobile** — `flutter analyze` + `flutter test`.
3. **Mobile integration** — emulator Android (API 33) dengan backend yang dijalankan di runner + `adb reverse` + `flutter test integration_test`.

Workflow memakai `JWT_ACCESS_SECRET` (bukan `JWT_SECRET`) dan Flutter **3.47.7** agar cocok dengan constraint Dart 3.13.5.

> Repo ini belum memiliki git remote; file workflow sudah siap tetapi baru berjalan setelah repository terhubung ke GitHub.

---

## 5. Catatan Keamanan (audit pra-rilis Fase 7)

- Argon2id untuk password, refresh token acak 64 byte **disimpan sebagai sha256**, rotasi atomik + *reuse detection* (mencabut seluruh sesi).
- Access token hanya memuat `sub`; email & timezone dibaca dari database per request (tidak ada PII di payload JWT, akun terhapus langsung kehilangan akses).
- `POST /auth/logout` **wajib** membawa access token; endpoint publik hanya `/auth/register`, `/auth/login`, `/auth/refresh`, `/health`.
- CORS memakai allowlist eksplisit (wajib `CORS_ORIGIN` di production); Swagger non-production; seluruh query ter-scope `userId` dan lintas-tenant selalu `404`.
- Rate limit per IP: global 60/menit, endpoint auth 10/menit (`429 RATE_LIMIT_EXCEEDED`).
- Android: `allowBackup="false"`, cleartext dibatasi, receiver notifikasi `exported="false"`.
- Cache baca offline (dashboard/tasks/habits/reminders/statistics) disimpan **terenkripsi** di Android Keystore (`flutter_secure_storage`), bukan `SharedPreferences` biasa.

---

## 6. Keterbatasan Verifikasi Manual

Skenario berikut **tidak** bisa dibuktikan andal tanpa perangkat/emulator nyata dan ditandai demikian pada checklist rilis:

1. **Notifikasi lokal** benar-benar muncul saat aplikasi ditutup.
2. **Reschedule setelah reboot** perangkat (Android me-restart alarm; aplikasi juga merekonsiliasi saat startup/resume).
3. **Penolakan izin `POST_NOTIFICATIONS`** → status reminder `FAILED` + banner panduan ke Pengaturan Android.
4. **Perilaku OEM battery saver / doze** terhadap alarm lokal (bervariasi per vendor).
5. **Perangkat fisik via IP LAN** (butuh penyesuaian `network_security_config.xml`).

Item 1–3 dapat dijalankan di emulator melalui `mobile/integration_test/app_journey_test.dart`.

---

## 7. Release (Milestone R)

Panduan lengkap ada di [`RELEASE.md`](RELEASE.md). Ringkasan:

```powershell
# APK distribusi (wajib URL HTTPS)
cd mobile
powershell -ExecutionPolicy Bypass -File .\build-release.ps1 `
  -ApiBaseUrl "https://api.lifeos.id/api/v1"

# Backend produksi
Copy-Item backend/.env.production.example backend/.env.production
# isi secret, lalu:
docker compose -f docker-compose.prod.yml up -d --build
```

Status saat ini:

- ✅ Release signing (keystore lokal, ignored), APK smoke v2+v3, Dockerfile multi-stage, `docker-compose.prod.yml`, entrypoint migrasi, CI env/versi Flutter.
- ✅ Sudah diverifikasi: image Docker menyala, health check, register/login/tasks, Swagger 404 di production, container non-root.
- ⬜ Belum: build ulang dengan domain HTTPS produksi, deploy server + TLS, backup keystore, uji notifikasi di perangkat fisik.
