# Kiray — Landlord App (Flutter)

Android and iOS app for small Addis Ababa landlords (2 to 20 units) to keep track of
properties, units, tenants, leases, rent and repairs. It talks only to the Laravel API in
[`Landlord-Rent-Maintenance-`](https://github.com/ads-tres/Landlord-Rent-Maintenance-).

> "Kiray" (ኪራይ, "rent") is a working name. It is set in `lib/l10n/app_*.arb` (`appName`).

## What's built so far

- Phone login with an SMS code (`/auth/otp` → `/auth/verify`). The token is kept in secure storage.
- Home, Properties, Rent, Repairs and Tenants tabs. Settings is behind the gear icon on Home.
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
- Payments: log cash, Telebirr or bank payments from the Rent tab (tap an unpaid month) or a lease.
  Quick amounts for the balance or 1–6 months, a reference required for Telebirr and bank, and an
  optional SMS receipt. Afterwards you get the receipt number, the months covered and a **share receipt
  link** button. Payment history sits on the lease, where a mistaken entry can be removed.
- Home dashboard: collected this month, outstanding, late tenants, open repairs, leases ending soon and
  vacant units, with shortcuts to the filtered Rent tab.
- Repairs: tenants report through their repair link (shown on the lease, sent by SMS or shared). You can
  also record repairs yourself with up to 4 photos (camera or gallery, shrunk on the phone to save data).
  Move a repair from new to in progress to done, with an optional note texted to the tenant. Photos are
  private and load with your login.
- Settings: turn SMS rent reminders on or off.
- **Ethiopian calendar** (default; switch in Settings): dates show as e.g. "6 ኅዳር 2019", and rent months
  as the Ethiopian months they span ("ጥቅምት–ኅዳር 2019"). Conversion is in
  `lib/core/utils/ethiopian_date.dart`, checked against the backend's andegna/calender results.
- **Quarterly income report** (Home): Ethiopian fiscal or Gregorian quarters, totals by month, property
  and method, and **Share PDF** for an accountant or the tax office. There's no tax calculation.
- **Works with weak signal:**
  - The main lists are saved on the phone and shown with a "No connection" banner when offline.
  - Payments logged offline are kept on the phone, marked **Not synced**, and sent automatically on start,
    when the app reopens, on pull-to-refresh or from **Sync now**. A `client_ref` makes sure a resend never
    creates a duplicate.
  - Saved data and unsent payments are cleared on logout.
- **Privacy:** from the Tenants list menu, **Export data** shares the tenant's records as JSON, and
  **Remove personal data** anonymizes a past tenant (payment amounts stay).
- Money is handled in santim (integers) and shown as `Br 12,500`.
- Next: pilot with 10 landlords, including a test pass on low-end Android phones.

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
    payments/    data · domain (Payment, DashboardSummary) · presentation (log payment, receipt sheet)
    repairs/     data · domain (Repair, UnitOption) · presentation (list, detail, add)
    reports/     quarterly income report + PDF sharing
  core/offline/  response cache (saved screens) and offline banner state
  features/payments/application/  pending (offline) payments queue
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
