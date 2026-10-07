# Planner

Proyekt/task idarəetməsi və günlük saat-saat planlama tətbiqi.

- **backend/** — Node.js (Express 5) + PostgreSQL, JWT ilə REST API (`/api/v1`). Web və gələcək mobil tətbiq eyni API-dən istifadə edir.
- **frontend/** — Vue 3 + Vite + Pinia.

## İşə salma (Docker)

```bash
cp .env.example .env   # JWT_SECRET-i uzun təsadüfi dəyərlə əvəz edin
docker compose up -d --build
```

| Servis | Ünvan |
|---|---|
| Frontend (nginx, `/api`-ni backend-ə proxy edir) | http://localhost:5173 |
| Backend API | http://localhost:4000/api/v1 |
| PostgreSQL | `localhost:5433` (planner / planner) |

Xaricdən yalnız frontend portu açıqdır, API də onun üzərindən `/api/v1` yolu ilə işləyir (mobil tətbiq üçün də). Backend və baza portları yalnız serverin özündən (127.0.0.1) əlçatandır.

Portlar başqa proqramla toqquşarsa, `.env`-də `FRONTEND_PORT`, `BACKEND_PORT`, `DB_PORT` dəyərlərini dəyişin.

Cədvəllər backend start olanda avtomatik yaradılır, məlumatlar `planner-data` volume-unda saxlanılır. Kod dəyişəndən sonra `docker compose up -d --build` ilə yenidən qurun. Loglar üçün: `docker compose logs -f backend`.

### Məlumatların serverə köçürülməsi

Serverdəki bazanın **bütün məlumatları silinir** və lokaldakı ilə əvəz olunur. Əməliyyat tək tranzaksiyada gedir, xəta olarsa heç nə dəyişmir.

```bash
# Bir əmrlə (SSH ilə): export → serverə köçür → import
./scripts/db-push-to-server.sh user@server /path/to/planner

# və ya əl ilə:
./scripts/db-export.sh dump.sql                      # lokalda
scp dump.sql user@server:/tmp/                       # serverə köçür
./scripts/db-import.sh /tmp/dump.sql                 # serverdə, layihə qovluğunda
```

### Docker-siz development (hot reload)

```bash
docker compose up -d db
docker compose stop backend frontend
cd backend && cp .env.example .env && npm install && npm run dev
cd frontend && npm install && npm run dev
```

## API

Bütün endpoint-lər (auth-dan başqa) `Authorization: Bearer <token>` tələb edir. Xəta cavabları `{ error, code }` formatındadır: `error` mətni `Accept-Language` başlığına görə `az`, `en` və ya `ru` dilində qaytarılır (default `az`), `code` isə dildən asılı olmayan sabit açardır (məs. `plan.overlap`). Vaxtlar gün başlanğıcından dəqiqə ilə ötürülür (`540` = 09:00, `1440` = 24:00), tarixlər `YYYY-MM-DD`.

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
