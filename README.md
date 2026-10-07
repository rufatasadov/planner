# Planner

Proyekt/task idarəetməsi və günlük saat-saat planlama tətbiqi.

- **backend/** — Node.js (Express 5) + PostgreSQL, JWT ilə REST API (`/api/v1`). Web və gələcək mobil tətbiq eyni API-dən istifadə edir.
- **frontend/** — Vue 3 + Vite + Pinia.

## İşə salma

```bash
# 1. PostgreSQL (localhost:5433)
docker compose up -d

# 2. Backend (http://localhost:3000/api/v1) — cədvəllər start zamanı avtomatik yaradılır
cd backend
cp .env.example .env   # JWT_SECRET-i dəyişin
npm install
npm run dev

# 3. Frontend (http://localhost:5173)
cd ../frontend
npm install
npm run dev
```

## API

Bütün endpoint-lər (auth-dan başqa) `Authorization: Bearer <token>` tələb edir. Vaxtlar gün başlanğıcından dəqiqə ilə ötürülür (`540` = 09:00, `1440` = 24:00), tarixlər `YYYY-MM-DD`.

| Metod | Yol | Təsvir |
|---|---|---|
| POST | `/auth/register` | `{ name, email, password }` → `{ token, user }` |
| POST | `/auth/login` | `{ email, password }` → `{ token, user }` |
| GET | `/auth/me` | Cari istifadəçi |
| GET / PUT | `/settings` | `{ work_start_min, work_end_min, notify_before_min }` |
| GET / POST | `/projects` | Siyahı / yarat `{ name, description?, color? }` |
| GET / PUT / DELETE | `/projects/:id` | |
| GET | `/tasks?project_id=&status=todo,in_progress` | Filtrli siyahı |
| POST | `/tasks` | `{ project_id, title, description?, status? }` |
| PUT / DELETE | `/tasks/:id` | |
| PATCH | `/tasks/:id/status` | `{ status }` — `todo`, `in_progress`, `done`, `cancelled` |
| GET | `/plans?date=` və ya `/plans?from=&to=` | Planlar (proyekt və tasklarla birgə) |
| GET | `/plans/current?date=&minute=` | Cari/növbəti plan, qalan dəqiqə, bildiriş ayarı |
| POST | `/plans` | `{ date, project_id, start_min, end_min, note? }` — proyektin açıq taskları avtomatik əlavə olunur |
| PUT | `/plans/:id` | `{ start_min?, end_min?, project_id?, note?, shift_mode }` |
| POST | `/plans/:id/postpone` | `{ date, start_min?, end_min? }` |
| POST | `/plans/:id/sync-tasks` | Proyektə sonradan əlavə olunmuş açıq taskları plana qoşur |
| POST | `/plans/generate` | `{ source_date, target_dates[], mode: 'skip' \| 'replace' }` |
| DELETE | `/plans/:id` | |

`shift_mode`:
- `none` — yalnız bu plan dəyişir (kəsişmə olarsa `409`);
- `next` — növbəti planın başlanğıcı bu planın yeni bitmə vaxtına çəkilir;
- `all` — bütün sonrakı planlar eyni dəqiqə qədər sürüşdürülür.
# planner
