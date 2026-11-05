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
  String get dashboardComingSoon =>
      'Rent totals, late tenants, open repairs and leases ending soon will show here once leases and payments are added.';

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
}
