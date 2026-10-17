# OneLinePlanner — Mobil plan (Flutter, iOS + Android)

> Versiya 1.0 · Oktyabr 2026
> Web və ödəniş tərəfi üçün bax: [texniki-plan.md](./texniki-plan.md), [biznes-plan.md](./biznes-plan.md)
> Qərar: mobil tətbiq **Flutter** ilə yazılır. Köhnə plandakı Capacitor variantı ləğv olunub.

## 1. Nə tikilir

Eyni hesab, eyni məlumat, eyni Pro. Flutter tətbiqi yeni backend deyil: hazır REST API-yə (`https://onelineplanner.com/api/v1`) qoşulan ikinci klientdir.

| | Web (hazırdır) | Mobil (bu plan) |
|---|---|---|
| Kod | Vue 3 | Flutter (bir kod bazası, iOS və Android) |
| Giriş | Email + şifrə, JWT 30 gün | Eyni. Token telefonda Keychain / Keystore-da |
| Məlumat | Postgres | Eyni server. Telefonda öz bazası yoxdur (v1) |
| Pro almaq | Paddle | Tətbiqin içində yalnız Apple / Google abunəsi |
| Artıq Pro-dursa | Paddle və ya promo | Eyni email ilə daxil olanda Pro avtomatik gəlir |

v1-in məqsədi mağazada işləyən tam gün planlayıcısıdır: gün xətti, taymer, layihələr, tapşırıqlar, qeydlər, bildirişlər və abunə. Widget, oflayn yazma və təqvim sinxronu v1-ə daxil deyil.

## 2. Niyə Flutter

| | Capacitor (köhnə təklif) | Flutter (seçilən) |
|---|---|---|
| İş | Vue ekranlarını native qabığa salır | Ekranlar yenidən yazılır |
| Müddət | ~6–8 həftə | ~10–12 həftə |
| Gün xətti, sürüşdürmə, taymer | Brauzer hissi | Native animasiya və jest |
| Widget, bildiriş, klaviatura | Plugin ilə, məhdud | Birbaşa |
| Apple 4.2 (nazik veb-qabıq) riski | Var, native əlavələr lazımdır | Yox |

Bir developer, bir Mac (iOS build üçün Mac artıq var). Android və iOS eyni vaxtda çıxır.

## 3. Arxitektura

```
Flutter tətbiqi
  │  HTTPS, Authorization: Bearer <jwt>
  ▼
onelineplanner.com/api/v1          mövcud Express backend
  │
  ├── auth, projects, tasks, plans, notes, settings, billing
  │
  └── subscriptions cədvəli  (artıq var: provider = paddle | app_store | play_store | promo)
        ▲                              ▲
        │ webhook                      │ webhook
   Paddle (web)                  RevenueCat
                                   ▲         ▲
                              App Store   Google Play
```

Pro qaydası dəyişmir. İstənilən canlı abunə (Paddle, App Store, Play, promo və ya admin) istifadəçini Pro edir. Web-də ödəyən adam telefonda yenidən ödəmir.

### Qovluq

Eyni repoda, `mobile/`:

```
mobile/
  pubspec.yaml
  lib/
    main.dart
    api/            dio klient, 401/402
    auth/           token, login, register, forgot
    l10n/           az, en, ru
    features/
      plan/         gün xətti, həftə, taymer
      projects/
      notes/
      settings/
      paywall/
  ios/              Xcode (flutter create yaradır)
  android/
```

## 4. Texnologiya

| İş | Paket |
|---|---|
| Vəziyyət | `flutter_riverpod` |
| HTTP | `dio` |
| Marşrut | `go_router` |
| Token | `flutter_secure_storage` |
| Dillər | `flutter gen-l10n` — az / en / ru (web-dəki mətnlərin qarşılığı) |
| Tema | Material 3, web-dəki tünd/açıq rənglər |
| Markdown qeydlər | `flutter_markdown` |
| Lokal bildiriş | `flutter_local_notifications` + `timezone` |
| Abunə | `purchases_flutter` (RevenueCat) |
| Tarix/saat | Cihazın saat qurşağı; planlar indi olduğu kimi dəqiqə ilə (`start_min` / `end_min`) |

Admin paneli mobilə köçmür.

## 5. Ekranlar (v1)

Web-də artıq olan axınların mobil qarşılığı:

1. **Giriş / qeydiyyat** — email, şifrə, "şifrəni unutdum". Təsdiq və bərpa linkləri hələlik saytı açır (`/verify-email`, `/reset-password`). Universal Link sonra.
2. **Gün planı** — əsas ekran. Saat xətti, plan kartları, sürüşdürərək vaxt dəyişmək, boş yerə toxunub plan yaratmaq, həftə zolağı, "bu gün".
3. **Cari iş** — aktiv plan, Başla / Pauza, qalan vaxt, effektivlik.
4. **Layihələr və tapşırıqlar** — siyahı, status, alt tapşırıqlar. Free planda 4-cü layihə 402 qaytarır və paywall açılır.
5. **Qeydlər** — Markdown.
6. **Ayarlar** — dil, tema, iş saatları, bildiriş dəqiqəsi, abunə.
7. **Paywall** — aylıq / illik. Qiyməti mağaza göstərir (hardcode `$4.99` yox).
8. **Tarixçə kilidi** — Free-də 14 gündən köhnə gün, web-dəki kimi, məlumat silinmir.

## 6. İstifadə olunan API

Hamısı hazırdır. Mobil üçün yeni CRUD lazım deyil.

| | |
|---|---|
| `POST /auth/register`, `/auth/login`, `/auth/forgot-password`, `/auth/reset-password`, `/auth/verify-email` | Giriş |
| `GET /auth/me` | `billing.plan`, `billing.source`, `email_verified` |
| `GET/POST/PUT/DELETE /projects`, `/tasks`, `/notes` | Məzmun |
| `GET /plans?from&to` | `X-History-Start` başlığı Free tarixçəsini kəsir |
| `POST /plans`, `PUT /plans/:id`, `POST /plans/:id/postpone` | Xəttə qoymaq və sürüşdürmək |
| `POST /plans/:id/tracking/start`, `.../pause` | Taymer |
| `GET/PUT /settings` | İş saatları, dil, saat qurşağı |
| 402 `plan.projectLimit` | Paywall |
| 401 | Tokeni sil, girişə qaytar |

JWT 30 gündür. v1 üçün refresh token yoxdur: müddət bitəndə yenidən giriş.

## 7. Abunə: mağaza qaydası

Bu hissə mağaza rəddinin ən çox yayılmış səbəbidir.

- iOS və Android tətbiqinin **içində** rəqəmsal Pro yalnız In-App Purchase ilə satılır. Paddle səhifəsinə və ya `onelineplanner.com/pricing` ünvanına düymə qoyulmur.
- Web-də Paddle ilə alan istifadəçi eyni email ilə telefonda Pro görür. Bunun üçün tətbiqdə ikinci ödəniş yoxdur.
- "İdarə et":
  - abunə App Store-dandırsa → Apple abunə səhifəsi;
  - Play-dəndirsə → Google Play abunə səhifəsi;
  - Paddle-dandırsa → qısa mətn: "Bu abunə saytda alınıb, Ayarlar orada idarə olunur." Tətbiqdən Paddle portalı açılmır.
- "Satınalmanı bərpa et" düyməsi məcburidir (RevenueCat `restorePurchases`).
- Mağaza qiymətləri ölkəyə görədir. Hədəf: aylıq ≈ $4.99, illik ≈ $39.99. Azərbaycan üçün mağazanın öz AZN pilləsi.

### Pulun axını (mağaza)

Müştəri Apple və ya Google-a ödəyir. Onlar komissiyanı (Small Business / abunə üçün təxminən 15%) saxlayır, qalanı developer hesabına köçürür. Bu pul Paddle balansına düşmür. Paddle yalnız saytdan gələn ödənişləri ödəyir.

RevenueCat mağazalarla danışır və webhook ilə backend-ə yazır. Kiçik gəlirdə (aylıq izlənilən gəlir təxminən $2 500-ə qədər) pulsuzdur.

## 8. Backend-ə əlavə (mobil başlamazdan əvvəl kiçik, mağazadan əvvəl vacib)

| İş | Niyə | Nə vaxt |
|---|---|---|
| `POST /billing/webhooks/revenuecat` | App Store / Play alışını `subscriptions` cədvəlinə yazır (`provider` = `app_store` və ya `play_store`). İmzası yoxlanır, eyni hadisə iki dəfə yazılmır — Paddle webhook-u ilə eyni model | Abunə mərhələsi |
| `DELETE /auth/me` — hesabı və məlumatı sil | Apple bunu tətbiqin içindən tələb edir | Mağazaya verməzdən əvvəl |
| App-specific password / Sign in with Apple | Apple, üçüncü tərəf girişi olanda tələb edir. v1-də yalnız email+şifrə olduğu üçün **lazım deyil** | Google/Apple login əlavə olunanda |

CORS mobilə təsir etmir: Flutter brauzer deyil.

## 9. Mərhələlər (1 developer)

| # | Mərhələ | Nəticə | Müddət |
|---|---|---|---|
| 0 | Hesablar | Apple Developer ($99/il), Google Play Console ($25, bir dəfə), RevenueCat | 1–2 gün + Apple təsdiqi bir neçə gün |
| 1 | Karkas | `mobile/`, giriş, token, boş tablar, az/en/ru, tema | 1 həftə |
| 2 | Gün xətti | Plan siyahısı, yaratmaq, sürüşdürmək, həftə, tarixçə kilidi | 2.5 həftə |
| 3 | Taymer | Başla/Pauza, cari iş kartı, effektivlik | 1 həftə |
| 4 | Layihə, tapşırıq, qeyd | Web-dəki əsas axın | 2 həftə |
| 5 | Bildiriş | Plan bitməzdən N dəqiqə əvvəl lokal bildiriş. Plan dəyişəndə növbəti 24 saat yenidən qurulur | 1 həftə |
| 6 | Abunə | RevenueCat, sandbox alış, bərpa, paywall, webhook | 1.5 həftə |
| 7 | Mağaza | İkon, splash, 3 dildə skrinşot və mətn, məxfilik forması, TestFlight, daxili test, review | 1.5–2 həftə |
| | **Cəmi** | İki mağazada v1 | **~10–12 həftə** |

TestFlight-da ilk yoxlanan build 1–4-cü mərhələdən sonra olur (~6–7 həftə), abunəsiz.

## 10. Mağaza siyahısı

- Ad: OneLinePlanner
- `applicationId` / bundle id: `com.onelineplanner.app`
- Yaş: 16+ (şərtlərdəki hədd)
- Məxfilik: hesab (email, ad), istifadəçinin yaratdığı məzmun, satınalma identifikatoru. Reklam və izləmə yoxdur.
- Mətn və skrinşotlar: az, en, ru
- Review qeydi: test hesabı (email + şifrə) və "Pro sandbox ilə yoxlanılır"
- Saytdakı Terms, Privacy, Refund linkləri mağaza siyahısında da olur

## 11. v1-dən sonra

Widget ("indiki plan və qalan vaxt"), push, oflayn oxumaq, Google/Apple ilə giriş, təqvim sinxronu, təkrarlanan planlar. Komanda planı web-dən sonra.

## 12. Başlamazdan əvvəl lazım olanlar

1. Apple Developer hesabı — developer.apple.com, illik $99.
2. Google Play Console — play.google.com/console, $25.
3. Mac-də Xcode və Android Studio (və ya yalnız Flutter SDK + Xcode).
4. Paddle review-in bitməsi mobilə mane olmur. Mağaza abunəsi Paddle-dan ayrıdır.
