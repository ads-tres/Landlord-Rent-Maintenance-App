# Kiray — Landlord App (Flutter)

Android and iOS app for small Addis Ababa landlords (2 to 20 units) to keep track of
properties, units, tenants, leases, rent and repairs. It talks only to the Laravel API in
[`Landlord-Rent-Maintenance-`](https://github.com/ads-tres/Landlord-Rent-Maintenance-).

> "Kiray" (ኪራይ, "rent") is a working name. It is set in `lib/l10n/app_*.arb` (`appName`).

## What's built so far

- Phone login with an SMS code (`/auth/otp` → `/auth/verify`). The token is kept in secure storage.
- Home, Properties, Tenants and Settings tabs.
- Properties list with unit and vacancy counts, add property, property detail with units, add unit.
- Tenants list with search, and an add-tenant form with the required privacy-notice confirmation.
- Amharic (default) and English, switchable on the login screen and in Settings.
  Noto Sans Ethiopic is bundled for Ge'ez script.
- Next: leases and the rent schedule, payment logging, repairs, reports, and the offline cache.

## Structure

```
lib/
  app.dart, main.dart
  core/          config, Dio API client + errors, secure storage, router, theme, locale
  features/
    auth/        data (repository) · domain (AppUser) · application (AuthController) · presentation
    properties/  data · domain (Property, Unit) · presentation
    tenants/     data · domain (Tenant) · presentation
    home/        bottom-nav shell, dashboard, settings
  l10n/          app_en.arb, app_am.arb (+ generated AppLocalizations)
```

State is handled with Riverpod, HTTP with Dio, and navigation with go_router (redirects follow the auth
state). Every user-facing string lives in the ARB files.

## Running

```bash
flutter pub get
# Android emulator talking to `php artisan serve` on the host:
flutter run
# Any other API:
flutter run --dart-define=API_BASE_URL=https://api.example.et/api/v1
```

With the backend's `SMS_DRIVER=log`, the login code appears in the backend's `storage/logs/laravel.log`.

## Tests

```bash
flutter analyze
flutter test
```
