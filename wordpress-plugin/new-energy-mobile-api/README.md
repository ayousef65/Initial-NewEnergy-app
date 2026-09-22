# New Energy Mobile API

WordPress and WooCommerce companion plugin for the New Energy Flutter app.

## Installation

1. Back up the WordPress database and plugin directory.
2. Install or replace the `new-energy-mobile-api` plugin folder.
3. Activate the plugin. On activation or upgrade it creates the mobile session
   and audit tables with WordPress `dbDelta()`.
4. Confirm the REST health route at `/wp-json/newenergy/v1/health` over HTTPS.

No administrator credential or shared application token belongs in the mobile
app. Customers register or sign in with WordPress accounts and receive an opaque,
revocable 30-day bearer session. Only a SHA-256 token hash is stored server-side.

## Data And Sync

- Service requests are private posts owned by the authenticated WordPress user.
- A client mutation ID makes offline retries idempotent.
- `/sync` returns only the signed-in user's changed records unless a WordPress
  manager performs an authenticated administrative request.
- Customer payment submissions remain `submitted` until management verifies them.
  This plugin does not collect card numbers or act as a payment gateway.

## Native Shop

- Product browsing uses WooCommerce's public Store API.
- `/shop/orders` creates and lists orders belonging to the signed-in account.
- WooCommerce validates each product, quantity, stock state, price, tax, and final
  line total on the server. Values supplied by the app are never trusted.
- A client mutation ID prevents duplicate orders after retries or interrupted
  connections.
- New mobile orders are placed on hold so management can confirm delivery and
  payment. The app does not collect card details.

## Audit And Retention

Registration, login, password changes, request creation and viewing, sync changes,
shop orders, payments, reviews, management edits, logout, and exports are recorded in a
plugin-owned audit table. Passwords, bearer tokens, email addresses, and phone
numbers are removed before audit storage. Events are retained for 180 days and
can be viewed or exported from `Mobile Requests > Audit History`.

Expired or revoked sessions and old audit events are pruned daily through WP-Cron.
For predictable production timing, configure the host's system scheduler to run
WordPress cron regularly.
