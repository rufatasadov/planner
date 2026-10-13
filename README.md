# <img src="frontend/public/logo.svg" width="36" align="top" alt="" /> OneLinePlanner

Eyni anda yalnız bir işlə məşğul olmaqla taskları planlamaq üçün tətbiq: gün bir xəttdir və hər an onun üzərində tək bir iş olur. Proyekt/task idarəetməsi və günlük saat-saat planlama.

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

### Production: domen və HTTPS

Serverdə Caddy konteyneri 80/443 portlarını açır, Let's Encrypt sertifikatını avtomatik alıb yeniləyir və trafiki frontend-ə ötürür. Serverdəki `.env`-ə əlavə edin:

```bash
COMPOSE_PROFILES=prod
DOMAIN=onelineplanner.com
FRONTEND_HOST=127.0.0.1
```

Domenin A qeydi serverin IP-sinə yönəlməli, 80 və 443 portları firewall-da açıq olmalıdır. Sonra `docker compose up -d`; sertifikatın alınmasını `docker compose logs -f caddy` ilə izləyin.

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

### Backup

`backup` servisi işə düşəndə və sonra hər `BACKUP_INTERVAL_HOURS` (default 24) saatdan bir bazanın tam dump-ını `./backups` qovluğuna yazır, `BACKUP_KEEP_DAYS` (default 14) gündən köhnələri silir.

```bash
docker compose logs backup                                   # son backup-lar
./scripts/db-restore-test.sh                                 # ən son backup-ı müvəqqəti bazaya bərpa edib yoxlayır (canlı bazaya toxunmur)
./scripts/db-backup-pull.sh user@server /path/to/planner     # serverdəki backup-ları öz kompüterinə köçür (off-site kopya)
```

Tam bərpa (canlı bazanı əvəz edir): `docker exec -i planner-db pg_restore -U planner -d planner --clean --if-exists --no-owner < backups/planner-....dump`

### Miqrasiyalar

Sxem dəyişiklikləri `backend/src/migrations/NNNN_ad.sql` fayllarındadır və backend açılanda ardıcıl tətbiq olunur (tətbiq olunanlar `schema_migrations` cədvəlində saxlanılır). Yeni dəyişiklik üçün **növbəti nömrə ilə yeni fayl** yaradın — tətbiq olunmuş faylı dəyişməyin.

### Testlər

```bash
docker compose up -d db
cd backend && npm test        # planner_test bazasını hər dəfə sıfırdan yaradır
```

GitHub-a hər push-da `.github/workflows/ci.yml` backend testlərini və frontend build-i işlədir.

### Monitorinq

`.env`-də `SENTRY_DSN` (backend) və `VITE_SENTRY_DSN` (frontend, build zamanı) verilsə, xətalar [Sentry](https://sentry.io)-yə göndərilir. Boşdursa söndürülüdür.

### Email

Email təsdiqi və şifrə bərpası məktubları [Resend](https://resend.com) ilə göndərilir (`RESEND_API_KEY`, `MAIL_FROM`, linklər üçün `APP_URL`). Açar verilməyibsə məktublar sadəcə backend loguna yazılır: `docker logs planner-backend`.

### Ödənişlər (Paddle)

Pro abunəliyi [Paddle](https://paddle.com) ilə satılır. `.env`-də `PADDLE_ENV`, `PADDLE_API_KEY`, `PADDLE_CLIENT_TOKEN` yazın, sonra məhsul, qiymətlər və webhook-u yaradın — skript qalan dəyişənləri çap edir:

```bash
docker compose exec backend node src/paddle-setup.js --webhook-url https://DOMAIN/api/v1/billing/webhooks/paddle
```

Lokal test üçün webhook-a ictimai ünvan lazımdır: `cloudflared tunnel --url http://127.0.0.1:4000` (ünvan hər dəfə dəyişir, skripti yeni ünvanla yenidən işə salın). Sandbox test kartı: `4242 4242 4242 4242`, CVC `100`.

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
| GET / PUT | `/settings` | `{ work_start_min, work_end_min, notify_before_min, auto_stop, break_reminder_min, idle_pause_min, target_efficiency_pct, timezone }` |
| GET / POST | `/projects` | Siyahı / yarat `{ name, description?, color? }` |
| GET / PUT / DELETE | `/projects/:id` | |
| GET | `/tasks?project_id=&status=todo,in_progress&parent_id=` | Filtrli siyahı (`parent_id=null` — yalnız əsas tasklar) |
| POST | `/tasks` | `{ project_id, title, description?, status?, parent_id? }` — alt task üçün `project_id` vacib deyil |
| PUT | `/tasks/:id` | `{ title?, description?, status?, parent_id? }` — `parent_id: null` taskı müstəqil edir |
| PUT | `/tasks/reorder` | `{ ids: [...] }` — eyni səviyyəli taskların yeni sırası |
| DELETE | `/tasks/:id` | Alt tasklar da silinir |
| PATCH | `/tasks/:id/status` | `{ status }` — `todo`, `in_progress`, `done`, `cancelled` |

Alt tasklar bir səviyyəlidir: ana task eyni proyektin əsas taskı olmalıdır. Hər taskda `parent_id`, `parent_title`,
`position`, `subtask_count`, `subtask_done` sahələri var. Bütün alt tasklar bitəndə (`done`/`cancelled`, ən azı biri `done`)
ana task avtomatik `done` olur; alt task yenidən açılanda ana task `in_progress`-ə qayıdır. Status, yaratma, köçürmə və silmə
cavablarında `parent: { id, title, status, changed }` qaytarılır.
| GET | `/plans?date=` və ya `/plans?from=&to=` | Planlar (proyekt və tasklarla birgə) |
| GET | `/plans/current?date=&minute=` | Cari/növbəti plan, qalan dəqiqə, bildiriş ayarı |
| POST | `/plans` | `{ date, project_id, start_min, end_min, note? }` — proyektin açıq taskları avtomatik əlavə olunur |
| PUT | `/plans/:id` | `{ start_min?, end_min?, project_id?, note?, shift_mode }` |
| POST | `/plans/:id/postpone` | `{ date, start_min?, end_min? }` |
| POST | `/plans/:id/sync-tasks` | Proyektə sonradan əlavə olunmuş açıq taskları plana qoşur |
| POST | `/plans/generate` | `{ source_date, target_dates[], mode: 'skip' \| 'replace' }` |
| DELETE | `/plans/:id` | |
| POST | `/plans/:id/tracking/start` | Taymeri başladır / davam etdirir (başqa planın işləyən taymeri dayandırılır) |
| POST | `/plans/:id/tracking/pause` | `{ reason?: 'pause' \| 'idle', at?: ISO }` — fasilə |

| GET | `/notes?task_id=&project_id=&plan_id=&from=&to=&q=&limit=&offset=` | İş qeydləri (yenidən köhnəyə), task/proyekt/plan məlumatı ilə |
| POST | `/notes` | `{ task_id, body, plan_id? }` — `body` Markdown mətndir |
| PUT | `/notes/:id` | `{ body?, plan_id? }` |
| DELETE | `/notes/:id` | |
| GET | `/admin/stats?days=7\|30\|90\|365` | Yalnız admin: ümumi göstəricilər, günlük dinamika və hər istifadəçi üzrə statistika. Admin emailləri `ADMIN_EMAILS` env dəyişənindədir (standart: `allforaze@gmail.com`) |

Tasklarda (`/tasks`, `/plans` cavablarında) `note_count` sahəsi qeydlərin sayını göstərir.

Hər plan obyektində `tracking` sahəsi var:
`{ state: 'not_started' | 'running' | 'paused' | 'stopped', effective_sec, break_sec, current_break_sec, sessions[] }`.
Effektivlik = `effective_sec` ÷ planın keçmiş vaxtı. `auto_stop` aktivdirsə, taymer plan bitəndə avtomatik dayanır.

`shift_mode`:
- `none` — yalnız bu plan dəyişir (kəsişmə olarsa `409`);
- `next` — növbəti planın başlanğıcı bu planın yeni bitmə vaxtına çəkilir;
- `all` — bütün sonrakı planlar eyni dəqiqə qədər sürüşdürülür.

## Müəllif

**Rufat Asadov** — [rufatasadov24@gmail.com](mailto:rufatasadov24@gmail.com)
