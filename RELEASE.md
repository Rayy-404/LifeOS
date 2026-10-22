# LifeOS — Release Runbook (Milestone R)

Dokumen ini adalah panduan operasional untuk membangun, menandatangani, dan men-deploy LifeOS di luar lingkungan development. Status verifikasi terakhir: **22 Oktober 2026**.

---

## 1. Artefak yang Sudah Diverifikasi

| Artefak | Lokasi | Status |
| :--- | :--- | :--- |
| APK release (smoke test emulator) | `mobile/dist/lifeos-1.0.0-smoke-20261022-093252.apk` | ✅ Dibangun & ditandatangani |
| Docker image backend | `lifeos-backend:1.0.0` | ✅ Dibangun & diuji |
| Stack produksi | `docker-compose.prod.yml` + PostgreSQL 17 | ✅ Health, migrasi, register/login/tasks |
| CI workflow | `.github/workflows/ci.yml` | ✅ Diperbaiki (belum berjalan tanpa remote) |

Detail APK smoke:

- Ukuran: **61,3 MB** (universal APK, arm64-v8a + armeabi-v7a + x86_64)
- SHA-256: `775136E8A1FEBC1A85079A36F40451A50800FB0DA031B0AB13E31A514B29FC80`
- Sertifikat: `CN=LifeOS Release, OU=Mobile, O=LifeOS, L=Jakarta, ST=DKI Jakarta, C=ID`
- Certificate SHA-256: `06d94cfab7659ed9c6e69301068ea535092a5175fee5b091711834ad74c9ee21`
- Signature scheme: **v2 + v3** (v1 dimatikan karena `minSdk 26`)

> ⚠️ APK smoke di atas memakai `API_BASE_URL=http://10.0.2.2:3000/api/v1` dan **hanya untuk emulator**. APK untuk distribusi wajib dibangun ulang dengan URL HTTPS produksi.

---

## 2. Android Release

### 2.1 Signing key

Keystore release lokal sudah dibuat dan **tidak masuk Git**:

| File | Fungsi |
| :--- | :--- |
| `mobile/android/app/lifeos-release.jks` | Keystore RSA 4096-bit, PKCS#12, valid 10.000 hari |
| `mobile/android/key.properties` | Password, alias, dan path keystore |

Keduanya di-ignore oleh `.gitignore` dan `mobile/android/.gitignore`. **Backup keduanya sekarang.** Jika keystore atau password hilang, aplikasi tidak bisa di-update di Play Store dengan package ID yang sama.

Format `mobile/android/key.properties`:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=lifeos
storeFile=lifeos-release.jks
```

Membuat keystore baru (jalankan dari `mobile/android`, ganti nilai placeholder):

```powershell
keytool -genkeypair -v `
  -keystore app/lifeos-release.jks `
  -storetype PKCS12 -keyalg RSA -keysize 4096 -validity 10000 `
  -alias lifeos `
  -storepass "<STORE_PASSWORD>" -keypass "<KEY_PASSWORD>" `
  -dname "CN=LifeOS Release, OU=Mobile, O=LifeOS, L=Jakarta, ST=DKI Jakarta, C=ID"
```

> Untuk Play Store, gunakan **upload key** terpisah bila ingin mendukung key rotation. Simpan backup di password manager / secret manager, bukan di repo.

### 2.2 Build APK/AAB

Script utama: `mobile/build-release.ps1`.

```powershell
cd mobile

# Build distribusi (wajib HTTPS)
powershell -ExecutionPolicy Bypass -File .\build-release.ps1 `
  -ApiBaseUrl "https://api.lifeos.id/api/v1"

# Android App Bundle untuk Play Store
powershell -ExecutionPolicy Bypass -File .\build-release.ps1 `
  -ApiBaseUrl "https://api.lifeos.id/api/v1" -AppBundle

# APK per ABI (lebih kecil)
powershell -ExecutionPolicy Bypass -File .\build-release.ps1 `
  -ApiBaseUrl "https://api.lifeos.id/api/v1" -SplitPerAbi

# Smoke test emulator (cleartext 10.0.2.2 diizinkan)
powershell -ExecutionPolicy Bypass -File .\build-release.ps1 -SmokeTest
```

Script akan:

1. Menolak URL non-HTTPS kecuali mode `-SmokeTest` untuk host lokal.
2. Memastikan `android/key.properties` tersedia (kecuali `-AllowDebugSigning`).
3. Menjalankan `flutter build` dengan `--dart-define=API_BASE_URL=...`.
4. Menyalin hasil ke `mobile/dist/` dengan nama berversi + timestamp.
5. Mencetak SHA-256 artefak.

Build manual tanpa script:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://api.lifeos.id/api/v1
```

### 2.3 Verifikasi artefak

```powershell
$apk = Get-ChildItem mobile/dist/*.apk | Select-Object -First 1
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0\apksigner.bat" `
  verify --verbose --print-certs $apk.FullName

& "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0\aapt2.exe" `
  dump badging $apk.FullName
```

Yang harus terlihat:

- `Verifies`
- `Verified using v2 scheme: true`
- `Verified using v3 scheme: true`
- `package: name='com.lifeos.lifeos_mobile' versionCode='1' versionName='1.0.0'`
- `minSdkVersion:'26'`, `targetSdkVersion:'36'`

### 2.4 Install smoke test

```powershell
adb install -r mobile/dist/lifeos-1.0.0-smoke-*.apk
adb shell am start -n com.lifeos.lifeos_mobile/.MainActivity
```

Prasyarat: emulator Android berjalan dan backend development aktif di `localhost:3000` (emulator menjangkau host lewat `10.0.2.2`).

Untuk device fisik, gunakan URL HTTPS (mis. tunnel/reverse proxy). `network_security_config.xml` menolak cleartext selain `localhost`, `127.0.0.1`, dan `10.0.2.2`.

### 2.5 Versioning

- Versi aplikasi: `version: 1.0.0+1` di `mobile/pubspec.yaml`.
- Naikkan `versionCode` (`+1`) untuk setiap upload Play Store.
- Tag rilis: `git tag v1.0.0 && git push origin v1.0.0`.

---

## 3. Backend Produksi (Docker)

### 3.1 Siapkan environment

```powershell
Copy-Item backend/.env.production.example backend/.env.production
```

Isi minimal:

| Variabel | Catatan |
| :--- | :--- |
| `POSTGRES_PASSWORD` | Password DB; gunakan alfanumerik agar aman di URL |
| `DATABASE_URL` | Host `postgres`; password harus sama dengan `POSTGRES_PASSWORD` |
| `JWT_ACCESS_SECRET` | Random 48 byte (96 hex char) |
| `CORS_ORIGIN` | Origin web/admin; native Android tidak mengirim Origin |
| `SWAGGER_ENABLED` | `false` di production |
| `TRUST_PROXY` | `1` bila di belakang reverse proxy |

Generate JWT secret di PowerShell:

```powershell
$bytes = New-Object byte[] 48
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
-join ($bytes | ForEach-Object { $_.ToString('x2') })
```

`backend/.env.production` sudah di-ignore Git. Jangan pernah commit.

### 3.2 Jalankan stack

```powershell
docker compose -f docker-compose.prod.yml up -d --build
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f backend
```

Yang terjadi saat start:

1. PostgreSQL 17 start dan lolos health check.
2. Container backend menjalankan `prisma migrate deploy` (retry maksimal 10x).
3. API start sebagai user non-root `node` di port 3000.
4. Port host default `127.0.0.1:3000` (ubah dengan `BACKEND_PORT`).

Health check:

```powershell
Invoke-RestMethod http://localhost:3000/api/v1/health
```

### 3.3 Reverse proxy & TLS

Backend sengaja bind ke loopback. Taruh Caddy/nginx/Traefik di depan port 3000 dan terminasi TLS di sana. Contoh Caddy:

```caddyfile
api.lifeos.id {
    reverse_proxy 127.0.0.1:3000
}
```

Pastikan `TRUST_PROXY=1` agar rate limit memakai IP klien asli, dan `CORS_ORIGIN` diisi origin yang benar.

### 3.4 Operasional

```powershell
# Log
docker compose -f docker-compose.prod.yml logs -f backend

# Backup database
docker compose -f docker-compose.prod.yml exec -T postgres `
  pg_dump -U lifeos -d lifeos -Fc > lifeos-$(Get-Date -Format yyyyMMdd-HHmm).dump

# Update aplikasi
git pull
docker compose -f docker-compose.prod.yml up -d --build

# Stop (data tetap)
docker compose -f docker-compose.prod.yml down

# Stop + hapus data (HATI-HATI)
docker compose -f docker-compose.prod.yml down -v
```

Migrasi Prisma bersifat **forward-only**. Backup database sebelum deploy versi baru; rollback aplikasi tidak otomatis me-rollback schema.

### 3.5 Verifikasi yang sudah dilakukan

- Image multi-stage berhasil dibangun (`node:24-bookworm-slim`, non-root).
- Stack produksi terisolasi berhasil start dengan PostgreSQL 17.
- `prisma migrate deploy` berjalan otomatis di entrypoint.
- `GET /api/v1/health` → `ok`.
- Register → login token → `GET /api/v1/tasks` berhasil.
- `GET /api/docs` → **404** saat `NODE_ENV=production`.
- Container berjalan sebagai `uid=1000(node)`.

---

## 4. CI

`.github/workflows/ci.yml` sudah diperbaiki:

- `JWT_SECRET` → **`JWT_ACCESS_SECRET`** (nama yang benar-benar dibaca `auth.config.ts`).
- `CORS_ORIGIN` ditambahkan.
- Flutter dipin ke **3.47.7** (Dart 3.13.5) agar sesuai `pubspec.yaml`; sebelumnya 3.35.0 tidak memenuhi constraint SDK.

Repo **belum memiliki git remote**, jadi workflow belum pernah berjalan di GitHub. Setelah remote ditambahkan:

```powershell
git remote add origin https://github.com/<owner>/<repo>.git
git push -u origin main
```

Release APK/AAB saat ini dibangun manual. Bila ingin otomatis di CI, tambahkan secrets keystore dan workflow terpisah; jangan simpan keystore di repo.

---

## 5. Checklist Rilis

### Sudah

- [x] Release signing key + `key.properties` (lokal, ignored)
- [x] APK release universal dibangun dan diverifikasi v2/v3
- [x] Dockerfile multi-stage + entrypoint migrasi
- [x] `docker-compose.prod.yml` + PostgreSQL 17
- [x] Smoke test container: health, register, login, tasks, Swagger 404, non-root
- [x] CI env & versi Flutter diperbaiki
- [x] Runbook rilis

### Sebelum distribusi

- [ ] Ganti URL API ke domain HTTPS produksi dan build ulang APK/AAB
- [ ] Deploy backend + reverse proxy TLS
- [ ] Ganti seluruh secret contoh (`JWT_ACCESS_SECRET`, DB password)
- [ ] Backup keystore + `key.properties` di tempat aman
- [ ] Uji di perangkat fisik: login, CRUD task, check-in habit, notifikasi saat app ditutup, reboot reschedule
- [ ] Naikkan `versionCode` dan buat tag `v1.0.0`
- [ ] (Opsional) Publikasi AAB ke Play Store internal testing
- [ ] (Opsional) Tambahkan remote Git + aktifkan CI

---

## 6. Keterbatasan Verifikasi

Item berikut tetap memerlukan perangkat/emulator nyata dan belum bisa dibuktikan hanya dengan build:

1. Notifikasi lokal muncul saat aplikasi ditutup.
2. Reschedule alarm setelah reboot.
3. Penolakan izin `POST_NOTIFICATIONS` → status `FAILED` + banner panduan.
4. Perilaku OEM battery saver/doze.
5. Koneksi device fisik melalui IP LAN (butuh HTTPS atau penyesuaian network security config).

Lihat juga `README.md` §6 dan `mobile/integration_test/app_journey_test.dart`.
