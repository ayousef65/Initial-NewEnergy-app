---
name: mobile-app-developer
description: Build, debug, test, preview, and package the New Energy Flutter mobile app and its app-facing WordPress contract. Use for Flutter features, Arabic RTL UI, Android or iOS setup, WooCommerce integration, release artifacts, and migration from the legacy Expo client; do not use for standalone WordPress work unrelated to the mobile API.
---

# Mobile App Developer

Treat `flutter_app/` as the primary client. The Expo files at the repository root
are a migration fallback; change them only when the user explicitly requests
legacy support or a parity fix.

## Start With Project Context

- Read [references/project-map.md](references/project-map.md) before the first
  substantive change in a task.
- Inspect the relevant Flutter implementation and the bundled WordPress plugin
  before changing a shared field, status, endpoint, payment shape, or review shape.
- Read `.env.example` for configuration names. Never print, copy, commit, or
  summarize values from `.env`.

## Work In The Flutter Architecture

- Keep app composition in `flutter_app/lib/app.dart`, state and workflows in
  `controllers/`, transport in `services/`, models in `models/`, fixtures in
  `data/`, and reusable presentation in `widgets/`.
- Use Material 3 and the existing theme before adding another design system or
  state-management package.
- Preserve Arabic copy, RTL direction, accessible semantics, keyboard behavior,
  and layouts down to a 320 px phone width.
- Keep the account-scoped encrypted request cache, offline queue, and shopping
  cart when WordPress is unavailable. Never expose one customer's cached data to
  another account.
- Add a dependency only when Flutter or the existing packages do not already
  provide the required capability. Use `flutter pub add` so the lockfile stays in
  sync.

## Keep The Mobile API Contract Together

For a service-request or response change, inspect and update the relevant layers:

- `flutter_app/lib/models/service_models.dart`
- `flutter_app/lib/services/new_energy_api.dart`
- controller and UI consumers
- fixtures and focused tests
- `wordpress-plugin/new-energy-mobile-api/new-energy-mobile-api.php` and its
  `includes/` modules

Do not call a production mutation endpoint merely to verify code. Use a fake API
in tests and verify read-only connectivity separately.

## Protect Credentials And Payments

- Values passed with `--dart-define` or `--dart-define-from-file` are bundled into
  the client and must be treated as public. Flutter must ignore the legacy Expo
  app token.
- Authenticate with the WordPress account routes and an opaque, revocable bearer
  session. Persist sessions and account-scoped caches only through
  `flutter_secure_storage`; never store administrator credentials in the app.
- Enforce ownership and management capabilities server-side for every private
  resource. UI filtering is not an authorization boundary.
- Give every queued create operation a stable client mutation ID and preserve it
  across retries so reconnecting cannot create duplicates.
- Keep automatic sync after successful writes, on app resume, and at the existing
  foreground interval. Refresh sessions before expiry and sign out cleanly after
  an unauthorized response.
- Log security-relevant and management actions through the plugin audit service,
  while redacting credentials and personal fields from metadata.
- Read published catalog data from the WooCommerce Store API, but create and list
  orders through the bearer-authenticated `/shop/orders` route. Keep product IDs
  and quantities as the only client-controlled line inputs; WooCommerce must
  validate purchasability, stock, prices, taxes, ownership, and final totals.
- Give shop checkout retries a stable mutation ID. Never place WooCommerce API
  keys or privileged store credentials in the mobile app.
- The current payment endpoint records payment state; it does not process cards.
  Do not imply PCI-compliant payment processing without a real provider flow.
- Keep keystores, store credentials, administrator credentials, and provider
  secrets out of the repository.

## Use The Local Toolchain

Prefer `flutter` and `dart` from `PATH`. On the current workstation, fall back to
`D:\tools\flutter\bin\flutter.bat` and `D:\tools\flutter\bin\dart.bat`.

The Android SDK is under the user's local Android SDK directory and Android Studio's
bundled JDK is configured for Flutter. Keep `kotlin.incremental=false` while the
project and pub cache are on different Windows drive letters; removing it revives
the Kotlin incremental-cache path failure.

## Verify Proportionally

After implementation changes, run from `flutter_app/`:

1. `dart format --output=none --set-exit-if-changed lib test`
2. `flutter analyze`
3. `flutter test`

For UI work, run the web preview with the repository `.env`, then inspect at a
320 px phone width, a standard phone width, and a wider viewport. Exercise the
changed interaction and check for overflow, clipped Arabic text, stale transitions,
and inaccessible controls.

For release work, also run:

- `flutter build web --release --dart-define-from-file=../.env`
- `flutter build apk --release --dart-define-from-file=../.env`

An APK proves Android compilation but is not Play Store readiness. Before an AAB
submission, require an official icon, production signing keystore, final contact
details, privacy disclosures, and a real-device check. iOS archives require macOS
and Xcode.

Finish with changed files, checks run, visual or device coverage, the artifact
path, and any remaining release blocker.
