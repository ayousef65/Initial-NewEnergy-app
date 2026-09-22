# New Energy Service App

Flutter mobile app for New Energy electric-vehicle service workflows. The app
is Arabic-first and right-to-left, keeps an encrypted offline cache, and connects
to the bundled WordPress API plugin with individual customer accounts.

The former Expo client remains at the repository root as a temporary migration
fallback. New mobile development belongs in `flutter_app/`.

## Features

- Book maintenance, home visits, emergency visits, spare parts, chargers, and towing.
- Register, sign in, recover a password, and sign out with WordPress accounts.
- Save account data in platform secure storage and synchronize automatically.
- Track maintenance stages, reported problems, and repairs.
- Review the technical report and itemized invoice.
- Submit a payment method for management verification without collecting card data.
- Send a rating to WordPress before opening Facebook or Google Maps.
- Browse products, search categories, keep an encrypted account cart, submit a
  native WooCommerce order, and review recent store orders without leaving the app.

## Flutter Workflow

Flutter 3.47.5 is installed at `D:\tools\flutter` on this workstation. From
`flutter_app/`:

```powershell
D:\tools\flutter\bin\flutter.bat pub get
D:\tools\flutter\bin\flutter.bat run -d chrome --dart-define-from-file=../.env
```

Run the quality suite:

```powershell
D:\tools\flutter\bin\dart.bat format --output=none --set-exit-if-changed lib test
D:\tools\flutter\bin\flutter.bat analyze
D:\tools\flutter\bin\flutter.bat test
```

Build locally without Expo or a cloud build service:

```powershell
D:\tools\flutter\bin\flutter.bat build web --release --dart-define-from-file=../.env
D:\tools\flutter\bin\flutter.bat build apk --release --dart-define-from-file=../.env
```

The APK is written to
`flutter_app/build/app/outputs/flutter-apk/app-release.apk`. iOS archives require
macOS, Xcode, and an Apple signing identity.

## Configuration

The Flutter app uses these public configuration values:

```dotenv
EXPO_PUBLIC_WORDPRESS_BASE_URL=https://newenergyeg.com
EXPO_PUBLIC_FACEBOOK_REVIEW_URL=https://www.facebook.com/newenergyeg
EXPO_PUBLIC_GOOGLE_MAPS_REVIEW_URL=https://www.google.com/maps/search/?api=1&query=New%20Energy%20Egypt
NEWENERGY_SERVICE_PHONE=01000000000
```

Pass the file with `--dart-define-from-file=../.env`. These values are compiled
into the client and are public. The legacy Expo token may remain in the repository
`.env` during migration, but Flutter ignores it. Never place WordPress administrator
credentials, payment secrets, signing keys, or other privileged credentials here.

## WordPress Integration

The companion plugin is in `wordpress-plugin/new-energy-mobile-api/`. Its routes
live under `/wp-json/newenergy/v1`:

- Public health check: `GET /health`
- Accounts: `POST /auth/register`, `/auth/login`, `/auth/logout`, `/auth/refresh`
- Account profile and password recovery: `GET /auth/me`, `POST /auth/forgot-password`
- Automatic changes: `GET /sync`
- Account-owned requests: `GET|POST /service-requests`
- Request detail: `GET /service-requests/{id}`
- Payment recording: `POST /service-requests/{id}/payment`
- Reviews: `POST /service-requests/{id}/review`
- Account-owned shop orders: `GET|POST /shop/orders`

Activating or upgrading the plugin creates its session and audit tables
automatically. Customer routes require expiring, revocable bearer sessions;
requests are restricted by WordPress user ownership. Payment currently submits an
external payment method for management verification; it is not a card-processing
gateway.

The native store reads published products through WooCommerce's public Store API.
Order creation is handled by the authenticated plugin route, which checks current
prices, purchasability, and stock on the server before creating an account-owned
WooCommerce order. Mobile orders remain on hold until delivery and payment are
confirmed; the app never collects card details.

The app pushes local changes immediately, retries queued requests safely, refreshes
after app resume, and checks for management updates every 45 seconds while open.
WordPress managers can review or export redacted events from
`Mobile Requests > Audit History`.

The web preview can be blocked by browser CORS rules even when Android and iOS
network calls work. The app keeps its local fallback in that case.

## Release Notes

- Android application ID: `com.newenergy.service`
- iOS bundle ID: `com.newenergy.service`
- Version: `2.1.0+3`
- The official wordmark is in `flutter_app/assets/newenergy_logo.png`; launcher and
  splash assets use the `#2661e9` brand color.
- The local APK uses Flutter's development signing fallback. Configure an Android
  upload keystore before publishing an AAB to Google Play.
- Replace the placeholder service phone and configure production signing before
  store submission.

## Legacy Expo Client

The root `App.tsx`, `src/`, `package.json`, `app.json`, and `eas.json` belong to
the previous Expo implementation. Keep them only until Flutter parity is approved;
do not duplicate new features across both clients unless migration work requires it.
