// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appName => 'ኪራይ';

  @override
  String get loginTitle => 'በስልክዎ ይግቡ';

  @override
  String get loginSubtitle => 'ባለ 6 አሃዝ ኮድ በኤስኤምኤስ እንልክልዎታለን።';

  @override
  String get phoneLabel => 'ስልክ ቁጥር';

  @override
  String get phoneHint => '09XX XXX XXX';

  @override
  String get phoneInvalid => 'የኢትዮጵያ ሞባይል ቁጥር ያስገቡ፤ ለምሳሌ 0911 234 567።';

  @override
  String get sendCode => 'ኮድ ላክ';

  @override
  String get codeTitle => 'ኮዱን ያስገቡ';

  @override
  String codeSentTo(String phone) {
    return 'ወደ $phone ኮድ ልከናል።';
  }

  @override
  String get codeLabel => 'ባለ 6 አሃዝ ኮድ';

  @override
  String get codeInvalid => 'ባለ 6 አሃዙን ኮድ ያስገቡ።';

  @override
  String get verify => 'ግባ';

  @override
  String get resendCode => 'አዲስ ኮድ ላክ';

  @override
  String get changeNumber => 'ቁጥር ቀይር';

  @override
  String get navDashboard => 'መነሻ';

  @override
  String get navProperties => 'ንብረቶች';

  @override
  String get navTenants => 'ተከራዮች';

  @override
  String get navSettings => 'ቅንብሮች';

  @override
  String dashboardWelcome(String name) {
    return 'እንኳን ደህና መጡ፣ $name';
  }

  @override
  String get dashboardWelcomeNoName => 'እንኳን ደህና መጡ';

  @override
  String get dashboardProperties => 'ንብረቶች';

  @override
  String get dashboardUnits => 'ቤቶች';

  @override
  String get dashboardVacant => 'ባዶ';

  @override
  String get propertiesEmpty => 'እስካሁን ንብረት የለም። ለመጀመር ግቢዎን ወይም ሕንፃዎን ያክሉ።';

  @override
  String get addProperty => 'ንብረት ጨምር';

  @override
  String get propertyName => 'ስም';

  @override
  String get propertyNameHint => 'ለምሳሌ የቦሌ ግቢ';

  @override
  String get subCity => 'ክፍለ ከተማ';

  @override
  String get woreda => 'ወረዳ';

  @override
  String get address => 'አድራሻ';

  @override
  String unitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ቤቶች',
      one: '1 ቤት',
      zero: 'ቤት የለም',
    );
    return '$_temp0';
  }

  @override
  String vacantCount(int count) {
    return '$count ባዶ';
  }

  @override
  String get unitsEmpty => 'እስካሁን ቤት የለም። የሚያከራዩዋቸውን ክፍሎች ወይም አፓርታማዎች ያክሉ።';

  @override
  String get addUnit => 'ቤት ጨምር';

  @override
  String get unitLabel => 'መለያ';

  @override
  String get unitLabelHint => 'ለምሳሌ ክፍል 3 ወይም አፓርታማ 2B';

  @override
  String get bedrooms => 'መኝታ ክፍሎች';

  @override
  String get statusVacant => 'ባዶ';

  @override
  String get statusOccupied => 'ተከራይቷል';

  @override
  String get tenantsEmpty => 'እስካሁን ተከራይ የለም።';

  @override
  String get addTenant => 'ተከራይ ጨምር';

  @override
  String get searchTenants => 'በስም ወይም በስልክ ይፈልጉ';

  @override
  String get fullName => 'ሙሉ ስም';

  @override
  String get idNumber => 'የመታወቂያ ቁጥር (አማራጭ)';

  @override
  String get idNumberHelp => 'የውል ቅጹ ከፈለገው ብቻ።';

  @override
  String get privacyNoticeTitle => 'የግላዊነት ማሳሰቢያ';

  @override
  String get privacyNoticeBody =>
      'ለተከራዩ ይንገሩ፦ \"ስምዎ፣ ስልክዎ እና የውል መረጃዎ የኪራይ መዝገብ ለመያዝ ይቀመጣሉ። መረጃው በኢትዮጵያ ውስጥ ይቀመጣል፣ አከራይዎ ብቻ ያየዋል፣ እንዲታረም ወይም እንዲሰረዝ መጠየቅ ይችላሉ።\"';

  @override
  String get privacyNoticeConfirm => 'ስለዚህ ማሳሰቢያ ለተከራዩ ነግሬዋለሁ';

  @override
  String get privacyNoticeRequired => 'ተከራዩ ስለ ግላዊነት ማሳሰቢያው እንደተነገረው ያረጋግጡ።';

  @override
  String get save => 'አስቀምጥ';

  @override
  String get cancel => 'ተው';

  @override
  String get delete => 'ሰርዝ';

  @override
  String get retry => 'እንደገና ሞክር';

  @override
  String get required => 'ያስፈልጋል';

  @override
  String get genericError => 'ችግር ተፈጥሯል። እባክዎ እንደገና ይሞክሩ።';

  @override
  String get networkError => 'ግንኙነት የለም። ኢንተርኔትዎን አረጋግጠው እንደገና ይሞክሩ።';

  @override
  String get language => 'ቋንቋ';

  @override
  String get calendar => 'የቀን አቆጣጠር';

  @override
  String get calendarEthiopian => 'ኢትዮጵያ';

  @override
  String get calendarGregorian => 'ግሪጎሪያን';

  @override
  String get logout => 'ውጣ';

  @override
  String get disclaimer => 'የመዝገብ መያዣ መሳሪያ ነው እንጂ የሕግ ወይም የግብር ምክር አይደለም።';

  @override
  String get navRent => 'ኪራይ';

  @override
  String get currency => 'ብር';

  @override
  String get addLease => 'ውል ፍጠር';

  @override
  String get leaseTitle => 'ውል';

  @override
  String leaseFor(String unit) {
    return 'የ$unit ውል';
  }

  @override
  String get tenant => 'ተከራይ';

  @override
  String get selectTenant => 'ተከራይ ይምረጡ';

  @override
  String get newTenant => 'አዲስ ተከራይ';

  @override
  String get noTenantsYet => 'እስካሁን ተከራይ የለም። መጀመሪያ ተከራዩን ያክሉ።';

  @override
  String get startDate => 'የመጀመሪያ ቀን';

  @override
  String get endDate => 'የማብቂያ ቀን';

  @override
  String endDateHelp(int years) {
    return 'ውል ቢያንስ $years ዓመት ነው (የአዲስ አበባ መመሪያ)።';
  }

  @override
  String endDateTooEarly(String date) {
    return 'የማብቂያ ቀኑ $date ወይም ከዚያ በኋላ መሆን አለበት።';
  }

  @override
  String get monthlyRent => 'ወርሃዊ ኪራይ (ብር)';

  @override
  String get deposit => 'ማስያዣ (ብር)';

  @override
  String get dueDay => 'ኪራይ የሚከፈልበት ቀን';

  @override
  String get dueDayHelp => 'ኪራይ የሚከፈልበት የወሩ ቀን።';

  @override
  String get conditionNotes => 'የቤቱ ሁኔታ';

  @override
  String get conditionNotesHint => 'ግድግዳ፣ ወለል፣ እቃዎች፣ ቆጣሪዎች፣ የተሰጡ ቁልፎች…';

  @override
  String get registeredOn => 'በወረዳ የተመዘገበበት ቀን';

  @override
  String get notRegistered => 'ገና አልተመዘገበም';

  @override
  String get amountInvalid => 'መጠኑን በብር ያስገቡ።';

  @override
  String get leaseActive => 'የሚሰራ';

  @override
  String get leaseEnded => 'ያበቃ';

  @override
  String get leaseDraft => 'ረቂቅ';

  @override
  String endsIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'በ$days ቀናት ውስጥ ያበቃል',
      one: 'ነገ ያበቃል',
      zero: 'ዛሬ ያበቃል',
    );
    return '$_temp0';
  }

  @override
  String endedOn(String date) {
    return '$date ላይ አብቅቷል';
  }

  @override
  String missingLeaseFields(String fields) {
    return 'ለመመሪያው የጎደለ፦ $fields';
  }

  @override
  String get missingLandlordName => 'ስምዎ (ቅንብሮች)';

  @override
  String get missingTenantAddress => 'የተከራይ አድራሻ';

  @override
  String get missingConditionNotes => 'የቤቱ ሁኔታ';

  @override
  String get balanceCharged => 'የተጠየቀ';

  @override
  String get balancePaid => 'የተከፈለ';

  @override
  String get balanceOutstanding => 'ቀሪ';

  @override
  String get rentHistory => 'የኪራይ ለውጦች';

  @override
  String rentChangeLine(String from, String to, String date, String cap) {
    return '$from → $to ከ$date ጀምሮ (ጣሪያ $cap%)';
  }

  @override
  String get changeRent => 'ኪራይ ቀይር';

  @override
  String get newRent => 'አዲስ ወርሃዊ ኪራይ (ብር)';

  @override
  String get effectiveDate => 'ከዚህ ቀን ጀምሮ';

  @override
  String currentRent(String amount) {
    return 'የአሁኑ ኪራይ፦ $amount';
  }

  @override
  String aboveCap(String cap, String max) {
    return 'ከዓመታዊው $cap% ጣሪያ በላይ ነው። ከፍተኛው የሚፈቀደው $max ነው።';
  }

  @override
  String withinCap(String percent, String cap) {
    return 'የ$percent% ጭማሪ (ጣሪያ $cap%)።';
  }

  @override
  String get endLease => 'ውል አቋርጥ';

  @override
  String endLeaseConfirm(String date) {
    return 'ይህ ውል $date ላይ ይቋረጥ? ቤቱ ባዶ ይሆናል፣ ለቀጣይ ወራት ያልተከፈለ ኪራይ ይሰረዛል።';
  }

  @override
  String get endedOnLabel => 'የመጨረሻ ቀን';

  @override
  String get charges => 'የኪራይ መርሃ ግብር';

  @override
  String get chargesEmpty => 'ለዚህ ወር የሚከፈል ኪራይ የለም።';

  @override
  String get statusDue => 'የሚከፈል';

  @override
  String get statusPartial => 'በከፊል የተከፈለ';

  @override
  String get statusPaid => 'የተከፈለ';

  @override
  String get statusLate => 'የዘገየ';

  @override
  String daysLate(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ቀናት ዘግይቷል',
      one: '1 ቀን ዘግይቷል',
    );
    return '$_temp0';
  }

  @override
  String dueOn(String date) {
    return 'የሚከፈልበት $date';
  }

  @override
  String get filterAll => 'ሁሉም';

  @override
  String get filterUnpaid => 'ያልተከፈለ';

  @override
  String get monthTotalDue => 'በዚህ ወር የሚከፈል';

  @override
  String get monthCollected => 'የተሰበሰበ';

  @override
  String get monthOutstanding => 'ቀሪ';

  @override
  String get unitVacantTapToLease => 'ባዶ · ውል ለመፍጠር ይንኩ';

  @override
  String get confirm => 'አረጋግጥ';

  @override
  String get logPayment => 'ክፍያ መዝግብ';

  @override
  String get amountPaid => 'የተከፈለ መጠን (ብር)';

  @override
  String get paidOn => 'የተከፈለበት ቀን';

  @override
  String get paymentMethod => 'የክፍያ ዘዴ';

  @override
  String get methodCash => 'ጥሬ ገንዘብ';

  @override
  String get methodTelebirr => 'ቴሌብር';

  @override
  String get methodBank => 'ባንክ';

  @override
  String get methodChapa => 'ቻፓ';

  @override
  String get reference => 'የግብይት ማጣቀሻ ቁጥር';

  @override
  String get referenceHelp => 'ከቴሌብር ኤስኤምኤስ ወይም ከባንክ ደረሰኝ።';

  @override
  String get notes => 'ማስታወሻ (አማራጭ)';

  @override
  String quickBalance(String amount) {
    return 'ቀሪ $amount';
  }

  @override
  String quickMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ወራት',
      one: '1 ወር',
    );
    return '$_temp0';
  }

  @override
  String get paymentSaved => 'ክፍያው ተመዝግቧል';

  @override
  String paymentCovers(String months) {
    return 'የሚሸፍነው፦ $months';
  }

  @override
  String receiptNumber(String number) {
    return 'ደረሰኝ $number';
  }

  @override
  String get smsQueued => 'ደረሰኝ ለተከራዩ በኤስኤምኤስ ተልኳል።';

  @override
  String get shareReceipt => 'የደረሰኝ ሊንክ አጋራ';

  @override
  String get done => 'ጨርስ';

  @override
  String get payments => 'ክፍያዎች';

  @override
  String get paymentsEmpty => 'እስካሁን የተመዘገበ ክፍያ የለም።';

  @override
  String get removePayment => 'ክፍያውን ሰርዝ';

  @override
  String removePaymentConfirm(String amount) {
    return 'ይህ የ$amount ክፍያ ይሰረዝ? የሸፈናቸው ወራት እንደገና ያልተከፈሉ ይሆናሉ።';
  }

  @override
  String get dashboardCollected => 'በዚህ ወር የተሰበሰበ';

  @override
  String get dashboardOutstanding => 'ቀሪ ዕዳ';

  @override
  String get dashboardLateTenants => 'የዘገዩ ተከራዮች';

  @override
  String get dashboardOpenRepairs => 'ክፍት ጥገናዎች';

  @override
  String get dashboardLeasesEnding => 'በ60 ቀናት የሚያበቁ ውሎች';

  @override
  String dashboardDueThisMonth(String amount) {
    return 'በዚህ ወር የሚከፈል፦ $amount';
  }

  @override
  String get smsReminders => 'የኪራይ ማሳሰቢያ በኤስኤምኤስ';

  @override
  String get smsRemindersHelp => 'ከመክፈያ ቀኑ 3 ቀን በፊት እና በዕለቱ ለተከራዮች ይላካል።';

  @override
  String get navRepairs => 'ጥገና';

  @override
  String get repairsEmpty => 'እዚህ ጥገና የለም።';

  @override
  String get repairActive => 'ክፍት';

  @override
  String get repairOpen => 'አዲስ';

  @override
  String get repairInProgress => 'እየተሰራ';

  @override
  String get repairDone => 'የተጠናቀቀ';

  @override
  String get addRepair => 'ጥገና መዝግብ';

  @override
  String get repairTitle => 'የሚጠገነው';

  @override
  String get repairCategory => 'አይነት';

  @override
  String get repairDescription => 'ዝርዝር (አማራጭ)';

  @override
  String get repairUnit => 'ቤት';

  @override
  String get repairFromTenant => 'ከተከራይ';

  @override
  String repairOpenedOn(String date) {
    return 'የተገለጸበት $date';
  }

  @override
  String repairClosedOn(String date) {
    return 'የተጠናቀቀበት $date';
  }

  @override
  String get addPhoto => 'ፎቶ ጨምር';

  @override
  String get takePhoto => 'ካሜራ';

  @override
  String get choosePhoto => 'ጋለሪ';

  @override
  String get photos => 'ፎቶዎች';

  @override
  String get startRepair => 'ስራ ጀምር';

  @override
  String get finishRepair => 'ተጠናቋል በል';

  @override
  String get reopenRepair => 'እንደገና ክፈት';

  @override
  String get repairNote => 'ለተከራዩ ማስታወሻ (አማራጭ)';

  @override
  String get repairNoteHint => 'ለምሳሌ ቧንቧ ሰራተኛ 9 ሰዓት ይመጣል';

  @override
  String get notifyTenantSms => 'ለተከራዩ በኤስኤምኤስ አሳውቅ';

  @override
  String get categoryWater => 'የውሃ አቅርቦት';

  @override
  String get categoryElectric => 'መብራት / ኤሌክትሪክ';

  @override
  String get categoryPlumbing => 'ቧንቧ / መፍሰስ';

  @override
  String get categoryDoorLock => 'በር ወይም ቁልፍ';

  @override
  String get categoryRoof => 'ጣሪያ ወይም ኮርኒስ';

  @override
  String get categoryAppliance => 'የቤት እቃ';

  @override
  String get categoryOther => 'ሌላ';

  @override
  String get repairLink => 'የተከራይ የጥገና ሊንክ';

  @override
  String get repairLinkHelp => 'ተከራዩ ያለ መተግበሪያ ጥገናን ከፎቶ ጋር እዚህ ማሳወቅ ይችላል።';

  @override
  String get sendRepairLink => 'በኤስኤምኤስ ላክ';

  @override
  String get shareRepairLink => 'አጋራ';

  @override
  String get resetRepairLink => 'አዲስ ሊንክ';

  @override
  String get resetRepairLinkConfirm => 'አዲስ ሊንክ ይፈጠር? የድሮው ሊንክ መስራት ያቆማል።';

  @override
  String get repairLinkSent => 'የጥገና ሊንኩ ለተከራዩ ተልኳል።';

  @override
  String get reportTitle => 'የሩብ ዓመት ገቢ';

  @override
  String get reportOpen => 'የሩብ ዓመት የገቢ ሪፖርት';

  @override
  String get reportOpenHelp => 'ለግብር ማቅረቢያ በየሩብ ዓመቱ የተቀበሉት ኪራይ';

  @override
  String reportPayments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ክፍያዎች',
      one: '1 ክፍያ',
      zero: 'ምንም ክፍያ የለም',
    );
    return '$_temp0';
  }

  @override
  String get reportByMonth => 'በወር';

  @override
  String get reportByProperty => 'በንብረት';

  @override
  String get reportByMethod => 'በክፍያ ዘዴ';

  @override
  String get reportNone => 'በዚህ ሩብ ዓመት የተቀበሉት ኪራይ የለም።';

  @override
  String get reportSharePdf => 'PDF አጋራ';

  @override
  String get reportDisclaimer =>
      'በመተግበሪያው የተመዘገበ የተቀበሉት ኪራይ ነው። የግብር ስሌት አይደለም፤ የሚከፍሉትን ከሂሳብ ባለሙያ ወይም ከግብር ቢሮ ያረጋግጡ።';

  @override
  String get previousQuarter => 'ያለፈው ሩብ ዓመት';

  @override
  String get nextQuarter => 'የሚቀጥለው ሩብ ዓመት';

  @override
  String get offlineBanner => 'ግንኙነት የለም። የተቀመጠ መረጃ እያሳየ ነው።';

  @override
  String pendingPaymentsBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ክፍያዎች አልተላኩም',
      one: '1 ክፍያ አልተላከም',
    );
    return '$_temp0';
  }

  @override
  String get syncNow => 'አሁን ላክ';

  @override
  String get notSynced => 'አልተላከም';

  @override
  String get savedOffline => 'በዚህ ስልክ ላይ ተቀምጧል';

  @override
  String get savedOfflineHelp =>
      'ግንኙነት የለም። ክፍያው ኢንተርኔት ሲመለስ በራሱ ይላካል። የኤስኤምኤስ ደረሰኙም ያኔ ይላካል።';

  @override
  String syncFailed(String error) {
    return 'መላክ አልተቻለም፦ $error';
  }

  @override
  String get discardPending => 'ተው';

  @override
  String get discardPendingConfirm => 'ያልተላከውን ይህን ክፍያ ይተዉት?';

  @override
  String get tenantExport => 'መረጃ ላክ';

  @override
  String get tenantAnonymize => 'የግል መረጃ አስወግድ';

  @override
  String tenantAnonymizeConfirm(String name) {
    return 'የ$name ስም፣ ስልክ፣ የመታወቂያ ቁጥር፣ አድራሻ እና የጥገና ፎቶዎች ይወገዱ? የክፍያ መጠኖች በመዝገብዎ ይቆያሉ። ይህ ሊቀለበስ አይችልም።';
  }

  @override
  String get tenantAnonymized => 'የግል መረጃው ተወግዷል።';

  @override
  String get sendFeedback => 'አስተያየት ይላኩ';

  @override
  String get sendFeedbackHelp => 'የተበላሸውን ወይም የጎደለውን ይንገሩን';

  @override
  String appVersion(String version) {
    return 'ስሪት $version';
  }

  @override
  String get telegram => 'ቴሌግራም';

  @override
  String get telegramConnected => 'ተገናኝቷል፦ የጥገና ማሳወቂያዎች በቴሌግራም ይመጣሉ';

  @override
  String get telegramNotConnected => 'ተከራይ ጥገና ሲያሳውቅ ማሳወቂያ ያግኙ';

  @override
  String get telegramConnect => 'ቴሌግራም ያገናኙ';

  @override
  String get telegramDisconnect => 'ቴሌግራም ያላቅቁ';

  @override
  String get telegramDisconnectConfirm => 'የቴሌግራም የጥገና ማሳወቂያዎች ይቁሙ?';

  @override
  String get telegramOpenHint => 'ቴሌግራም ይከፈታል። ለማገናኘት Start ይንኩ።';

  @override
  String get tenantOnTelegram => 'መልዕክቶችን በቴሌግራም ይቀበላል';

  @override
  String get voiceNotes => 'የድምፅ መልዕክቶች';

  @override
  String voiceNote(int number) {
    return 'የድምፅ መልዕክት $number';
  }

  @override
  String get sendReceipt => 'ለተከራዩ ደረሰኝ ላክ';

  @override
  String get sendReceiptHelp => 'ካገናኙ በቴሌግራም፣ ካልሆነ በኤስኤምኤስ';
}
