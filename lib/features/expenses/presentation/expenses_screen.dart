import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../payments/data/payments_repository.dart';
import '../../properties/data/properties_repository.dart';
import '../../repairs/presentation/repair_widgets.dart';
import '../data/expenses_repository.dart';
import '../domain/expense.dart';

/// What the landlord spent, newest first and grouped by month.
/// Opened from Home (all properties, with a filter) or from a property's menu.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key, this.propertyId});

  final int? propertyId;

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  late int? _propertyId = widget.propertyId;

  void _refresh() {
    ref.invalidate(expensesProvider);
    ref.invalidate(dashboardProvider);
  }

  Future<void> _add() async {
    final saved = await context.push<Expense>(
      _propertyId == null
          ? '/expenses/new'
          : '/expenses/new?propertyId=$_propertyId',
    );
    if (saved != null) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    final expenses = ref.watch(expensesProvider(_propertyId));
    final properties = widget.propertyId == null
        ? ref.watch(propertiesProvider).value ?? const []
        : const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenses)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addExpense'),
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(l10n.addExpense),
      ),
      body: Column(
        children: [
          if (properties.length > 1)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(l10n.allProperties),
                      selected: _propertyId == null,
                      onSelected: (_) => setState(() => _propertyId = null),
                    ),
                  ),
                  for (final p in properties)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p.name),
                        selected: _propertyId == p.id,
                        onSelected: (_) => setState(() => _propertyId = p.id),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: expenses.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(error: e, onRetry: _refresh),
              data: (list) {
                if (list.items.isEmpty) {
                  return EmptyView(
                    message: l10n.expensesEmpty,
                    icon: Icons.receipt_long_outlined,
                  );
                }
                final months = <String, List<Expense>>{};
                for (final e in list.items) {
                  months
                      .putIfAbsent(
                        DateFormat('yyyy-MM').format(e.spentOn),
                        () => [],
                      )
                      .add(e);
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(expensesProvider(_propertyId).future),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: [
                      ListTile(
                        title: Text(l10n.expensesTotal),
                        trailing: Text(
                          formatBirr(list.total, locale: locale),
                          key: const Key('expensesTotal'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      for (final MapEntry(key: month, value: items)
                          in months.entries) ...[
                        _MonthHeader(
                          label: dates.period(month),
                          total: formatBirr(
                            items.fold(0, (sum, e) => sum + e.amount),
                            locale: locale,
                          ),
                        ),
                        for (final e in items)
                          ListTile(
                            key: Key('expense-${e.id}'),
                            leading: Icon(e.category.icon),
                            title: Text(
                              e.description?.isNotEmpty == true
                                  ? e.description!
                                  : e.category.label(l10n),
                            ),
                            subtitle: Text(
                              [
                                dates.date(e.spentOn),
                                if (widget.propertyId == null &&
                                    e.propertyName != null)
                                  e.propertyName!,
                                if (e.unitLabel != null) e.unitLabel!,
                                if (e.isAutomatic) l10n.expenseAutomatic,
                              ].join(' · '),
                            ),
                            trailing: Text(
                              formatBirr(e.amount, locale: locale),
                            ),
                            onTap: () => _details(e),
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _details(Expense e) async {
    final l10n = AppLocalizations.of(context);
    final locale = ref.read(localeControllerProvider).languageCode;
    final dates = ref.read(appDatesProvider);
    final repo = ref.read(expensesRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatBirr(e.amount, locale: locale),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                [
                  e.category.label(l10n),
                  dates.date(e.spentOn),
                  if (e.propertyName != null) e.propertyName!,
                  if (e.unitLabel != null) e.unitLabel!,
                ].join(' · '),
              ),
              if (e.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(e.description!),
              ],
              if (e.vendor?.isNotEmpty == true)
                Text('${l10n.expenseVendor}: ${e.vendor}'),
              if (e.isAutomatic) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.expenseAutomaticHelp,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
              if (e.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final url in e.photoUrls)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 120,
                              child: AuthImage(url: url),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (e.photoUrls.length < 4)
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, 'photo'),
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(l10n.addReceiptPhoto),
                    ),
                  if (!e.isAutomatic)
                    TextButton.icon(
                      key: const Key('deleteExpense'),
                      onPressed: () => Navigator.pop(context, 'delete'),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.delete),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;

    try {
      if (action == 'photo') {
        final path = await pickRepairPhoto(context);
        if (path == null) return;
        await repo.addPhoto(e.id, path);
      } else if (action == 'delete') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(l10n.deleteExpenseConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                key: const Key('confirmDeleteExpense'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
        if (ok != true) return;
        await repo.delete(e.id);
      }
      _refresh();
    } on ApiException catch (err) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(friendlyError(context, err))),
        );
      }
    }
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label, required this.total});

  final String label;
  final String total;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall
        ?.copyWith(color: Theme.of(context).colorScheme.primary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(total, style: style),
        ],
      ),
    );
  }
}
