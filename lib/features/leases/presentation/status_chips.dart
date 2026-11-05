import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/charge.dart';

class ChargeStatusChip extends StatelessWidget {
  const ChargeStatusChip({super.key, required this.status});

  final ChargeStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (label, background, foreground) = switch (status) {
      ChargeStatus.paid => (
        l10n.statusPaid,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      ChargeStatus.partial => (
        l10n.statusPartial,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      ChargeStatus.late => (
        l10n.statusLate,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      ChargeStatus.due => (
        l10n.statusDue,
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    return Chip(
      label: Text(label, style: TextStyle(color: foreground)),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
