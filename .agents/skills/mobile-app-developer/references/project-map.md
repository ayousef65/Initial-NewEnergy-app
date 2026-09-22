# New Energy Mobile Project Map

## Product And Stack

The primary client is a Flutter 3.47 app in `flutter_app/`, targeting Android,
iOS, and a web preview. It is Arabic-first and RTL, uses Material 3, stores the
signed-in session and account-scoped offline cache with platform secure storage,
and communicates with WordPress REST routes plus the public WooCommerce Store API.

The former Expo React Native client remains at the repository root during
migration. Treat it as legacy unless a task explicitly targets it.

## Flutter Ownership Boundaries

| Area | Primary files | Responsibility |
| --- | --- | --- |
| App composition | `flutter_app/lib/app.dart` | Lifecycle sync, auth gate, locale, direction, and navigation |
| Startup | `flutter_app/lib/main.dart` | Framework initialization, secure stores, controller wiring |
| Configuration | `flutter_app/lib/config/app_config.dart` | Compile-time WordPress, review, and phone values |
| State/workflows | `flutter_app/lib/controllers/app_controller.dart` | Authentication, requests, automatic updates, shop cart and orders, payment, rating, offline behavior |
| API transport | `flutter_app/lib/services/new_energy_api.dart` | Bearer-authenticated WordPress calls, WooCommerce calls, and response mapping |
| Persistence | `flutter_app/lib/services/auth_store.dart`, `secure_storage.dart`, `request_store.dart`, `shop_store.dart` | Secure session storage, account-keyed request and cart caches, and in-memory test stores |
| Domain model | `flutter_app/lib/models/service_models.dart` | Account, session, request, invoice, repair, product, cart, store order, and result types |
| Formatting | `flutter_app/lib/utils/formatters.dart` | Arabic status, date, and money formatting |
| Screens | `flutter_app/lib/screens/` | Authentication, home, requests, tracking, invoice, payment, reviews, catalog, product detail, cart, and checkout |
| Reusable UI | `flutter_app/lib/widgets/` | Cards, banners, request sheet, controls, timeline |
| Design system | `flutter_app/lib/theme/app_theme.dart` | Material theme, color, typography, navigation styles |
| Fixtures | `flutter_app/lib/data/sample_data.dart` | Services, starter request, stages, repairs, invoice, payments |
| Automated tests | `flutter_app/test/` | Formatters, mapping, controller workflows, widget smoke tests |
| Server companion | `wordpress-plugin/new-energy-mobile-api/` | REST routes, WordPress ownership, sessions, audit storage, and admin UI |

## Runtime Data Flow

1. `main.dart` initializes Arabic date symbols, secure stores, and the controller.
2. `AppController` restores and validates a saved WordPress session before showing
   account data. Logged-out users remain behind the auth gate.
3. After login, the controller loads that account's encrypted cache immediately,
   then synchronizes private records with a bearer-authenticated API request.
4. Failed request creation remains in the account's offline queue with a stable
   mutation ID. A retry returns the existing server record instead of duplicating it.
5. Writes trigger immediate sync; app resume and a 45-second foreground timer pull
   management changes. Sessions refresh before expiry.
6. Payment and review actions require an account-owned WordPress request ID.
7. The account cart is encrypted locally. Checkout sends product IDs, quantities,
   delivery details, and a stable mutation ID; WooCommerce validates stock and
   recalculates totals before creating an account-owned order.

## API Contract

- Public health: `GET /wp-json/newenergy/v1/health`
- Public accounts: `POST /wp-json/newenergy/v1/auth/register`, `/auth/login`, and
  `/auth/forgot-password`
- Bearer session: `GET /auth/me`, `POST /auth/refresh`, and `/auth/logout`
- Incremental account sync: `GET /wp-json/newenergy/v1/sync`
- Account-owned requests: `GET|POST /wp-json/newenergy/v1/service-requests`
- Account-owned detail: `GET /wp-json/newenergy/v1/service-requests/{id}`
- Account-owned payment record: `POST /wp-json/newenergy/v1/service-requests/{id}/payment`
- Account-owned review: `POST /wp-json/newenergy/v1/service-requests/{id}/review`
- Public products: `GET /wp-json/wc/store/v1/products`
- Account-owned store orders: `GET|POST /wp-json/newenergy/v1/shop/orders`

Important request keys include `client_mutation_id`, `service_id`, `service_title`,
`status`, `priority`, `customer_name`, `phone`, `vehicle`, `location`,
`preferred_date`, and `notes`.
The current WordPress response uses camelCase names consumed by
`ServiceRequest.fromJson`.

## Configuration Contract

The committed `.env.example` defines:

- `EXPO_PUBLIC_WORDPRESS_BASE_URL`
- `EXPO_PUBLIC_FACEBOOK_REVIEW_URL`
- `EXPO_PUBLIC_GOOGLE_MAPS_REVIEW_URL`
- `NEWENERGY_SERVICE_PHONE`

The legacy Expo token can remain temporarily for the old client, but Flutter does
not read it. The `EXPO_PUBLIC_` prefix is retained for shared migration-era public
values; every compile-time value remains public inside the compiled app.

## Build And Release

- Android application ID: `com.newenergy.service`
- iOS bundle ID: `com.newenergy.service`
- Flutter version: `2.1.0+3`
- Launcher source: `flutter_app/assets/app_icon.png`
- Android output: `flutter_app/build/app/outputs/flutter-apk/`
- Web output: `flutter_app/build/web/`

`flutter_launcher_icons` regenerates platform icons and `flutter_native_splash`
regenerates launch screens. Run their generators after changing the source icon.

The local release APK uses development signing until an Android upload keystore
is configured. Never commit the keystore or `key.properties`.

## Change Routing

- UI-only: inspect the screen, shared widget, and theme; verify RTL at 320 px and
  a standard phone width.
- New request field: update the model, sheet, controller payload, API transport,
  PHP sanitization/storage/serialization, fixtures, and tests.
- New server field: update PHP serialization, model mapping, consumers, fixtures,
  and tests.
- Status change: update WordPress options, Arabic localization, stage selection,
  status tone, and tests.
- Shop flow: update product/cart/order models, secure cart persistence, controller,
  native screens, API transport, `includes/shop.php`, and checkout tests together.
- New plugin: add with `flutter pub add`, inspect native setup and permissions,
  analyze, test, and rebuild Android plus web.
- Release: verify IDs, version, icon/splash, public configuration, signing,
  privacy requirements, and real-device behavior.

## Legacy Expo Map

`App.tsx`, `src/`, `package.json`, `app.json`, and `eas.json` belong to the legacy
Expo client. Preserve them until Flutter parity is approved, but do not implement
new behavior there by default.
