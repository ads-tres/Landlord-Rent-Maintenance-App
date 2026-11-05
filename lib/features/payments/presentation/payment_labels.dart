import '../../../l10n/app_localizations.dart';
import '../domain/payment.dart';

extension PaymentMethodLabel on PaymentMethod {
  String label(AppLocalizations l10n) => switch (this) {
    PaymentMethod.cash => l10n.methodCash,
    PaymentMethod.telebirr => l10n.methodTelebirr,
    PaymentMethod.bank => l10n.methodBank,
    PaymentMethod.chapa => l10n.methodChapa,
  };
}
