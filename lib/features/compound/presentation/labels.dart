import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/compound.dart';

extension MeterKindLabel on MeterKind {
  String label(AppLocalizations l10n) =>
      this == MeterKind.water ? l10n.kindWater : l10n.kindElectricity;
  IconData get icon =>
      this == MeterKind.water ? Icons.water_drop_outlined : Icons.bolt_outlined;
}

extension SplitMethodLabel on SplitMethod {
  String label(AppLocalizations l10n) => switch (this) {
    SplitMethod.equal => l10n.splitEqual,
    SplitMethod.percent => l10n.splitPercent,
    SplitMethod.submeter => l10n.splitSubmeter,
  };
}

extension AssetKindLabel on AssetKind {
  String label(AppLocalizations l10n) => switch (this) {
    AssetKind.generator => l10n.kindGenerator,
    AssetKind.waterTank => l10n.kindWaterTank,
    AssetKind.pump => l10n.kindPump,
    AssetKind.other => l10n.kindOther,
  };

  IconData get icon => switch (this) {
    AssetKind.generator => Icons.electrical_services,
    AssetKind.waterTank => Icons.propane_tank_outlined,
    AssetKind.pump => Icons.water_damage_outlined,
    AssetKind.other => Icons.build_circle_outlined,
  };
}
