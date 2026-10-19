# LifeOS — Personal Productivity & Academic OS

Monorepo untuk **LifeOS** (Aplikasi Produktivitas Pribadi & Akademik untuk Android).

## Struktur Monorepo

- [`planning/`](file:///C:/Users/Rey/Documents/Projects/lifeOS/planning/README.md) — Dokumentasi PRD, Design Brief, Spesifikasi Teknis, Keamanan & Pengujian, serta Engineering Playbooks.
- [`DESIGN.md`](file:///C:/Users/Rey/Documents/Projects/lifeOS/DESIGN.md) — Spesifikasi Sistem Desain UI/UX (Material 3, palet warna, tipografi, dan komponen layar).
- `backend/` — REST API Server (`/api/v1`) menggunakan **NestJS**, **Prisma 6**, dan **PostgreSQL 17**.
- `mobile/` — Aplikasi Klien Android menggunakan **Flutter** (Material 3, Riverpod, GoRouter, Dio, Local Notifications).

## Menjalankan Lingkungan Development

### 1. Database (PostgreSQL 17 via Docker)
```bash
docker compose up -d
```

### 2. Backend (NestJS + Prisma 6)
```bash
cd backend
cp .env.example .env
npx prisma migrate dev
npm run start:dev
```
Dokumentasi Swagger OpenAPI tersedia di `http://localhost:3000/api/docs`.

### 3. Mobile (Flutter Android)
```bash
cd mobile
flutter pub get
flutter run
```
*(Catatan: Pada Android Emulator, API diarahkan secara default ke `http://10.0.2.2:3000/api/v1`).*
