# New Energy Service (Flutter)

Arabic RTL app for WordPress-backed customer accounts, electric-vehicle service
requests, maintenance tracking, reports, payment verification, reviews, and a
native WooCommerce catalog, encrypted cart, checkout, and order history.

## Run

Flutter is currently installed at `D:\tools\flutter` on this workstation.

```powershell
D:\tools\flutter\bin\flutter.bat pub get
D:\tools\flutter\bin\flutter.bat run -d chrome --dart-define-from-file=../.env
```

The app uses the existing repository configuration keys:

- `EXPO_PUBLIC_WORDPRESS_BASE_URL`
- `EXPO_PUBLIC_FACEBOOK_REVIEW_URL`
- `EXPO_PUBLIC_GOOGLE_MAPS_REVIEW_URL`
- `NEWENERGY_SERVICE_PHONE` (optional)

All compile-time values are bundled into the client. Authentication uses a
WordPress-issued bearer session stored with `flutter_secure_storage`; never use
compile-time values for administrator credentials, signing keys, or payment
secrets.

The app syncs after every write, on app resume, and every 45 seconds while open.
Offline requests retain an idempotency key so reconnecting cannot create duplicate
WordPress records.

Published products come from the WooCommerce Store API. Store orders use the
signed-in account route so the server validates prices and stock, calculates the
order total, prevents duplicate retries, and retains each order in WooCommerce.

## Verify

```powershell
D:\tools\flutter\bin\dart.bat format --output=none --set-exit-if-changed lib test
D:\tools\flutter\bin\flutter.bat analyze
D:\tools\flutter\bin\flutter.bat test
D:\tools\flutter\bin\flutter.bat build web --release --dart-define-from-file=../.env
D:\tools\flutter\bin\flutter.bat build apk --release --dart-define-from-file=../.env
```

An Android App Bundle for Play Console upload can be produced with
`flutter build appbundle --release` after configuring the production signing
keystore. iOS archives require macOS, Xcode, and an Apple signing identity.
