# OneLinePlanner mobil (Flutter)

iOS və Android. Eyni hesab və eyni API: `https://onelineplanner.com/api/v1`.

```bash
cd mobile
flutter run
```

iOS 26 fiziki cihazda debug rejimi işləmir (Flutter 3.29). Həmin telefonda:

```bash
flutter run --release -d 00008150-00185D9E0E90C01C
```

Debug və hot reload üçün simulyator istifadə edin.

Lokal backend:

```bash
flutter run --dart-define=API_URL=http://127.0.0.1:4000/api/v1
```

Android emulator host-a `10.0.2.2` ilə çatır: `http://10.0.2.2:4000/api/v1`.

Bundle id: `com.onelineplanner.app`.
