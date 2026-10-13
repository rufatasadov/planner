# OneLinePlanner — Texniki plan (ödənişli versiya: Web + iOS + Android)

> Versiya 1.0 · Oktyabr 2026 · Biznes tərəfi üçün bax: [biznes-plan.md](./biznes-plan.md)

## 1. Hazırkı vəziyyət

| Hissə | İndi | Ödənişli versiya üçün problem |
|---|---|---|
| Frontend | Vue 3 + Vite SPA, Pinia, öz i18n (az/en/ru), mobil responsiv | Mobil tətbiq yoxdur, PWA yoxdur |
| Backend | Express 5, REST `/api/v1`, `pg` | Rate limit, validasiya, abunə məntiqi yoxdur |
| Auth | E-poçt + şifrə, JWT (30 gün), `localStorage` | Refresh token, Google/Apple login, e-poçt təsdiqi, şifrə bərpası, hesab silmə yoxdur |
| DB | PostgreSQL 16, idempotent `schema.sql` | Versiyalı miqrasiya yoxdur; avtomatik backup yoxdur |
| Infra | Bir VPS, Docker Compose, Caddy (HTTPS) | Staging, CI/CD, monitorinq yoxdur |
| Testlər | Yoxdur | Ödəniş məntiqi testsiz riskli olur |

Müsbət tərəflər: `VITE_API_URL` artıq dəstəklənir (mobil tətbiq ayrıca domenə müraciət edə bilər), UI mobil üçün hazırdır, admin paneli var.

## 2. Arxitektura qərarları

### 2.1 Mobil: **Capacitor** (tövsiyə)

| Variant | Üstünlük | Çatışmazlıq | Qərar |
|---|---|---|---|
| **Capacitor** (mövcud Vue kodunu native qabığa salmaq) | Bir kod bazası, 4–6 həftə, bütün funksiyalar dərhal | Native hiss bir az zəif; Apple 4.2 riskinə görə native funksiyalar əlavə edilməlidir | ✅ **Seçilir** |
| React Native / Flutter (yenidən yazmaq) | Ən yaxşı native təcrübə | 3–4 ay, iki kod bazası | ✗ indi yox |
| Yalnız PWA | Ən ucuz | iOS-da mağaza yoxdur, bildirişlər məhduddur, IAP yoxdur | Web üçün əlavə olaraq ✅ |

Apple-ın rədd etməməsi üçün (Guideline 4.2 "minimum functionality") tətbiqə **native dəyər** qatılır: lokal bildirişlər (plan başlayır/bitir), haptics, widget (2-ci mərhələ), offline oxuma, Sign in with Apple.

### 2.2 Ödəniş: **RevenueCat** + mağaza IAP + web MoR

```
            ┌────────── iOS: StoreKit (IAP) ──────────┐
 İstifadəçi ├────────── Android: Play Billing ────────┼──► RevenueCat ──webhook──► Backend ──► subscriptions cədvəli
            └────────── Web: Paddle / Lemon Squeezy ──┘                              │
                                                                                     ▼
                                                              /auth/me → entitlements { pro: true, until }
```

- **Yeganə həqiqət mənbəyi backend-dir:** frontend yalnız `entitlements` sahəsinə baxır, limitlər serverdə yoxlanılır.
- RevenueCat istifadəçini `app_user_id = users.id` ilə tanıyır → bir platformada alınan Pro hər yerdə işləyir.
- Web ödənişi RevenueCat-ın Paddle/Stripe inteqrasiyası ilə və ya birbaşa Paddle webhook ilə (RevenueCat Paddle-ı dəstəkləmirsə ⚠ yoxla).
- Yerli AZN ödənişi (Payriff/Epoint) — 2-ci mərhələ, ayrıca webhook adapteri ilə eyni `subscriptions` cədvəlinə yazır.

### 2.3 Domenlər

| Domen | Məzmun |
|---|---|
| `onelineplanner.com` | Statik landing (SEO, qiymətlər, bloq, gizlilik siyasəti, şərtlər) |
| `app.onelineplanner.com` | Vue tətbiqi (indiki frontend) |
| `api.onelineplanner.com` | Backend (mobil tətbiq bura müraciət edir) |

## 3. Backend dəyişiklikləri

### 3.1 Yeni cədvəllər (miqrasiya)

```sql
CREATE TABLE subscriptions (
  id              BIGSERIAL PRIMARY KEY,
  user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider        TEXT NOT NULL,            -- 'app_store' | 'play_store' | 'paddle' | 'payriff' | 'promo'
  product_id      TEXT NOT NULL,            -- 'pro_monthly', 'pro_yearly'
  status          TEXT NOT NULL,            -- 'trialing' | 'active' | 'grace' | 'canceled' | 'expired'
  current_period_end TIMESTAMPTZ,
  will_renew      BOOLEAN NOT NULL DEFAULT true,
  external_id     TEXT NOT NULL,            -- original_transaction_id / subscription id
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (provider, external_id)
);

CREATE TABLE billing_events (               -- webhook jurnalı: idempotentlik və audit
  id          TEXT PRIMARY KEY,             -- provayderin event id-si
  provider    TEXT NOT NULL,
  payload     JSONB NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE users
  ADD COLUMN email_verified_at TIMESTAMPTZ,
  ADD COLUMN trial_ends_at     TIMESTAMPTZ,
  ADD COLUMN deleted_at        TIMESTAMPTZ;

CREATE TABLE refresh_tokens (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  TEXT NOT NULL UNIQUE,
  device      TEXT,
  expires_at  TIMESTAMPTZ NOT NULL,
  revoked_at  TIMESTAMPTZ
);

CREATE TABLE oauth_accounts (               -- Google / Apple login
  provider    TEXT NOT NULL,
  subject     TEXT NOT NULL,
  user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (provider, subject)
);
```

### 3.2 Entitlement və limitlər

- `services/entitlements.js`: `getPlan(userId)` → `'free' | 'pro'` (aktiv/trial/grace abunə və ya `trial_ends_at > now()`), qısa müddətli keş.
- `LIMITS = { free: { projects: 3, historyDays: 14, notesPerTask: 1 }, pro: { ... Infinity } }` — bir faylda.
- Middleware: `requirePro` (yalnız Pro endpointlər: export, şablonlar, kalendar sinxronu) və `assertLimit(userId, 'projects')` (yaradılarkən).
- Limitə çatanda **HTTP 402** + `{ code: 'plan.limit', limit: 'projects' }` → frontend paywall açır.
- `/auth/me` cavabına: `plan`, `trial_ends_at`, `limits`, `subscription { provider, period_end, will_renew }`.
- **Endirim (downgrade) zamanı məlumat silinmir** — yalnız yaratmaq/baxmaq məhdudlaşır.

### 3.3 Yeni endpointlər

| Endpoint | Təyinat |
|---|---|
| `POST /billing/webhooks/revenuecat` | RevenueCat hadisələri (Authorization header ilə yoxlanılır) |
| `POST /billing/webhooks/paddle` | Paddle hadisələri (imza yoxlaması) |
| `POST /billing/checkout` | Web üçün checkout sessiyası/linki |
| `GET  /billing/portal` | Abunəni idarə etmə linki (ləğv, kart dəyişmə) |
| `POST /auth/refresh`, `POST /auth/logout` | Refresh token rotasiyası |
| `POST /auth/google`, `POST /auth/apple` | ID token yoxlanışı → istifadəçi |
| `POST /auth/verify-email`, `POST /auth/forgot-password`, `POST /auth/reset-password` | E-poçt axınları |
| `DELETE /auth/account` | Hesabı silmə (Apple tələbi) — 30 günlük soft delete, sonra tam silmə |
| `GET  /export` | Bütün məlumatların JSON/CSV ixracı (GDPR) |

Webhook qaydaları: imzanı yoxla → `billing_events`-ə `INSERT ... ON CONFLICT DO NOTHING` (təkrar hadisəni at) → `subscriptions` upsert → 200 qaytar. Uğursuz olanda provayder təkrar göndərir.

### 3.4 Auth yenilənməsi

- **Access token 15 dəq** + **refresh token 60 gün** (rotasiya, DB-də hash).
  - Web: refresh token `httpOnly; Secure; SameSite=Lax` cookie-də.
  - Mobil: `@capacitor/preferences` əvəzinə **Keychain/Keystore** (`capacitor-secure-storage` plugin).
- Apple qaydası: Google login varsa **Sign in with Apple da olmalıdır**.
- E-poçt göndərmə: Resend və ya Postmark, 3 dildə şablonlar.

### 3.5 Təhlükəsizlik və keyfiyyət

- `helmet`, `express-rate-limit` (auth endpointlərinə xüsusilə), `CORS_ORIGIN` — `*` əvəzinə konkret domenlər + `capacitor://localhost`, `https://localhost`.
- Giriş validasiyası: `zod` sxemləri.
- Miqrasiyalar: `schema.sql` → **nömrələnmiş miqrasiyalar** (`node-pg-migrate`), mövcud sxem `0001_baseline` olur.
- Testlər: `vitest` + `supertest` — auth, limitlər, webhook idempotentliyi, abunə statusları (ən azı bunlar).
- Loqlar: strukturlu (`pino`), xətalar **Sentry**-yə.

## 4. Frontend (web) dəyişiklikləri

1. **Pricing səhifəsi** və **Paywall** komponenti (402 cavabında və Pro funksiyaya toxunanda açılır).
2. **Ayarlar → Abunə** bölməsi: plan, növbəti ödəniş tarixi, "İdarə et", "Satınalmanı bərpa et" (mobil).
3. Trial banneri ("Pro sınağı: 9 gün qaldı").
4. Pro funksiyalar: tarixçə > 14 gün, hesabatlar, export, təkrarlanan planlar, şablonlar.
5. Auth: Google/Apple düymələri, şifrə bərpası, e-poçt təsdiqi ekranları, hesabı silmə.
6. **PWA:** `vite-plugin-pwa` — manifest, ikonlar (logo hazırdır), offline shell.
7. Analitika: **PostHog** (funnel: qeydiyyat → aktivasiya → trial → ödəniş), cookie razılığı.
8. `api.js`: 401-də birbaşa `/login`-ə atmaq əvəzinə əvvəl `/auth/refresh` cəhdi.

## 5. Mobil tətbiq (Capacitor)

```
frontend/
  capacitor.config.ts      appId: com.onelineplanner.app
  ios/                     Xcode layihəsi (npx cap add ios)
  android/                 Android Studio layihəsi (npx cap add android)
```

| İş | Plugin / alət |
|---|---|
| API ünvanı | `VITE_API_URL=https://api.onelineplanner.com/api/v1` mobil build üçün |
| Safe area (notch, home indicator) | CSS `env(safe-area-inset-*)` — alt tab bar üçün vacib |
| Status bar, splash, ikonlar | `@capacitor/status-bar`, `@capacitor/splash-screen`, `@capacitor/assets` (logo.svg-dən) |
| Plan başlayır/bitir xəbərdarlığı | `@capacitor/local-notifications` — planlar dəyişəndə növbəti 24 saat üçün yenidən planlaşdırılır |
| Push (sonra) | `@capacitor/push-notifications` + FCM/APNs |
| Abunə | `@revenuecat/purchases-capacitor` — Paywall-da məhsullar, satınalma, bərpa |
| Google / Apple login | `@capacitor-firebase/authentication` və ya `@capgo/capacitor-social-login` |
| Deep link (şifrə bərpası) | Universal Links / App Links (`apple-app-site-association`, `assetlinks.json`) |
| Haptics, klaviatura | `@capacitor/haptics`, `@capacitor/keyboard` |
| Widget (2-ci mərhələ) | Native kod: iOS WidgetKit (Swift), Android Glance — "indiki plan + qalan vaxt" |

**Platforma qaydaları:**
- iOS/Android tətbiqində rəqəmsal abunə **yalnız IAP** ilə satılır; tətbiq daxilində web ödənişinə link vermək qaydaları ölkədən asılıdır ⚠ — ən təhlükəsizi: mobil tətbiqdə yalnız IAP.
- Mağaza abunəsinin ləğvi mağazada olur → "İdarə et" düyməsi mağazanın abunə səhifəsini açır.
- Mağaza qiymətləri hər ölkə üçün ayrıca təyin edilir (AZ üçün yerli qiymət).

**Build/Release:** Fastlane (iOS: TestFlight → App Store; Android: internal testing → production), GitHub Actions ilə avtomatlaşdırma (macOS runner iOS üçün).

## 6. İnfrastruktur və əməliyyatlar

| İş | Həll |
|---|---|
| **Backup** | Gündəlik `pg_dump` → Backblaze B2/S3 (şifrəli), 30 gün saxlanma, **ayda bir bərpa testi** |
| Staging | Eyni serverdə ayrıca compose layihəsi (`staging.onelineplanner.com`), ayrıca DB |
| CI/CD | GitHub Actions: lint + test → Docker image → serverə deploy (indiki `git pull && docker compose up -d --build` əvəzinə) |
| Monitorinq | Sentry (FE + BE), UptimeRobot (`/api/v1/health`), disk/RAM xəbərdarlığı |
| DB parol/sirlər | `docker-compose.yml`-dəki `planner:planner` parolunu `.env`-ə köçürmək, güclü parol |
| Miqyaslama | 10k istifadəçiyə qədər bir VPS kifayətdir; sonra idarə olunan Postgres (məs. Neon/Supabase/DO) |

## 7. Mərhələlər və təxmini iş həcmi (1 developer)

| # | Mərhələ | Tapşırıqlar | Müddət |
|---|---|---|---|
| 0 | **Təməl** ✅ (staging qalıb) | Miqrasiya sistemi, backup, Sentry, rate limit, CORS, testlər üçün karkas, CI, staging | 1.5 həftə |
| 1 | **Auth 2.0** | Refresh token, e-poçt təsdiqi, şifrə bərpası, Google + Apple login, hesab silmə, export | 1.5 həftə |
| 2 | **Abunə nüvəsi** | `subscriptions`, entitlements, limitlər (402), trial, admin paneldə MRR/abunəçilər | 1 həftə |
| 3 | **Web ödəniş** | Paddle/Lemon Squeezy checkout + webhook, Pricing, Paywall, Abunə ayarları, landing səhifə | 1.5 həftə |
| — | **Web Pro launch** ✅ | İlk gəlir | **~5.5 həftə** |
| 4 | **Capacitor** | iOS/Android layihələri, safe area, ikonlar, lokal bildirişlər, deep links | 2 həftə |
| 5 | **IAP** | RevenueCat, mağaza məhsulları, paywall (mobil), bərpa, sandbox testləri | 1.5 həftə |
| 6 | **Mağazaya çıxış** | Skrinşotlar, mətnlər (3 dil), privacy formaları, TestFlight beta, review | 1.5–2 həftə |
| — | **Mobil launch** ✅ | | **~11 həftə (≈ 3 ay)** |
| 7 | Böyümə | Widget, Google Calendar sinxronu, təkrarlanan planlar, push, offline yazma, Team planı | davamlı |

## 8. Launch öncəsi yoxlama siyahısı

- [ ] Backup bərpası test edilib
- [ ] Webhook-lar təkrar və sıra pozuntusu ilə test edilib (idempotent)
- [ ] Trial bitir → Free; ödəniş uğursuz → grace → expired axınları yoxlanılıb
- [ ] Downgrade zamanı məlumat itmir
- [ ] Hesab silmə tətbiqdən işləyir (Apple)
- [ ] Gizlilik siyasəti və şərtlər tətbiqdə və saytda linklənib
- [ ] Sandbox (Apple/Google/Paddle) satınalmaları uğurlu
- [ ] Sentry-də kritik xəta yoxdur, uptime monitor aktivdir
- [ ] Admin paneldə abunəçilər və MRR görünür
