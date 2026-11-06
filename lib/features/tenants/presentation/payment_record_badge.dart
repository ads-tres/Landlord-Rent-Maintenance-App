import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/tenant_record.dart';

extension PaymentRatingLabel on PaymentRating {
  String label(AppLocalizations l10n) => switch (this) {
    PaymentRating.good => l10n.ratingGood,
    PaymentRating.fair => l10n.ratingFair,
    PaymentRating.poor => l10n.ratingPoor,
    PaymentRating.newTenant => l10n.ratingNew,
  };

  Color color(ColorScheme scheme) => switch (this) {
    PaymentRating.good => Colors.green.shade700,
    PaymentRating.fair => Colors.orange.shade800,
    PaymentRating.poor => scheme.error,
    PaymentRating.newTenant => scheme.outline,
  };
}

/// "Good payer · 92% on time" — used on renewals, applications and the record screen.
class PaymentRecordBadge extends StatelessWidget {
  const PaymentRecordBadge({super.key, required this.record, this.prefix});

  final TenantRecord record;

  /// Put before the rating, e.g. "Rented before".
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = record.rating.color(Theme.of(context).colorScheme);
    return Row(
      children: [
        Icon(Icons.verified_user_outlined, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            [
              ?prefix,
              record.rating.label(l10n),
              if (record.rating != PaymentRating.newTenant)
                l10n.onTimePercent(record.percentLabel),
              if (record.averageDaysLate != null)
                l10n.averageDaysLate(record.averageDaysLate!.round()),
            ].join(' · '),
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
