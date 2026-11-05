import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
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

  Future<void> _share(QuarterlyReport r) async {
    setState(() => _sharing = true);
    try {
      final path = await ref
          .read(reportsRepositoryProvider)
          .downloadPdf(year: r.year, quarter: r.quarter);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/pdf')],
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
      appBar: AppBar(title: Text(l10n.reportTitle)),
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
            const SizedBox(height: 12),
            Text(
              l10n.reportDisclaimer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
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
