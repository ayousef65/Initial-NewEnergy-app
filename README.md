# New Energy Service App

iOS and Android app built with Expo React Native for New Energy electric vehicle service workflows.

## Features

- Book maintenance.
- Request a home visit.
- Request an emergency visit.
- Buy spare parts.
- Buy a charger or accessory.
- Request emergency towing.
- Track maintenance stages, problems, and repairs.
- View the technical report and invoice.
- Select a payment method and mark payment as completed.
- Send reviews through Facebook and Google Maps.

## Run Locally

Required on the development machine:

- Node.js and npm.
- Expo CLI through `npx`.
- Expo Go on a real phone, or Android Studio/Xcode for simulators.

Commands:

```bash
npm install
npx expo start
```

Then choose:

- `a` to run Android.
- `i` to run iOS on macOS with Xcode.
- Scan the QR code with Expo Go to test on a real device.

## Project Structure

- `App.tsx`: app state, tab switching, and screen composition.
- `src/api`: WordPress and WooCommerce API calls.
- `src/components`: reusable UI, cards, modals, and maintenance timeline pieces.
- `src/data`: static service, billing, maintenance, and starter request data.
- `src/styles`: shared React Native styles.
- `src/types`: app-wide TypeScript models.
- `src/utils`: formatting and API-to-app mappers.

## Development Preferences

- Keep updates lean and avoid unnecessary abstractions.
- Add comments only when they clarify non-obvious behavior.
- Prefer small focused changes over broad rewrites.

## Connect The App To WordPress

The WordPress website used as the app database:

```text
https://newenergyeg.com
```

A ready-to-install WordPress plugin is included at:

```text
wordpress-plugin/new-energy-mobile-api
```

Connection steps:

1. Upload `wordpress-plugin/new-energy-mobile-api-flat.zip` from the WordPress dashboard:
   `Plugins > Add New > Upload Plugin`.
2. Activate the `New Energy Mobile API` plugin.
3. Open:
   `Settings > New Energy Mobile API`.
4. Copy the `App token` value.
5. Create a `.env` file next to `package.json` and add:

```bash
EXPO_PUBLIC_WORDPRESS_BASE_URL=https://newenergyeg.com
EXPO_PUBLIC_NEWENERGY_APP_TOKEN=paste-token-here
EXPO_PUBLIC_FACEBOOK_REVIEW_URL=https://www.facebook.com/newenergyeg
EXPO_PUBLIC_GOOGLE_MAPS_REVIEW_URL=https://www.google.com/maps/search/?api=1&query=New%20Energy%20Egypt
```

After that:

- App service requests are saved in WordPress under `Mobile Requests`.
- App payments update the request payment status in WordPress.
- In-app ratings are saved to the request before opening Facebook or Google Maps.
- WooCommerce products are shown in the app from the public store endpoint.

## Updating Requests In WordPress

Open your WordPress dashboard:

```text
https://newenergyeg.com/wp-admin
```

Then go to:

```text
Mobile Requests
```

Open any request to update:

- Customer and vehicle details.
- Maintenance status.
- Technical report.
- Missing items, problems, repairs, and items marked as not needed.
- Invoice items and total.
- Payment status and paid amount.

After saving the request in WordPress, open the app and tap `Update from WordPress` on the requests screen.

If WordPress shows `Plugin file does not exist`, use the `new-energy-mobile-api-flat.zip`
package. If the dashboard upload still fails, install it manually:

1. Open your hosting file manager or FTP.
2. Go to `wp-content/plugins/`.
3. Create a folder named `new-energy-mobile-api`.
4. Upload `wordpress-plugin/new-energy-mobile-api/new-energy-mobile-api.php` into that folder.
5. In WordPress Admin, open `Plugins` and activate `New Energy Mobile API`.

## Updating The Plugin Without Reuploading

Version `1.1.1` adds GitHub release updates. Install this version once, then future updates can appear in the normal WordPress update flow.

In WordPress:

```text
Settings > New Energy Mobile API > Plugin Updates
```

### GitHub Releases

The easiest update source is a public GitHub repository.

In the plugin settings, set:

```text
GitHub repository: owner/repository
GitHub release asset: new-energy-mobile-api.zip
```

Then publish a GitHub release with a tag newer than the installed plugin version, for example:

```text
v1.1.2
```

The included GitHub Actions workflow builds and uploads `new-energy-mobile-api.zip` to the release automatically.

WordPress will then show the update in:

```text
Dashboard > Updates
```

or:

```text
Plugins
```

### Initial GitHub Setup

Create a GitHub repository, then run:

```bash
git init
git add .
git commit -m "Initial New Energy app"
git branch -M main
git remote add origin https://github.com/OWNER/REPOSITORY.git
git push -u origin main
```

Do not commit `.env`; it is ignored because it contains private tokens.

### Manifest Fallback

You can also paste a public update manifest URL. The manifest should look like:

```json
{
  "version": "1.1.2",
  "download_url": "https://newenergyeg.com/wp-content/uploads/new-energy-mobile-api.zip",
  "details_url": "https://newenergyeg.com",
  "requires": "6.0",
  "tested": "6.8",
  "requires_php": "7.4",
  "description": "Mobile app API and request management for New Energy.",
  "changelog": "Describe the plugin change here."
}
```

Future release flow:

1. Update the plugin `Version` and `NEM_PLUGIN_VERSION` in `new-energy-mobile-api.php`.
2. Commit and push to GitHub.
3. Create a GitHub release using a tag like `v1.1.2`.
4. Wait for the release workflow to attach `new-energy-mobile-api.zip`.
5. In WordPress Admin, open `Dashboard > Updates` or `Plugins` and update `New Energy Mobile API`.

Use `wordpress-plugin/update-manifest.example.json` as the template.

## Build Android And iOS

Install EAS CLI or run it through `npx`:

```bash
npm install
npx eas build --platform android --profile production
npx eas build --platform ios --profile production
```

Build configuration files:

- `app.json` for app name, package identifiers, and Expo settings.
- `eas.json` for EAS build profiles.

## Before Publishing

- Replace the phone number inside `App.tsx`.
- Replace the review links in `.env` with the real Facebook page and Google Maps place links.
- Add the official app icon and splash screen before submitting to the stores.
