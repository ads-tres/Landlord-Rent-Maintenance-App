import '../../../l10n/app_localizations.dart';

/// "Electricity" / "Water" for a utility charge from a shared meter bill.
String utilityLabel(AppLocalizations l10n, String? kind) =>
    kind == 'water' ? l10n.utilityWater : l10n.utilityElectricity;
