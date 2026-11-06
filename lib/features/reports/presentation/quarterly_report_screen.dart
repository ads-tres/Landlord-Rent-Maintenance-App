import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/domain/expense.dart';
import '../../payments/domain/payment.dart';
import '../../payments/presentation/payment_labels.dart';
import '../data/reports_repository.dart';
import '../domain/quarterly_report.dart';

/// Rent received per quarter (Ethiopian fiscal or Gregorian quarters, per Settings),
/// with a PDF to share with an accountant or the tax office.
class QuarterlyReportScreen extends ConsumerStatefulWidget {
  const QuarterlyReportScreen({super.key});

  @override
  ConsumerState<QuarterlyReportScreen> createState() =>
      _QuarterlyReportScreenState();
}

class _QuarterlyReportScreenState extends ConsumerState<QuarterlyReportScreen> {
  QuarterKey _key = (year: null, quarter: null);
  bool _sharing = false;

  static const _xlsxMime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  Future<void> _share(QuarterlyReport r, {bool excel = false}) async {
    setState(() => _sharing = true);
    try {
      final repo = ref.read(reportsRepositoryProvider);
      final path = excel
          ? await repo.downloadExcel(year: r.year, quarter: r.quarter)
          : await repo.downloadPdf(year: r.year, quarter: r.quarter);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: excel ? _xlsxMime : 'application/pdf')],
          text: r.label,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(context, e))));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final report = ref.watch(quarterlyReportProvider(_key));
    String birr(int s) => formatBirr(s, locale: locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportTitle),
        actions: [
          TextButton.icon(
            key: const Key('openAnnual'),
            onPressed: () => context.push('/reports/annual'),
            icon: const Icon(Icons.calendar_view_month),
            label: Text(l10n.wholeYear),
          ),
        ],
      ),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(quarterlyReportProvider(_key)),
        ),
        data: (r) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('previousQuarter'),
                  tooltip: l10n.previousQuarter,
                  onPressed: () =>
                      setState(() => _key = previousQuarter(r.year, r.quarter)),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        r.label,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${r.fromDisplay} – ${r.toDisplay}',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('nextQuarter'),
                  tooltip: l10n.nextQuarter,
                  onPressed: () =>
                      setState(() => _key = nextQuarter(r.year, r.quarter)),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      birr(r.total),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(l10n.reportPayments(r.paymentsCount)),
                  ],
                ),
              ),
            ),
            if (r.paymentsCount == 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.reportNone, textAlign: TextAlign.center),
              )
            else ...[
              _Section(
                title: l10n.reportByMonth,
                rows: [
                  for (final m in r.byMonth) (m.label, birr(m.total), false),
                ],
              ),
              _Section(
                title: l10n.reportByProperty,
                rows: [
                  for (final p in r.byProperty) ...[
                    (p.property, birr(p.total), false),
                    for (final u in p.units) (u.unit, birr(u.total), true),
                  ],
                ],
              ),
              _Section(
                title: l10n.reportByMethod,
                rows: [
                  for (final m in r.byMethod)
                    (
                      PaymentMethod.parse(m.method).label(l10n),
                      birr(m.total),
                      false,
                    ),
                ],
              ),
            ],
            _Section(
              title: l10n.reportExpenses,
              rows: [
                if (r.expensesByCategory.isEmpty)
                  (l10n.reportNoExpenses, '', true),
                for (final c in r.expensesByCategory)
                  (
                    ExpenseCategory.parse(c.category).label(l10n),
                    birr(c.total),
                    false,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _Line(l10n.reportTotalReceived, birr(r.total)),
                    if (r.refunded > 0)
                      _Line(
                        l10n.reportRefunded,
                        '− ${birr(r.refunded)}',
                        key: const Key('reportRefunded'),
                      ),
                    _Line(
                      l10n.reportExpensesTotal,
                      '− ${birr(r.expensesTotal)}',
                    ),
                    const Divider(),
                    _Line(
                      l10n.reportNet,
                      birr(r.net),
                      key: const Key('reportNet'),
                      strong: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('sharePdf'),
              onPressed: _sharing ? null : () => _share(r),
              icon: _sharing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(l10n.reportSharePdf),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('shareExcel'),
              onPressed: _sharing ? null : () => _share(r, excel: true),
              icon: const Icon(Icons.table_chart_outlined),
              label: Text(l10n.reportShareExcel),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.reportShareExcelHelp,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.reportDisclaimer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reportExpensesNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.amount, {super.key, this.strong = false});

  final String label;
  final String amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = strong ? Theme.of(context).textTheme.titleMedium : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(amount, style: style),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;

  /// (label, amount, indented)
  final List<(String, String, bool)> rows;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: Theme.of(context).colorScheme.outline);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        for (final (label, amount, indented) in rows)
          Padding(
            padding: EdgeInsets.only(
              left: indented ? 16 : 0,
              top: 6,
              bottom: 6,
            ),
            child: Row(
              children: [
                Expanded(child: Text(label, style: indented ? muted : null)),
                Text(amount, style: indented ? muted : null),
              ],
            ),
          ),
      ],
    );
  }
}
