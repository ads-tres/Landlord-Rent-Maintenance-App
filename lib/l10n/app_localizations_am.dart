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
  String get dashboardComingSoon =>
      'ውሎችና ክፍያዎች ሲጨመሩ የኪራይ ድምር፣ የዘገዩ ተከራዮች፣ ክፍት ጥገናዎች እና የሚያበቁ ውሎች እዚህ ይታያሉ።';

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
}
