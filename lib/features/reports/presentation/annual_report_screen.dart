import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/reports_repository.dart';
import '../domain/annual_report.dart';

/// The year at a glance, month by month, with PDF and Excel to share.
class AnnualReportScreen extends ConsumerStatefulWidget {
  const AnnualReportScreen({super.key});

  @override
  ConsumerState<AnnualReportScreen> createState() => _AnnualReportScreenState();
}

class _AnnualReportScreenState extends ConsumerState<AnnualReportScreen> {
  int? _year;
  bool _sharing = false;

  Future<void> _share(AnnualReport r, String format) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sharing = true);
    try {
      final path = await ref
          .read(reportsRepositoryProvider)
          .downloadAnnual(r.year, format);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              path,
              mimeType: format == 'pdf' ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
          text: r.label,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(friendlyError(context, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final report = ref.watch(annualReportProvider(_year));
    String birr(int s) => formatBirr(s, locale: locale);
    final scheme = Theme.of(context).colorScheme;

    Widget line(String label, String value, {TextStyle? style, Key? key}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(label, style: style)),
              Text(value, key: key, style: style),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.annualSummary)),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(annualReportProvider(_year)),
        ),
        data: (r) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('previousYear'),
                  onPressed: () => setState(() => _year = r.year - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        r.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${r.fromDisplay} – ${r.toDisplay}',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('nextYear'),
                  onPressed: () => setState(() => _year = r.year + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    line(l10n.reportTotalReceived, birr(r.income)),
                    if (r.refunded > 0)
                      line(l10n.reportRefunded, '− ${birr(r.refunded)}'),
                    line(l10n.reportExpensesTotal, '− ${birr(r.expenses)}'),
                    const Divider(),
                    line(
                      l10n.reportNet,
                      birr(r.net),
                      key: const Key('annualNet'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    line(l10n.averageOccupancy, '${r.averageOccupancy}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final m in r.months)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m.label),
                subtitle: Text(
                  [
                    '${l10n.reportTotalReceived} ${birr(m.income)}',
                    if (m.refunded + m.expenses > 0)
                      '− ${birr(m.refunded + m.expenses)}',
                    l10n.occupancyShort(m.occupancy),
                  ].join(' · '),
                ),
                trailing: Text(
                  birr(m.net),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: m.net < 0 ? scheme.error : null,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('shareAnnualPdf'),
              onPressed: _sharing ? null : () => _share(r, 'pdf'),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(l10n.reportSharePdf),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('shareAnnualExcel'),
              onPressed: _sharing ? null : () => _share(r, 'xlsx'),
              icon: const Icon(Icons.table_chart_outlined),
              label: Text(l10n.reportShareExcel),
            ),
          ],
        ),
      ),
    );
  }
}
