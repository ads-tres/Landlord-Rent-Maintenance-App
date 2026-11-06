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
- Settings: turn SMS rent reminders on or off, and **Connect Telegram** (when the server has a bot) to get an
  alert for each new tenant repair.
- **Telegram:** tenants who linked the bot get receipts, reminders and repair updates there instead of SMS, and
  are marked with a Telegram icon in the Tenants list. Repairs reported in the bot can include voice notes,
  which play from the repair page.
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
- **Compound tools** (property page ⋮ menu):
  - **Shared meters:** set up a water or electricity meter for some units (equal shares, fixed percentages or
    sub-meter readings). Enter each bill with an optional photo, preview the split, then save; each tenant's
    share becomes a charge next to their rent (marked "Electricity" or "Water"), and tenants are told.
  - **Equipment:** generator, water tank and pump with a service interval. Tap one to log a service. Home shows
    **Services due** for the coming week.
  - **Announcements:** one message to all current tenants, with the number of tenants, how many go free on
    Telegram, how many SMS and roughly what they cost before sending.
- Money is handled in santim (integers) and shown as `Br 12,500`.
- Settings shows the app version and, when configured, a **Send feedback** link to the pilot group.
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
    compound/    shared meters and bills, equipment, announcements
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

## Release build (pilot APKs)

Android builds are made by GitHub Actions (`.github/workflows/release-apk.yml`) and come out as two small
signed APKs: `arm64-v8a` for most phones and `armeabi-v7a` for older or low-end phones.

1. **Create a signing key once** and keep a copy offline. Losing it means pilots must uninstall to update.
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   base64 -w0 upload-keystore.jks   # paste into the ANDROID_KEYSTORE_BASE64 secret
   ```
2. In the repository's Settings → Secrets and variables → Actions, add:
   - **Secrets:** `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (`upload`),
     `ANDROID_KEY_PASSWORD`
   - **Variables:** `API_BASE_URL` (e.g. `https://api.example.et/api/v1`), and optionally `FEEDBACK_URL`
     (the pilot Telegram group link, shown as "Send feedback" in Settings)
3. Run **Actions → Release APK → Run workflow**, or push a tag (`git tag v1.0.0 && git push origin v1.0.0`)
   to also attach the APKs to a GitHub release. Bump `version:` in `pubspec.yaml` for each release.
4. Send the APK to pilots (Telegram works well). Install it for them during setup, and check Settings shows
   the version.

To build locally, put a `key.properties` (see `android/app/build.gradle.kts`) in `android/` and run
`flutter build apk --release --split-per-abi --dart-define=API_BASE_URL=https://…/api/v1`. Without
`key.properties`, the release build is signed with debug keys (fine for testing, not for pilots).

Release builds talk to the server over HTTPS only. Plain `http` is allowed in debug builds, for the local dev
server.

## Tests

```bash
flutter analyze
flutter test
```
