import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Kiray'**
  String get appName;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in with your phone'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will send you a 6-digit code by SMS.'**
  String get loginSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'09XX XXX XXX'**
  String get phoneHint;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an Ethiopian mobile number, for example 0911 234 567.'**
  String get phoneInvalid;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @codeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get codeTitle;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {phone}.'**
  String codeSentTo(String phone);

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get codeLabel;

  /// No description provided for @codeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get codeInvalid;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get resendCode;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navDashboard;

  /// No description provided for @navProperties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get navProperties;

  /// No description provided for @navTenants.
  ///
  /// In en, this message translates to:
  /// **'Tenants'**
  String get navTenants;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @dashboardWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String dashboardWelcome(String name);

  /// No description provided for @dashboardWelcomeNoName.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get dashboardWelcomeNoName;

  /// No description provided for @dashboardProperties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get dashboardProperties;

  /// No description provided for @dashboardUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get dashboardUnits;

  /// No description provided for @dashboardVacant.
  ///
  /// In en, this message translates to:
  /// **'Vacant'**
  String get dashboardVacant;

  /// No description provided for @propertiesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No properties yet. Add your compound or building to start.'**
  String get propertiesEmpty;

  /// No description provided for @addProperty.
  ///
  /// In en, this message translates to:
  /// **'Add property'**
  String get addProperty;

  /// No description provided for @propertyName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get propertyName;

  /// No description provided for @propertyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bole compound'**
  String get propertyNameHint;

  /// No description provided for @subCity.
  ///
  /// In en, this message translates to:
  /// **'Sub-city'**
  String get subCity;

  /// No description provided for @woreda.
  ///
  /// In en, this message translates to:
  /// **'Woreda'**
  String get woreda;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @unitsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No units} =1{1 unit} other{{count} units}}'**
  String unitsCount(int count);

  /// No description provided for @vacantCount.
  ///
  /// In en, this message translates to:
  /// **'{count} vacant'**
  String vacantCount(int count);

  /// No description provided for @unitsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No units yet. Add the rooms or apartments you rent out.'**
  String get unitsEmpty;

  /// No description provided for @addUnit.
  ///
  /// In en, this message translates to:
  /// **'Add unit'**
  String get addUnit;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get unitLabel;

  /// No description provided for @unitLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Room 3 or Apt 2B'**
  String get unitLabelHint;

  /// No description provided for @bedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get bedrooms;

  /// No description provided for @statusVacant.
  ///
  /// In en, this message translates to:
  /// **'Vacant'**
  String get statusVacant;

  /// No description provided for @statusOccupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get statusOccupied;

  /// No description provided for @tenantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tenants yet.'**
  String get tenantsEmpty;

  /// No description provided for @addTenant.
  ///
  /// In en, this message translates to:
  /// **'Add tenant'**
  String get addTenant;

  /// No description provided for @searchTenants.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone'**
  String get searchTenants;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @idNumber.
  ///
  /// In en, this message translates to:
  /// **'ID number (optional)'**
  String get idNumber;

  /// No description provided for @idNumberHelp.
  ///
  /// In en, this message translates to:
  /// **'Only if the lease form needs it.'**
  String get idNumberHelp;

  /// No description provided for @privacyNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy notice'**
  String get privacyNoticeTitle;

  /// No description provided for @privacyNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Tell the tenant: \"Your name, phone and lease details are stored to keep rent records. The data is stored in Ethiopia, seen only by your landlord, and you can ask for it to be corrected or deleted.\"'**
  String get privacyNoticeBody;

  /// No description provided for @privacyNoticeConfirm.
  ///
  /// In en, this message translates to:
  /// **'I have told the tenant about this notice'**
  String get privacyNoticeConfirm;

  /// No description provided for @privacyNoticeRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm that the tenant was told about the privacy notice.'**
  String get privacyNoticeRequired;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get networkError;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @calendarEthiopian.
  ///
  /// In en, this message translates to:
  /// **'Ethiopian'**
  String get calendarEthiopian;

  /// No description provided for @calendarGregorian.
  ///
  /// In en, this message translates to:
  /// **'Gregorian'**
  String get calendarGregorian;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'A record-keeping tool, not legal or tax advice.'**
  String get disclaimer;

  /// No description provided for @navRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get navRent;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Br'**
  String get currency;

  /// No description provided for @addLease.
  ///
  /// In en, this message translates to:
  /// **'Create lease'**
  String get addLease;

  /// No description provided for @leaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Lease'**
  String get leaseTitle;

  /// No description provided for @leaseFor.
  ///
  /// In en, this message translates to:
  /// **'Lease for {unit}'**
  String leaseFor(String unit);

  /// No description provided for @tenant.
  ///
  /// In en, this message translates to:
  /// **'Tenant'**
  String get tenant;

  /// No description provided for @selectTenant.
  ///
  /// In en, this message translates to:
  /// **'Choose a tenant'**
  String get selectTenant;

  /// No description provided for @newTenant.
  ///
  /// In en, this message translates to:
  /// **'New tenant'**
  String get newTenant;

  /// No description provided for @noTenantsYet.
  ///
  /// In en, this message translates to:
  /// **'No tenants yet. Add the tenant first.'**
  String get noTenantsYet;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @endDateHelp.
  ///
  /// In en, this message translates to:
  /// **'Leases run at least {years} years (Addis directive).'**
  String endDateHelp(int years);

  /// No description provided for @endDateTooEarly.
  ///
  /// In en, this message translates to:
  /// **'The end date must be {date} or later.'**
  String endDateTooEarly(String date);

  /// No description provided for @monthlyRent.
  ///
  /// In en, this message translates to:
  /// **'Monthly rent (Br)'**
  String get monthlyRent;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit (Br)'**
  String get deposit;

  /// No description provided for @dueDay.
  ///
  /// In en, this message translates to:
  /// **'Rent due on day'**
  String get dueDay;

  /// No description provided for @dueDayHelp.
  ///
  /// In en, this message translates to:
  /// **'Day of the month rent is due.'**
  String get dueDayHelp;

  /// No description provided for @conditionNotes.
  ///
  /// In en, this message translates to:
  /// **'Property condition'**
  String get conditionNotes;

  /// No description provided for @conditionNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Walls, floors, fixtures, meters, keys handed over…'**
  String get conditionNotesHint;

  /// No description provided for @registeredOn.
  ///
  /// In en, this message translates to:
  /// **'Registered with the woreda on'**
  String get registeredOn;

  /// No description provided for @notRegistered.
  ///
  /// In en, this message translates to:
  /// **'Not registered yet'**
  String get notRegistered;

  /// No description provided for @amountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount in birr.'**
  String get amountInvalid;

  /// No description provided for @leaseActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get leaseActive;

  /// No description provided for @leaseEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get leaseEnded;

  /// No description provided for @leaseDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get leaseDraft;

  /// No description provided for @endsIn.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Ends today} =1{Ends tomorrow} other{Ends in {days} days}}'**
  String endsIn(int days);

  /// No description provided for @endedOn.
  ///
  /// In en, this message translates to:
  /// **'Ended on {date}'**
  String endedOn(String date);

  /// No description provided for @missingLeaseFields.
  ///
  /// In en, this message translates to:
  /// **'Missing for the directive: {fields}'**
  String missingLeaseFields(String fields);

  /// No description provided for @missingLandlordName.
  ///
  /// In en, this message translates to:
  /// **'your name (Settings)'**
  String get missingLandlordName;

  /// No description provided for @missingTenantAddress.
  ///
  /// In en, this message translates to:
  /// **'tenant address'**
  String get missingTenantAddress;

  /// No description provided for @missingConditionNotes.
  ///
  /// In en, this message translates to:
  /// **'property condition'**
  String get missingConditionNotes;

  /// No description provided for @balanceCharged.
  ///
  /// In en, this message translates to:
  /// **'Charged'**
  String get balanceCharged;

  /// No description provided for @balancePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get balancePaid;

  /// No description provided for @balanceOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get balanceOutstanding;

  /// No description provided for @rentHistory.
  ///
  /// In en, this message translates to:
  /// **'Rent changes'**
  String get rentHistory;

  /// No description provided for @rentChangeLine.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to} from {date} (cap {cap}%)'**
  String rentChangeLine(String from, String to, String date, String cap);

  /// No description provided for @changeRent.
  ///
  /// In en, this message translates to:
  /// **'Change rent'**
  String get changeRent;

  /// No description provided for @newRent.
  ///
  /// In en, this message translates to:
  /// **'New monthly rent (Br)'**
  String get newRent;

  /// No description provided for @effectiveDate.
  ///
  /// In en, this message translates to:
  /// **'Effective from'**
  String get effectiveDate;

  /// No description provided for @currentRent.
  ///
  /// In en, this message translates to:
  /// **'Current rent: {amount}'**
  String currentRent(String amount);

  /// No description provided for @aboveCap.
  ///
  /// In en, this message translates to:
  /// **'Above the {cap}% yearly cap. The most allowed is {max}.'**
  String aboveCap(String cap, String max);

  /// No description provided for @withinCap.
  ///
  /// In en, this message translates to:
  /// **'Increase of {percent}% (cap {cap}%).'**
  String withinCap(String percent, String cap);

  /// No description provided for @endLease.
  ///
  /// In en, this message translates to:
  /// **'End lease'**
  String get endLease;

  /// No description provided for @endLeaseConfirm.
  ///
  /// In en, this message translates to:
  /// **'End this lease on {date}? The unit becomes vacant and unpaid rent for later months is removed.'**
  String endLeaseConfirm(String date);

  /// No description provided for @endedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Last day'**
  String get endedOnLabel;

  /// No description provided for @charges.
  ///
  /// In en, this message translates to:
  /// **'Rent schedule'**
  String get charges;

  /// No description provided for @chargesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rent due for this month.'**
  String get chargesEmpty;

  /// No description provided for @statusDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get statusDue;

  /// No description provided for @statusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partly paid'**
  String get statusPartial;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get statusLate;

  /// No description provided for @daysLate.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day late} other{{days} days late}}'**
  String daysLate(int days);

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueOn(String date);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get filterUnpaid;

  /// No description provided for @monthTotalDue.
  ///
  /// In en, this message translates to:
  /// **'Due this month'**
  String get monthTotalDue;

  /// No description provided for @monthCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get monthCollected;

  /// No description provided for @monthOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get monthOutstanding;

  /// No description provided for @unitVacantTapToLease.
  ///
  /// In en, this message translates to:
  /// **'Vacant · tap to create a lease'**
  String get unitVacantTapToLease;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @logPayment.
  ///
  /// In en, this message translates to:
  /// **'Log payment'**
  String get logPayment;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount paid (Br)'**
  String get amountPaid;

  /// No description provided for @paidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get paidOn;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paymentMethod;

  /// No description provided for @methodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get methodCash;

  /// No description provided for @methodTelebirr.
  ///
  /// In en, this message translates to:
  /// **'Telebirr'**
  String get methodTelebirr;

  /// No description provided for @methodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get methodBank;

  /// No description provided for @methodChapa.
  ///
  /// In en, this message translates to:
  /// **'Chapa'**
  String get methodChapa;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Transaction reference'**
  String get reference;

  /// No description provided for @referenceHelp.
  ///
  /// In en, this message translates to:
  /// **'From the Telebirr SMS or bank slip.'**
  String get referenceHelp;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get notes;

  /// No description provided for @sendSmsReceipt.
  ///
  /// In en, this message translates to:
  /// **'Send SMS receipt to the tenant'**
  String get sendSmsReceipt;

  /// No description provided for @quickBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance {amount}'**
  String quickBalance(String amount);

  /// No description provided for @quickMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String quickMonths(int count);

  /// No description provided for @paymentSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment saved'**
  String get paymentSaved;

  /// No description provided for @paymentCovers.
  ///
  /// In en, this message translates to:
  /// **'Covers {months}'**
  String paymentCovers(String months);

  /// No description provided for @receiptNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt {number}'**
  String receiptNumber(String number);

  /// No description provided for @smsQueued.
  ///
  /// In en, this message translates to:
  /// **'SMS receipt sent to the tenant.'**
  String get smsQueued;

  /// No description provided for @shareReceipt.
  ///
  /// In en, this message translates to:
  /// **'Share receipt link'**
  String get shareReceipt;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @paymentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments logged yet.'**
  String get paymentsEmpty;

  /// No description provided for @removePayment.
  ///
  /// In en, this message translates to:
  /// **'Remove payment'**
  String get removePayment;

  /// No description provided for @removePaymentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this payment of {amount}? The months it covered become unpaid again.'**
  String removePaymentConfirm(String amount);

  /// No description provided for @dashboardCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected this month'**
  String get dashboardCollected;

  /// No description provided for @dashboardOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get dashboardOutstanding;

  /// No description provided for @dashboardLateTenants.
  ///
  /// In en, this message translates to:
  /// **'Late tenants'**
  String get dashboardLateTenants;

  /// No description provided for @dashboardOpenRepairs.
  ///
  /// In en, this message translates to:
  /// **'Open repairs'**
  String get dashboardOpenRepairs;

  /// No description provided for @dashboardLeasesEnding.
  ///
  /// In en, this message translates to:
  /// **'Leases ending in 60 days'**
  String get dashboardLeasesEnding;

  /// No description provided for @dashboardDueThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Due this month: {amount}'**
  String dashboardDueThisMonth(String amount);

  /// No description provided for @smsReminders.
  ///
  /// In en, this message translates to:
  /// **'SMS rent reminders'**
  String get smsReminders;

  /// No description provided for @smsRemindersHelp.
  ///
  /// In en, this message translates to:
  /// **'Text tenants 3 days before and on the due date.'**
  String get smsRemindersHelp;

  /// No description provided for @navRepairs.
  ///
  /// In en, this message translates to:
  /// **'Repairs'**
  String get navRepairs;

  /// No description provided for @repairsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No repairs here.'**
  String get repairsEmpty;

  /// No description provided for @repairActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get repairActive;

  /// No description provided for @repairOpen.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get repairOpen;

  /// No description provided for @repairInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get repairInProgress;

  /// No description provided for @repairDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get repairDone;

  /// No description provided for @addRepair.
  ///
  /// In en, this message translates to:
  /// **'Record repair'**
  String get addRepair;

  /// No description provided for @repairTitle.
  ///
  /// In en, this message translates to:
  /// **'What needs fixing'**
  String get repairTitle;

  /// No description provided for @repairCategory.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get repairCategory;

  /// No description provided for @repairDescription.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get repairDescription;

  /// No description provided for @repairUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get repairUnit;

  /// No description provided for @repairFromTenant.
  ///
  /// In en, this message translates to:
  /// **'From tenant'**
  String get repairFromTenant;

  /// No description provided for @repairOpenedOn.
  ///
  /// In en, this message translates to:
  /// **'Reported {date}'**
  String repairOpenedOn(String date);

  /// No description provided for @repairClosedOn.
  ///
  /// In en, this message translates to:
  /// **'Done {date}'**
  String repairClosedOn(String date);

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get takePhoto;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get choosePhoto;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @startRepair.
  ///
  /// In en, this message translates to:
  /// **'Start work'**
  String get startRepair;

  /// No description provided for @finishRepair.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get finishRepair;

  /// No description provided for @reopenRepair.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopenRepair;

  /// No description provided for @repairNote.
  ///
  /// In en, this message translates to:
  /// **'Note for the tenant (optional)'**
  String get repairNote;

  /// No description provided for @repairNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Plumber coming at 3pm'**
  String get repairNoteHint;

  /// No description provided for @notifyTenantSms.
  ///
  /// In en, this message translates to:
  /// **'Text the tenant'**
  String get notifyTenantSms;

  /// No description provided for @categoryWater.
  ///
  /// In en, this message translates to:
  /// **'Water supply'**
  String get categoryWater;

  /// No description provided for @categoryElectric.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get categoryElectric;

  /// No description provided for @categoryPlumbing.
  ///
  /// In en, this message translates to:
  /// **'Plumbing / leak'**
  String get categoryPlumbing;

  /// No description provided for @categoryDoorLock.
  ///
  /// In en, this message translates to:
  /// **'Door or lock'**
  String get categoryDoorLock;

  /// No description provided for @categoryRoof.
  ///
  /// In en, this message translates to:
  /// **'Roof or ceiling'**
  String get categoryRoof;

  /// No description provided for @categoryAppliance.
  ///
  /// In en, this message translates to:
  /// **'Appliance'**
  String get categoryAppliance;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @repairLink.
  ///
  /// In en, this message translates to:
  /// **'Tenant repair link'**
  String get repairLink;

  /// No description provided for @repairLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'The tenant can report repairs with a photo here, without an app.'**
  String get repairLinkHelp;

  /// No description provided for @sendRepairLink.
  ///
  /// In en, this message translates to:
  /// **'Send by SMS'**
  String get sendRepairLink;

  /// No description provided for @shareRepairLink.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareRepairLink;

  /// No description provided for @resetRepairLink.
  ///
  /// In en, this message translates to:
  /// **'New link'**
  String get resetRepairLink;

  /// No description provided for @resetRepairLinkConfirm.
  ///
  /// In en, this message translates to:
  /// **'Make a new link? The old link will stop working.'**
  String get resetRepairLinkConfirm;

  /// No description provided for @repairLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Repair link sent to the tenant.'**
  String get repairLinkSent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
