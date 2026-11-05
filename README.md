# Kiray — Landlord App (Flutter)

Android and iOS app for small Addis Ababa landlords (2 to 20 units) to keep track of
properties, units, tenants, leases, rent and repairs. It talks only to the Laravel API in
[`Landlord-Rent-Maintenance-`](https://github.com/ads-tres/Landlord-Rent-Maintenance-).

> "Kiray" (ኪራይ, "rent") is a working name. It is set in `lib/l10n/app_*.arb` (`appName`).

## What's built so far

- Phone login with an SMS code (`/auth/otp` → `/auth/verify`). The token is kept in secure storage.
- Home, Properties, Rent, Tenants and Settings tabs.
- Properties list with unit and vacancy counts, add property, property detail with units, add unit.
- Tenants list with search, and an add-tenant form with the required privacy-notice confirmation.
- Amharic (default) and English, switchable on the login screen and in Settings.
  Noto Sans Ethiopic is bundled for Ge'ez script.
- Leases: tap a vacant unit to create one. The form follows the Addis directive: the end date defaults to
  the 2-year minimum, the due day defaults to the start day, and property condition is required.
  Unchecked items the directive asks for are flagged.
- Lease detail: balance, rent schedule, rent-change history, **change rent** (warns above the yearly cap from
  `GET /rules`), and **end lease**.
- Rent tab: one month at a time, with totals for due, collected and outstanding, filters (unpaid, late,
  partly paid, paid), and days late.
- Money is handled in santim (integers) and shown as `Br 12,500`. Dates are Gregorian for now.
- Next: payment logging and receipts, repairs, reports, the Ethiopian calendar and the offline cache.

## Structure

```
lib/
  app.dart, main.dart
  core/          config, Dio API client + errors, secure storage, router, theme, locale
  features/
    auth/        data (repository) · domain (AppUser) · application (AuthController) · presentation
    properties/  data · domain (Property, Unit) · presentation
    tenants/     data · domain (Tenant) · presentation
    leases/      data · domain (Lease, Charge, RentRules) · presentation (add, detail)
    rent/        monthly rent list
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
