/// Override for a local backend: `--dart-define=API_URL=http://127.0.0.1:4000/api/v1`
/// Android emulator reaches the host at `http://10.0.2.2:4000/api/v1`.
const apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://onelineplanner.com/api/v1',
);

/// RevenueCat public SDK keys. Empty means this build cannot sell Pro in the store.
/// `--dart-define=REVENUECAT_APPLE_KEY=appl_... --dart-define=REVENUECAT_GOOGLE_KEY=goog_...`
const revenueCatAppleKey = String.fromEnvironment('REVENUECAT_APPLE_KEY');
const revenueCatGoogleKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY');
