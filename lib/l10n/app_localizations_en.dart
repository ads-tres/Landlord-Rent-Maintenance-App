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

  @override
  String get navRepairs => 'Repairs';

  @override
  String get repairsEmpty => 'No repairs here.';

  @override
  String get repairActive => 'Active';

  @override
  String get repairOpen => 'New';

  @override
  String get repairInProgress => 'In progress';

  @override
  String get repairDone => 'Done';

  @override
  String get addRepair => 'Record repair';

  @override
  String get repairTitle => 'What needs fixing';

  @override
  String get repairCategory => 'Type';

  @override
  String get repairDescription => 'Details (optional)';

  @override
  String get repairUnit => 'Unit';

  @override
  String get repairFromTenant => 'From tenant';

  @override
  String repairOpenedOn(String date) {
    return 'Reported $date';
  }

  @override
  String repairClosedOn(String date) {
    return 'Done $date';
  }

  @override
  String get addPhoto => 'Add photo';

  @override
  String get takePhoto => 'Camera';

  @override
  String get choosePhoto => 'Gallery';

  @override
  String get photos => 'Photos';

  @override
  String get startRepair => 'Start work';

  @override
  String get finishRepair => 'Mark done';

  @override
  String get reopenRepair => 'Reopen';

  @override
  String get repairNote => 'Note for the tenant (optional)';

  @override
  String get repairNoteHint => 'e.g. Plumber coming at 3pm';

  @override
  String get notifyTenantSms => 'Text the tenant';

  @override
  String get categoryWater => 'Water supply';

  @override
  String get categoryElectric => 'Electricity';

  @override
  String get categoryPlumbing => 'Plumbing / leak';

  @override
  String get categoryDoorLock => 'Door or lock';

  @override
  String get categoryRoof => 'Roof or ceiling';

  @override
  String get categoryAppliance => 'Appliance';

  @override
  String get categoryOther => 'Other';

  @override
  String get repairLink => 'Tenant repair link';

  @override
  String get repairLinkHelp =>
      'The tenant can report repairs with a photo here, without an app.';

  @override
  String get sendRepairLink => 'Send by SMS';

  @override
  String get shareRepairLink => 'Share';

  @override
  String get resetRepairLink => 'New link';

  @override
  String get resetRepairLinkConfirm =>
      'Make a new link? The old link will stop working.';

  @override
  String get repairLinkSent => 'Repair link sent to the tenant.';

  @override
  String get reportTitle => 'Quarterly income';

  @override
  String get reportOpen => 'Quarterly income report';

  @override
  String get reportOpenHelp => 'Rent received per quarter, for tax filing';

  @override
  String reportPayments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments',
      one: '1 payment',
      zero: 'No payments',
    );
    return '$_temp0';
  }

  @override
  String get reportByMonth => 'By month';

  @override
  String get reportByProperty => 'By property';

  @override
  String get reportByMethod => 'By payment method';

  @override
  String get reportNone => 'No rent received in this quarter.';

  @override
  String get reportSharePdf => 'Share PDF';

  @override
  String get reportDisclaimer =>
      'Rent received as recorded in the app. This is not a tax calculation; confirm what you owe with an accountant or the tax office.';

  @override
  String get previousQuarter => 'Previous quarter';

  @override
  String get nextQuarter => 'Next quarter';

  @override
  String get offlineBanner => 'No connection. Showing saved data.';

  @override
  String pendingPaymentsBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments not synced',
      one: '1 payment not synced',
    );
    return '$_temp0';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String get notSynced => 'Not synced';

  @override
  String get savedOffline => 'Saved on this phone';

  @override
  String get savedOfflineHelp =>
      'There is no connection. The payment will be sent automatically when you are back online. The SMS receipt goes out then.';

  @override
  String syncFailed(String error) {
    return 'Could not sync: $error';
  }

  @override
  String get discardPending => 'Discard';

  @override
  String get discardPendingConfirm =>
      'Discard this payment that was never sent?';

  @override
  String get tenantExport => 'Export data';

  @override
  String get tenantAnonymize => 'Remove personal data';

  @override
  String tenantAnonymizeConfirm(String name) {
    return 'Remove $name\'s name, phone, ID number, address and repair photos? Payment amounts stay in your records. This cannot be undone.';
  }

  @override
  String get tenantAnonymized => 'Personal data removed.';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get sendFeedbackHelp => 'Tell us what broke or what is missing';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get telegram => 'Telegram';

  @override
  String get telegramConnected => 'Connected: repair alerts come to Telegram';

  @override
  String get telegramNotConnected =>
      'Get an alert when a tenant reports a repair';

  @override
  String get telegramConnect => 'Connect Telegram';

  @override
  String get telegramDisconnect => 'Disconnect Telegram';

  @override
  String get telegramDisconnectConfirm => 'Stop repair alerts on Telegram?';

  @override
  String get telegramOpenHint =>
      'Telegram opens. Tap Start to finish connecting.';

  @override
  String get tenantOnTelegram => 'Gets messages on Telegram';

  @override
  String get voiceNotes => 'Voice notes';

  @override
  String voiceNote(int number) {
    return 'Voice note $number';
  }

  @override
  String get sendReceipt => 'Send receipt to the tenant';

  @override
  String get sendReceiptHelp =>
      'On Telegram if they connected, otherwise by SMS';

  @override
  String get sharedMeters => 'Shared meters';

  @override
  String get sharedMetersEmpty =>
      'No shared meters. Add one to split a water or electricity bill across units.';

  @override
  String get addMeter => 'Add meter';

  @override
  String get meterName => 'Meter name';

  @override
  String get meterNameHint => 'e.g. Main electricity';

  @override
  String get meterKind => 'Type';

  @override
  String get kindElectricity => 'Electricity';

  @override
  String get kindWater => 'Water';

  @override
  String get splitMethod => 'How to split the bill';

  @override
  String get splitEqual => 'Equal shares';

  @override
  String get splitPercent => 'Fixed percentages';

  @override
  String get splitSubmeter => 'Sub-meter readings';

  @override
  String get meterUnits => 'Units on this meter';

  @override
  String get sharePercent => 'Share %';

  @override
  String sharesTotal(String total) {
    return 'Total: $total% (must be 100%)';
  }

  @override
  String get selectUnits => 'Select at least one unit.';

  @override
  String get bills => 'Bills';

  @override
  String get billsEmpty => 'No bills entered yet.';

  @override
  String get enterBill => 'Enter bill';

  @override
  String get billMonth => 'Bill for';

  @override
  String get billAmount => 'Bill amount (Br)';

  @override
  String get billDueDate => 'Tenants pay by';

  @override
  String get readings => 'Readings';

  @override
  String get previousReading => 'Previous';

  @override
  String get currentReading => 'Current';

  @override
  String get billPhoto => 'Photo of the bill';

  @override
  String get notifyTenants => 'Tell tenants their share';

  @override
  String get previewSplit => 'Preview split';

  @override
  String get splitResult => 'Split';

  @override
  String landlordShare(String amount) {
    return 'Your share (vacant units): $amount';
  }

  @override
  String get vacant => 'vacant';

  @override
  String get saveBill => 'Save bill';

  @override
  String get billSaved =>
      'Bill saved. Each tenant\'s share was added to their rent.';

  @override
  String get removeBill => 'Remove bill';

  @override
  String get equipment => 'Equipment';

  @override
  String get equipmentEmpty =>
      'No equipment yet. Add the generator, water tank or pump to get service reminders.';

  @override
  String get addEquipment => 'Add equipment';

  @override
  String get equipmentKind => 'Type';

  @override
  String get kindGenerator => 'Generator';

  @override
  String get kindWaterTank => 'Water tank';

  @override
  String get kindPump => 'Pump';

  @override
  String get kindOther => 'Other';

  @override
  String get equipmentName => 'Name';

  @override
  String get serviceEveryDays => 'Service every (days)';

  @override
  String get lastServiced => 'Last serviced';

  @override
  String get neverServiced => 'Not serviced yet';

  @override
  String nextService(String date) {
    return 'Next service $date';
  }

  @override
  String get serviceOverdue => 'Service overdue';

  @override
  String serviceDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Service due in $days days',
      one: 'Service due tomorrow',
      zero: 'Service due today',
    );
    return '$_temp0';
  }

  @override
  String get logService => 'Log service';

  @override
  String get servicedOn => 'Serviced on';

  @override
  String get serviceCost => 'Cost (Br, optional)';

  @override
  String get serviceNotes => 'What was done (optional)';

  @override
  String get dashboardServicesDue => 'Services due';

  @override
  String get announce => 'Send announcement';

  @override
  String get announcement => 'Message to all tenants';

  @override
  String get announcementHint => 'e.g. No water tomorrow from 8 to 12.';

  @override
  String get announcementPreview => 'Check before sending';

  @override
  String announcementRecipients(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tenants',
      one: '1 tenant',
    );
    return '$_temp0';
  }

  @override
  String announcementChannels(int telegram, int sms) {
    return '$telegram on Telegram (free) · $sms by SMS';
  }

  @override
  String announcementSms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count SMS',
      one: '1 SMS',
      zero: 'No SMS',
    );
    return '$_temp0';
  }

  @override
  String announcementCost(String amount) {
    return 'About $amount';
  }

  @override
  String get announcementSend => 'Send to all';

  @override
  String get announcementSent => 'Announcement sent.';

  @override
  String get announcementHistory => 'Sent before';

  @override
  String get utilityElectricity => 'Electricity';

  @override
  String get utilityWater => 'Water';

  @override
  String get listings => 'Listings';

  @override
  String get listingsEmpty =>
      'No listings yet. Open a vacant unit and choose “List this unit”.';

  @override
  String get listUnit => 'List this unit';

  @override
  String get viewListing => 'View listing';

  @override
  String get askingRent => 'Asking rent (Br)';

  @override
  String get availableFrom => 'Available from';

  @override
  String get listingDescription => 'Description (optional)';

  @override
  String get listingDescriptionHint =>
      'e.g. Sunny, water tank, near the main road';

  @override
  String get createListing => 'Create listing';

  @override
  String get listingDraft => 'Draft';

  @override
  String get listingLive => 'Live';

  @override
  String get listingClosed => 'Closed';

  @override
  String get listingSuspended => 'Suspended';

  @override
  String get publish => 'Publish for 30 days';

  @override
  String get closeListing => 'Close listing';

  @override
  String get shareListing => 'Share listing';

  @override
  String get copyLink => 'Copy link';

  @override
  String get linkCopied => 'Link copied.';

  @override
  String expiresOn(String date) {
    return 'Open until $date';
  }

  @override
  String rentAboveCap(String last, String cap, String max) {
    return 'Above the allowed rent: the last rent was $last, and the most allowed after the $cap% cap is $max. Under the rent law a new tenant\'s rent should match the renewal rent.';
  }

  @override
  String rentWithinCap(String last, String max) {
    return 'Last rent $last; up to $max is within the yearly cap.';
  }

  @override
  String get applications => 'Applications';

  @override
  String get applicationsEmpty =>
      'No applications yet. Share the listing to get some.';

  @override
  String get appNew => 'New';

  @override
  String get appShortlisted => 'Shortlisted';

  @override
  String get appRejected => 'Not chosen';

  @override
  String get appApproved => 'Approved';

  @override
  String householdSize(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String moveInOn(String date) {
    return 'Move in $date';
  }

  @override
  String get call => 'Call';

  @override
  String get shortlist => 'Shortlist';

  @override
  String get reject => 'Reject';

  @override
  String get approve => 'Approve';

  @override
  String approveConfirm(String name) {
    return 'Approve $name? This creates the tenant and a draft lease, closes the listing, and texts the other applicants that someone else was chosen.';
  }

  @override
  String get leaseDraftBanner =>
      'Draft lease from an approved application. Add the property condition and activate it to start rent.';

  @override
  String get activateLease => 'Activate lease';

  @override
  String listingReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reported $count times',
      one: 'Reported once',
    );
    return '$_temp0';
  }

  @override
  String get addListingPhoto => 'Add photo';

  @override
  String get onlineRent => 'Online rent (Chapa)';

  @override
  String get onlineRentHelp =>
      'Tenants pay with Telebirr, CBE Birr or bank; money goes to your bank account.';

  @override
  String get onlineRentOn => 'On: tenants can pay online';

  @override
  String get onlineRentOff => 'Off';

  @override
  String get payoutAccount => 'Payout bank account';

  @override
  String get bank => 'Bank';

  @override
  String get accountName => 'Account holder name';

  @override
  String get accountNumber => 'Account number';

  @override
  String get saveAccount => 'Save bank account';

  @override
  String get accountActive => 'Active';

  @override
  String get accountPending => 'Setting up…';

  @override
  String get accountFailed =>
      'Chapa could not set up this account. Check the details.';

  @override
  String get acceptOnlineRent => 'Accept online rent';

  @override
  String onlineRentFee(String fee) {
    return 'Each online payment: our fee of $fee and Chapa\'s fee (about 1.5%) are taken before the rest reaches your bank.';
  }

  @override
  String get payLink => 'Tenant pay link';

  @override
  String get payLinkHelp =>
      'The tenant can pay rent online here. It is also added to rent reminders.';

  @override
  String get sendPayLink => 'Send by SMS';

  @override
  String get payLinkSent => 'Pay link sent to the tenant.';

  @override
  String get paidOnline => 'Online';

  @override
  String get expenses => 'Expenses';

  @override
  String get addExpense => 'Add expense';

  @override
  String get allProperties => 'All properties';

  @override
  String get expensesEmpty =>
      'No expenses yet. Record what you spend on repairs, land lease, utilities and more; repair and service costs are added for you.';

  @override
  String get expensesTotal => 'Total';

  @override
  String get expenseAutomatic => 'Automatic';

  @override
  String get expenseAutomaticHelp =>
      'Added automatically from a repair, an equipment service or a shared meter bill. Change it there.';

  @override
  String get expenseVendor => 'Paid to';

  @override
  String get expenseVendorOptional => 'Paid to (optional)';

  @override
  String get addReceiptPhoto => 'Receipt photo';

  @override
  String get deleteExpenseConfirm => 'Delete this expense?';

  @override
  String get expenseProperty => 'Property';

  @override
  String get expenseUnit => 'Unit';

  @override
  String get expenseWholeProperty => 'Whole property';

  @override
  String get expenseCategory => 'Type';

  @override
  String get expenseAmount => 'Amount (Br)';

  @override
  String get expenseDate => 'Date paid';

  @override
  String get expenseDescription => 'What for';

  @override
  String get expenseDescriptionHint => 'e.g. New water pump';

  @override
  String get expenseRepair => 'Repairs';

  @override
  String get expenseMaintenance => 'Equipment service';

  @override
  String get expenseLandLease => 'Land lease';

  @override
  String get expenseUtility => 'Utilities';

  @override
  String get expenseTax => 'Taxes and fees';

  @override
  String get expenseInsurance => 'Insurance';

  @override
  String get expenseSecurityCleaning => 'Guard and cleaning';

  @override
  String get expenseOther => 'Other';

  @override
  String get dashboardExpenses => 'Spent this month';

  @override
  String get repairCost => 'Cost (Br, optional)';

  @override
  String get repairCostHelp => 'Recorded as an expense';

  @override
  String get repairCostRecorded => 'Repair cost, recorded as an expense';

  @override
  String get reportExpenses => 'Expenses';

  @override
  String get reportNoExpenses => 'No expenses recorded';

  @override
  String get reportTotalReceived => 'Rent received';

  @override
  String get reportExpensesTotal => 'Expenses';

  @override
  String get reportNet => 'Net';

  @override
  String get reportExpensesNote =>
      'Expenses are what you recorded in the app. Ask your accountant which ones are deductible.';

  @override
  String get moveOut => 'Move out';

  @override
  String get moveOutInProgress => 'Move-out in progress';

  @override
  String get settleMoveOut => 'Settle deposit and end lease';

  @override
  String get settleMoveOutConfirm => 'Settle';

  @override
  String settleRefundLine(String amount) {
    return 'Refund to the tenant: $amount';
  }

  @override
  String get settleNoRefund =>
      'Nothing to refund: the deposit is used up by the deductions.';

  @override
  String moveOutBalanceOwed(String amount) {
    return 'The tenant will still owe $amount.';
  }

  @override
  String get settleEndsLease =>
      'This ends the lease, marks the unit vacant and can\'t be undone.';

  @override
  String get refundReference => 'Refund reference (optional)';

  @override
  String get sendStatementToTenant => 'Send the statement to the tenant';

  @override
  String get moveOutCondition => 'Condition check';

  @override
  String get movedOutOn => 'Move-out date';

  @override
  String get keysReturned => 'Keys returned';

  @override
  String get conditionNotesEmpty =>
      'Add notes on the condition (walls, floors, meters…)';

  @override
  String get deductions => 'Deductions';

  @override
  String get addDeduction => 'Add';

  @override
  String get noDeductions => 'No deductions. The whole deposit is refunded.';

  @override
  String get deductionKind => 'Type';

  @override
  String get deductionDescription => 'What for';

  @override
  String get deductionDescriptionHint => 'e.g. Repaint bedroom wall';

  @override
  String get deductionUnpaidRent => 'Unpaid rent';

  @override
  String get deductionUnpaidUtility => 'Unpaid utility share';

  @override
  String get deductionDamage => 'Damage';

  @override
  String get deductionCleaning => 'Cleaning';

  @override
  String get deductionKeys => 'Keys';

  @override
  String get deductionOther => 'Other';

  @override
  String get depositHeld => 'Deposit held';

  @override
  String get refund => 'Refund';

  @override
  String get stillOwed => 'Still owed';

  @override
  String get moveOutSettled => 'Settled. The lease has ended.';

  @override
  String refundedBy(String method) {
    return 'Refunded by $method';
  }

  @override
  String get depositStatement => 'Deposit statement';

  @override
  String get shareStatement => 'Share statement (PDF)';

  @override
  String get statementSent => 'Statement sent to the tenant.';

  @override
  String get methodDeposit => 'From deposit';

  @override
  String get tenantPage => 'Tenant page';

  @override
  String get tenantPageHelp =>
      'The tenant\'s own page: balance, receipts, repairs and announcements. No app needed.';

  @override
  String get tenantPageSent => 'Link sent to the tenant.';

  @override
  String get sendToTenant => 'Send';

  @override
  String get share => 'Share';

  @override
  String get copy => 'Copy';

  @override
  String get resetLink => 'New link';

  @override
  String get resetTenantPageConfirm =>
      'Make a new link? The old one will stop working.';

  @override
  String get team => 'Team';

  @override
  String get teamHelp => 'Caretakers who log payments and handle repairs';

  @override
  String get addCaretaker => 'Add caretaker';

  @override
  String get sendInvite => 'Send invite';

  @override
  String get caretakerName => 'Name';

  @override
  String get inviteHelp =>
      'They get an SMS telling them to install the app and log in with this number.';

  @override
  String get caretakerCan =>
      'Caretakers can log payments, handle repairs, enter meter bills and send announcements. They can\'t see reports or expenses, change money settings, or create, end or delete leases and properties.';

  @override
  String get teamEmpty => 'No caretakers yet.';

  @override
  String get caretakerJoined => 'Active';

  @override
  String get caretakerInvited => 'Invited, not logged in yet';

  @override
  String get removeCaretaker => 'Remove';

  @override
  String removeCaretakerConfirm(String name) {
    return 'Remove $name? They will be signed out and can\'t log in again unless you add them back.';
  }

  @override
  String workingFor(String name) {
    return 'Caretaker for $name';
  }

  @override
  String get caretakerHelp => 'Some actions are only for the landlord.';

  @override
  String loggedBy(String name) {
    return 'Logged by $name';
  }

  @override
  String handledBy(String name) {
    return 'Handled by $name';
  }

  @override
  String get onlyLandlordSettles =>
      'Only the landlord can settle the deposit and end the lease.';

  @override
  String get renewLease => 'Renew lease';

  @override
  String renewLeaseHelp(int days) {
    return 'Ends in $days days. Extend it to a new end date.';
  }

  @override
  String get renew => 'Renew';

  @override
  String currentEnd(String date) {
    return 'Current end: $date';
  }

  @override
  String get newEndDate => 'New end date';

  @override
  String rentFrom(String date) {
    return 'Monthly rent from $date (Br)';
  }

  @override
  String maxRentHint(String amount, String cap) {
    return 'Up to $amount ($cap% yearly limit)';
  }

  @override
  String get leaseRenewed => 'Lease renewed';

  @override
  String leaseRenewedBody(String date, String rent) {
    return 'Now ends $date. Rent: $rent. Print the addendum, sign it with the tenant and register it with the woreda.';
  }

  @override
  String get renewalAddendum => 'Renewal addendum';

  @override
  String get close => 'Close';

  @override
  String get leasesEnding => 'Leases ending soon';

  @override
  String get leasesEndingEmpty => 'No leases end in the next 60 days.';

  @override
  String get aboveYearlyLimit => 'Above the yearly limit.';

  @override
  String get reportShareExcel => 'Share Excel for accountant';

  @override
  String get reportShareExcelHelp =>
      'Every payment and expense, a rent roll and a summary, in a spreadsheet.';

  @override
  String get pushNotifications => 'Notifications';

  @override
  String get pushNotificationsHelp =>
      'New repairs, payments and lease reminders on this phone';

  @override
  String get open => 'Open';

  @override
  String get arrears => 'Late rent';

  @override
  String get arrearsEmpty => 'Nobody is behind on rent.';

  @override
  String daysOverdue(int days) {
    return '$days days overdue';
  }

  @override
  String monthsBehind(int count) {
    return '$count months behind';
  }

  @override
  String nextStep(String step) {
    return 'Next step: $step';
  }

  @override
  String get onPaymentPlan => 'On a payment plan';

  @override
  String get arrearsCleared => 'All caught up';

  @override
  String get arrearsReminder => 'Friendly reminder';

  @override
  String get arrearsNotice => 'Firm notice';

  @override
  String get arrearsDemandLetter => 'Demand letter';

  @override
  String get arrearsPlan => 'Payment plan';

  @override
  String get arrearsNote => 'Note';

  @override
  String get arrearsReminderHelp =>
      'A polite SMS with the amount and their tenant page, asking them to pay or call to agree a date.';

  @override
  String get arrearsNoticeHelp =>
      'An SMS asking them to pay within 7 days or agree a payment plan.';

  @override
  String get arrearsDemandLetterHelp =>
      'A formal letter (PDF) listing each unpaid month with a 15-day deadline, to print and deliver.';

  @override
  String get arrearsSent => 'Sent to the tenant.';

  @override
  String get arrearsHistory => 'History';

  @override
  String get arrearsNoHistory => 'Nothing done yet.';

  @override
  String get arrearsNoteHint => 'e.g. Called, will pay on Friday';

  @override
  String get send => 'Send';

  @override
  String get agreePlan => 'Agree plan';

  @override
  String planIntro(String amount) {
    return 'Split $amount into monthly instalments. The tenant is reminded the day before each one.';
  }

  @override
  String get instalments => 'Instalments';

  @override
  String get firstInstalment => 'First instalment';

  @override
  String planProgress(String paid, String total) {
    return 'Plan: $paid of $total paid';
  }

  @override
  String get cancelPlan => 'Cancel plan';

  @override
  String get cancelPlanConfirm => 'Cancel this payment plan?';

  @override
  String get no => 'No';

  @override
  String get leaseAgreement => 'Lease agreement';

  @override
  String registrationNo(String number) {
    return 'No. $number';
  }

  @override
  String agreementBlanks(String fields) {
    return 'Left blank to fill in by hand: $fields';
  }

  @override
  String get missingTenantIdNumber => 'tenant ID number';

  @override
  String get missingPropertyLocation => 'property location';

  @override
  String get agreementPdf => 'Agreement PDF';

  @override
  String get extraTerms => 'Extra terms';

  @override
  String get editRegistration => 'Edit registration';

  @override
  String get recordRegistration => 'Record registration';

  @override
  String get signedCopy => 'Signed copy';

  @override
  String get agreementLanguage => 'Language of the agreement';

  @override
  String get agreementLanguageHelp =>
      'Both puts the English under each Amharic clause.';

  @override
  String get bothLanguages => 'Amharic and English';

  @override
  String get extraTermsHelp =>
      'Added to the agreement as its own clause, for example house rules.';

  @override
  String get extraTermsHint =>
      'e.g. No pets. Quiet after 10 pm. Rubbish out on Tuesdays.';

  @override
  String get registrationDate => 'Date registered';

  @override
  String get registrationNumber => 'Registration number (optional)';

  @override
  String get registrationOffice => 'Office (optional)';

  @override
  String get registrationOfficeHint => 'e.g. Bole Woreda 03';

  @override
  String get clearRegistration => 'Remove registration';

  @override
  String get leasesToRegister => 'Leases to register';

  @override
  String get leasesToRegisterEmpty => 'All active leases are registered.';

  @override
  String startedOn(String date) {
    return 'Started $date';
  }

  @override
  String unregisteredBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leases aren\'t registered yet',
      one: '1 lease isn\'t registered yet',
    );
    return '$_temp0';
  }

  @override
  String get unregisteredBannerHelp =>
      'Print the agreement, sign it and register it with the woreda.';

  @override
  String registeredDate(String date) {
    return 'Registered $date';
  }

  @override
  String get pasteSms => 'Paste payment SMS';

  @override
  String get pasteSmsHelp =>
      'Copy the Telebirr or bank confirmation message, then paste it here. The amount, reference and date are filled in for you to check.';

  @override
  String get pasteSmsHint => 'Paste the SMS here';

  @override
  String get pasteFromClipboard => 'Paste';

  @override
  String get smsNoAmount =>
      'No amount found in this message. Check that you copied the whole SMS.';

  @override
  String get smsFrom => 'From';

  @override
  String get useSms => 'Use these details';

  @override
  String get smsFilled =>
      'Filled in from the SMS. Check the details before saving.';

  @override
  String smsOtherPayer(String payer, String tenant) {
    return 'This message seems to be from $payer, not $tenant. Check before saving.';
  }

  @override
  String get smsPickLease => 'Which tenant is this payment from?';

  @override
  String get smsLikely => 'Likely';

  @override
  String get smsNoLeases => 'No active leases.';

  @override
  String get statement => 'Statement of account';

  @override
  String get wholeLease => 'Whole lease';

  @override
  String get thisYear => 'This year';

  @override
  String get last3Months => 'Last 3 months';

  @override
  String get customRange => 'Choose dates';

  @override
  String get openingBalance => 'Brought forward';

  @override
  String get totalCharged => 'Charged';

  @override
  String get totalPaid => 'Paid';

  @override
  String get closingBalance => 'Balance';

  @override
  String balanceOwed(String amount) {
    return '$amount owed';
  }

  @override
  String balanceAhead(String amount) {
    return '$amount paid ahead';
  }

  @override
  String get statementEmpty => 'Nothing charged or paid in this period.';

  @override
  String get shareStatementPdf => 'Share statement (PDF)';

  @override
  String get getStarted => 'Get started';

  @override
  String get getStartedHelp =>
      'A few steps to start collecting rent with the app.';

  @override
  String stepsDone(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get setupComplete => 'All set up. Well done!';

  @override
  String get hide => 'Hide';

  @override
  String get optional => 'optional';

  @override
  String get setupProfileTitle => 'Add your name';

  @override
  String get setupProfileHelp =>
      'It goes on receipts, agreements and messages to tenants.';

  @override
  String get yourFullName => 'Your full name';

  @override
  String get yourFullNameHelp => 'As tenants know you, e.g. Abel Kebede';

  @override
  String get setupPropertyTitle => 'Add your property';

  @override
  String get setupPropertyHelp =>
      'The compound or building, with its sub-city and woreda.';

  @override
  String get setupUnitsTitle => 'Add the rooms or apartments';

  @override
  String get setupUnitsHelp =>
      'Open the property and add each unit you rent out.';

  @override
  String get setupTenantTitle => 'Add a tenant';

  @override
  String get setupTenantHelp =>
      'Name and phone number; they get receipts by SMS or Telegram.';

  @override
  String get setupLeaseTitle => 'Add a lease';

  @override
  String get setupLeaseHelp =>
      'Open a property and tap a vacant unit to add the lease. Rent is then charged every month.';

  @override
  String get setupPaymentTitle => 'Log a payment';

  @override
  String get setupPaymentHelp =>
      'From the Rent tab, or paste a Telebirr or bank SMS. The tenant gets a receipt.';

  @override
  String get setupTenantPageTitle => 'Send a tenant their page';

  @override
  String get setupTenantPageHelp =>
      'Open a lease and send the tenant page: balance, receipts and repairs, no app needed.';

  @override
  String get setupTelegramTitle => 'Connect Telegram';

  @override
  String get setupTelegramHelp =>
      'Get repair and payment alerts on Telegram for free.';

  @override
  String get setupCaretakerTitle => 'Invite a caretaker';

  @override
  String get setupCaretakerHelp =>
      'Someone on site who logs payments and handles repairs.';

  @override
  String get documentDetails => 'Details for documents';

  @override
  String get documentDetailsHelp =>
      'Your name, ID number and address, printed on lease agreements and letters.';

  @override
  String get documentDetailsMissing =>
      'Add your ID number and address so agreements don\'t print blanks.';

  @override
  String get idNumberLabel => 'ID number (kebele ID or Fayda)';

  @override
  String get idNumberPrivate =>
      'Kept encrypted; only printed on your documents.';

  @override
  String get addressLabel => 'Your address';

  @override
  String get addressHint => 'e.g. Bole, Woreda 03, house 55';

  @override
  String get missingLandlordIdNumber => 'your ID number (Settings)';

  @override
  String get prepaidRent => 'Rent paid ahead (after move-out)';

  @override
  String get reportRefunded => 'Rent refunded';

  @override
  String get messages => 'Messages';

  @override
  String get rentReminders => 'Rent reminders';

  @override
  String get rentRemindersHelp =>
      'Reminders before and on the due day. Receipts and notices are always sent.';

  @override
  String get quietHoursNote =>
      'Nothing is sent between 9 pm and 7 am; those messages go out at 7 am.';

  @override
  String get noMessages => 'No messages sent yet.';

  @override
  String get messageSent => 'Sent';

  @override
  String get messageFailed => 'Failed';

  @override
  String get messageQueued => 'Sending';

  @override
  String messageScheduled(String time) {
    return 'At $time';
  }

  @override
  String get remindersOff => 'Reminders off';

  @override
  String get annualSummary => 'Annual summary';

  @override
  String get averageOccupancy => 'Average occupancy';

  @override
  String occupancyShort(int percent) {
    return '$percent% let';
  }

  @override
  String get wholeYear => 'Year';
}
