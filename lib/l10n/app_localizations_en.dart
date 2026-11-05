// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kiray';

  @override
  String get loginTitle => 'Log in with your phone';

  @override
  String get loginSubtitle => 'We will send you a 6-digit code by SMS.';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get phoneHint => '09XX XXX XXX';

  @override
  String get phoneInvalid =>
      'Enter an Ethiopian mobile number, for example 0911 234 567.';

  @override
  String get sendCode => 'Send code';

  @override
  String get codeTitle => 'Enter the code';

  @override
  String codeSentTo(String phone) {
    return 'We sent a code to $phone.';
  }

  @override
  String get codeLabel => '6-digit code';

  @override
  String get codeInvalid => 'Enter the 6-digit code.';

  @override
  String get verify => 'Log in';

  @override
  String get resendCode => 'Send a new code';

  @override
  String get changeNumber => 'Change number';

  @override
  String get navDashboard => 'Home';

  @override
  String get navProperties => 'Properties';

  @override
  String get navTenants => 'Tenants';

  @override
  String get navSettings => 'Settings';

  @override
  String dashboardWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String get dashboardWelcomeNoName => 'Welcome';

  @override
  String get dashboardProperties => 'Properties';

  @override
  String get dashboardUnits => 'Units';

  @override
  String get dashboardVacant => 'Vacant';

  @override
  String get propertiesEmpty =>
      'No properties yet. Add your compound or building to start.';

  @override
  String get addProperty => 'Add property';

  @override
  String get propertyName => 'Name';

  @override
  String get propertyNameHint => 'e.g. Bole compound';

  @override
  String get subCity => 'Sub-city';

  @override
  String get woreda => 'Woreda';

  @override
  String get address => 'Address';

  @override
  String unitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count units',
      one: '1 unit',
      zero: 'No units',
    );
    return '$_temp0';
  }

  @override
  String vacantCount(int count) {
    return '$count vacant';
  }

  @override
  String get unitsEmpty =>
      'No units yet. Add the rooms or apartments you rent out.';

  @override
  String get addUnit => 'Add unit';

  @override
  String get unitLabel => 'Label';

  @override
  String get unitLabelHint => 'e.g. Room 3 or Apt 2B';

  @override
  String get bedrooms => 'Bedrooms';

  @override
  String get statusVacant => 'Vacant';

  @override
  String get statusOccupied => 'Occupied';

  @override
  String get tenantsEmpty => 'No tenants yet.';

  @override
  String get addTenant => 'Add tenant';

  @override
  String get searchTenants => 'Search by name or phone';

  @override
  String get fullName => 'Full name';

  @override
  String get idNumber => 'ID number (optional)';

  @override
  String get idNumberHelp => 'Only if the lease form needs it.';

  @override
  String get privacyNoticeTitle => 'Privacy notice';

  @override
  String get privacyNoticeBody =>
      'Tell the tenant: \"Your name, phone and lease details are stored to keep rent records. The data is stored in Ethiopia, seen only by your landlord, and you can ask for it to be corrected or deleted.\"';

  @override
  String get privacyNoticeConfirm => 'I have told the tenant about this notice';

  @override
  String get privacyNoticeRequired =>
      'Confirm that the tenant was told about the privacy notice.';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Try again';

  @override
  String get required => 'Required';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get networkError =>
      'No connection. Check your internet and try again.';

  @override
  String get language => 'Language';

  @override
  String get calendar => 'Calendar';

  @override
  String get calendarEthiopian => 'Ethiopian';

  @override
  String get calendarGregorian => 'Gregorian';

  @override
  String get logout => 'Log out';

  @override
  String get disclaimer => 'A record-keeping tool, not legal or tax advice.';

  @override
  String get navRent => 'Rent';

  @override
  String get currency => 'Br';

  @override
  String get addLease => 'Create lease';

  @override
  String get leaseTitle => 'Lease';

  @override
  String leaseFor(String unit) {
    return 'Lease for $unit';
  }

  @override
  String get tenant => 'Tenant';

  @override
  String get selectTenant => 'Choose a tenant';

  @override
  String get newTenant => 'New tenant';

  @override
  String get noTenantsYet => 'No tenants yet. Add the tenant first.';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String endDateHelp(int years) {
    return 'Leases run at least $years years (Addis directive).';
  }

  @override
  String endDateTooEarly(String date) {
    return 'The end date must be $date or later.';
  }

  @override
  String get monthlyRent => 'Monthly rent (Br)';

  @override
  String get deposit => 'Deposit (Br)';

  @override
  String get dueDay => 'Rent due on day';

  @override
  String get dueDayHelp => 'Day of the month rent is due.';

  @override
  String get conditionNotes => 'Property condition';

  @override
  String get conditionNotesHint =>
      'Walls, floors, fixtures, meters, keys handed over…';

  @override
  String get registeredOn => 'Registered with the woreda on';

  @override
  String get notRegistered => 'Not registered yet';

  @override
  String get amountInvalid => 'Enter an amount in birr.';

  @override
  String get leaseActive => 'Active';

  @override
  String get leaseEnded => 'Ended';

  @override
  String get leaseDraft => 'Draft';

  @override
  String endsIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Ends in $days days',
      one: 'Ends tomorrow',
      zero: 'Ends today',
    );
    return '$_temp0';
  }

  @override
  String endedOn(String date) {
    return 'Ended on $date';
  }

  @override
  String missingLeaseFields(String fields) {
    return 'Missing for the directive: $fields';
  }

  @override
  String get missingLandlordName => 'your name (Settings)';

  @override
  String get missingTenantAddress => 'tenant address';

  @override
  String get missingConditionNotes => 'property condition';

  @override
  String get balanceCharged => 'Charged';

  @override
  String get balancePaid => 'Paid';

  @override
  String get balanceOutstanding => 'Outstanding';

  @override
  String get rentHistory => 'Rent changes';

  @override
  String rentChangeLine(String from, String to, String date, String cap) {
    return '$from → $to from $date (cap $cap%)';
  }

  @override
  String get changeRent => 'Change rent';

  @override
  String get newRent => 'New monthly rent (Br)';

  @override
  String get effectiveDate => 'Effective from';

  @override
  String currentRent(String amount) {
    return 'Current rent: $amount';
  }

  @override
  String aboveCap(String cap, String max) {
    return 'Above the $cap% yearly cap. The most allowed is $max.';
  }

  @override
  String withinCap(String percent, String cap) {
    return 'Increase of $percent% (cap $cap%).';
  }

  @override
  String get endLease => 'End lease';

  @override
  String endLeaseConfirm(String date) {
    return 'End this lease on $date? The unit becomes vacant and unpaid rent for later months is removed.';
  }

  @override
  String get endedOnLabel => 'Last day';

  @override
  String get charges => 'Rent schedule';

  @override
  String get chargesEmpty => 'No rent due for this month.';

  @override
  String get statusDue => 'Due';

  @override
  String get statusPartial => 'Partly paid';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusLate => 'Late';

  @override
  String daysLate(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days late',
      one: '1 day late',
    );
    return '$_temp0';
  }

  @override
  String dueOn(String date) {
    return 'Due $date';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterUnpaid => 'Unpaid';

  @override
  String get monthTotalDue => 'Due this month';

  @override
  String get monthCollected => 'Collected';

  @override
  String get monthOutstanding => 'Outstanding';

  @override
  String get unitVacantTapToLease => 'Vacant · tap to create a lease';

  @override
  String get confirm => 'Confirm';

  @override
  String get logPayment => 'Log payment';

  @override
  String get amountPaid => 'Amount paid (Br)';

  @override
  String get paidOn => 'Paid on';

  @override
  String get paymentMethod => 'Paid by';

  @override
  String get methodCash => 'Cash';

  @override
  String get methodTelebirr => 'Telebirr';

  @override
  String get methodBank => 'Bank';

  @override
  String get methodChapa => 'Chapa';

  @override
  String get reference => 'Transaction reference';

  @override
  String get referenceHelp => 'From the Telebirr SMS or bank slip.';

  @override
  String get notes => 'Note (optional)';

  @override
  String get sendSmsReceipt => 'Send SMS receipt to the tenant';

  @override
  String quickBalance(String amount) {
    return 'Balance $amount';
  }

  @override
  String quickMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get paymentSaved => 'Payment saved';

  @override
  String paymentCovers(String months) {
    return 'Covers $months';
  }

  @override
  String receiptNumber(String number) {
    return 'Receipt $number';
  }

  @override
  String get smsQueued => 'SMS receipt sent to the tenant.';

  @override
  String get shareReceipt => 'Share receipt link';

  @override
  String get done => 'Done';

  @override
  String get payments => 'Payments';

  @override
  String get paymentsEmpty => 'No payments logged yet.';

  @override
  String get removePayment => 'Remove payment';

  @override
  String removePaymentConfirm(String amount) {
    return 'Remove this payment of $amount? The months it covered become unpaid again.';
  }

  @override
  String get dashboardCollected => 'Collected this month';

  @override
  String get dashboardOutstanding => 'Outstanding';

  @override
  String get dashboardLateTenants => 'Late tenants';

  @override
  String get dashboardOpenRepairs => 'Open repairs';

  @override
  String get dashboardLeasesEnding => 'Leases ending in 60 days';

  @override
  String dashboardDueThisMonth(String amount) {
    return 'Due this month: $amount';
  }

  @override
  String get smsReminders => 'SMS rent reminders';

  @override
  String get smsRemindersHelp =>
      'Text tenants 3 days before and on the due date.';
}
