import '../../../core/utils/dates.dart';

class StatementLine {
  const StatementLine({
    required this.date,
    required this.isPayment,
    required this.description,
    required this.amount,
    required this.balance,
  });

  factory StatementLine.fromJson(Map<String, dynamic> j) => StatementLine(
    date: parseYmd(j['date'] as String),
    isPayment: j['kind'] == 'payment',
    description: j['description'] as String,
    amount: (j['kind'] == 'payment' ? j['payment'] : j['charge']) as int,
    balance: j['balance'] as int,
  );

  final DateTime date;
  final bool isPayment;
  final String description;

  /// Santim charged or paid.
  final int amount;

  /// Running balance after this line: positive is owed, negative is paid ahead.
  final int balance;
}

/// `GET /leases/{id}/statement`. Amounts in santim.
class LeaseStatementData {
  const LeaseStatementData({
    required this.from,
    required this.to,
    required this.opening,
    required this.charged,
    required this.paid,
    required this.closing,
    required this.lines,
  });

  factory LeaseStatementData.fromJson(Map<String, dynamic> j) =>
      LeaseStatementData(
        from: parseYmd(j['from'] as String),
        to: parseYmd(j['to'] as String),
        opening: j['opening'] as int,
        charged: j['charged'] as int,
        paid: j['paid'] as int,
        closing: j['closing'] as int,
        lines: [
          for (final l in j['lines'] as List<dynamic>)
            StatementLine.fromJson(l as Map<String, dynamic>),
        ],
      );

  final DateTime from;
  final DateTime to;
  final int opening;
  final int charged;
  final int paid;
  final int closing;
  final List<StatementLine> lines;
}
