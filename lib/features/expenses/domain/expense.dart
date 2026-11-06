import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

enum ExpenseCategory {
  repair('repair', Icons.build_outlined),
  maintenance('maintenance', Icons.electrical_services),
  landLease('land_lease', Icons.landscape_outlined),
  utility('utility', Icons.bolt_outlined),
  tax('tax', Icons.account_balance_outlined),
  insurance('insurance', Icons.shield_outlined),
  securityCleaning('security_cleaning', Icons.cleaning_services_outlined),
  other('other', Icons.receipt_long_outlined);

  const ExpenseCategory(this.apiValue, this.icon);

  final String apiValue;
  final IconData icon;

  static ExpenseCategory parse(String? value) => values.firstWhere(
    (c) => c.apiValue == value,
    orElse: () => ExpenseCategory.other,
  );

  String label(AppLocalizations l10n) => switch (this) {
    repair => l10n.expenseRepair,
    maintenance => l10n.expenseMaintenance,
    landLease => l10n.expenseLandLease,
    utility => l10n.expenseUtility,
    tax => l10n.expenseTax,
    insurance => l10n.expenseInsurance,
    securityCleaning => l10n.expenseSecurityCleaning,
    other => l10n.expenseOther,
  };
}

/// Where an automatic expense came from.
enum ExpenseSource { repair, service, utilityBill }

/// Money spent on a property. Amounts in santim.
class Expense {
  const Expense({
    required this.id,
    required this.propertyId,
    required this.category,
    required this.amount,
    required this.spentOn,
    this.propertyName,
    this.unitId,
    this.unitLabel,
    this.description,
    this.vendor,
    this.source,
    this.sourceId,
    this.photoUrls = const [],
  });

  factory Expense.fromJson(Map<String, dynamic> j) {
    final source = j['source'] as Map<String, dynamic>?;
    return Expense(
      id: j['id'] as int,
      propertyId: j['property_id'] as int,
      propertyName: j['property_name'] as String?,
      unitId: j['unit_id'] as int?,
      unitLabel: j['unit_label'] as String?,
      category: ExpenseCategory.parse(j['category'] as String?),
      amount: j['amount'] as int,
      spentOn: DateTime.parse(j['spent_on'] as String),
      description: j['description'] as String?,
      vendor: j['vendor'] as String?,
      source: switch (source?['type']) {
        'repair' => ExpenseSource.repair,
        'service' => ExpenseSource.service,
        'utility_bill' => ExpenseSource.utilityBill,
        _ => null,
      },
      sourceId: source?['id'] as int?,
      photoUrls: [
        for (final p in j['photos'] as List<dynamic>? ?? [])
          (p as Map<String, dynamic>)['url'] as String,
      ],
    );
  }

  final int id;
  final int propertyId;
  final String? propertyName;
  final int? unitId;
  final String? unitLabel;
  final ExpenseCategory category;
  final int amount;
  final DateTime spentOn;
  final String? description;
  final String? vendor;
  final ExpenseSource? source;
  final int? sourceId;
  final List<String> photoUrls;

  /// Added from a repair, a service or a utility bill; changed there, not here.
  bool get isAutomatic => source != null;
}

typedef ExpenseList = ({List<Expense> items, int total});
