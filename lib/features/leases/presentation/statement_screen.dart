import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/leases_repository.dart';
import '../domain/statement.dart';

/// Which part of the lease the statement covers.
enum StatementRange { wholeLease, thisYear, last3Months, custom }

typedef _Query = ({int leaseId, DateTime? from, DateTime? to});

final _statementProvider = FutureProvider.autoDispose
    .family<LeaseStatementData, _Query>(
      (ref, q) => ref
          .watch(leasesRepositoryProvider)
          .statement(q.leaseId, from: q.from, to: q.to),
    );

/// Every charge and payment on a lease with a running balance, to check or share.
class StatementScreen extends ConsumerStatefulWidget {
  const StatementScreen({super.key, required this.leaseId});

  final int leaseId;

  @override
  ConsumerState<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends ConsumerState<StatementScreen> {
  StatementRange _range = StatementRange.wholeLease;
  DateTimeRange? _custom;
  bool _sharing = false;

  _Query get _query {
    final today = dateOnly(DateTime.now());
    return switch (_range) {
      StatementRange.wholeLease => (
        leaseId: widget.leaseId,
        from: null,
        to: null,
      ),
      StatementRange.thisYear => (
        leaseId: widget.leaseId,
        from: DateTime(today.year),
        to: today,
      ),
      StatementRange.last3Months => (
        leaseId: widget.leaseId,
        from: DateTime(today.year, today.month - 3, today.day),
        to: today,
      ),
      StatementRange.custom => (
        leaseId: widget.leaseId,
        from: _custom?.start,
        to: _custom?.end,
      ),
    };
  }

  String _balance(AppLocalizations l10n, int santim, String locale) =>
      santim > 0
      ? l10n.balanceOwed(formatBirr(santim, locale: locale))
      : santim < 0
      ? l10n.balanceAhead(formatBirr(-santim, locale: locale))
      : formatBirr(0, locale: locale);

  Future<void> _pickCustom() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      initialDateRange: _custom,
    );
    if (picked != null) {
      setState(() {
        _custom = picked;
        _range = StatementRange.custom;
      });
    }
  }

  Future<void> _share(LeaseStatementData s) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final language = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (code, label) in [('am', 'አማርኛ'), ('en', 'English')])
              ListTile(
                key: Key('statementLanguage-$code'),
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(label),
                onTap: () => Navigator.pop(context, code),
              ),
          ],
        ),
      ),
    );
    if (language == null || !mounted) return;
    setState(() => _sharing = true);
    try {
      final path = await ref
          .read(leasesRepositoryProvider)
          .downloadStatement(
            widget.leaseId,
            from: s.from,
            to: s.to,
            language: language,
          );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/pdf')],
          text: l10n.statement,
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
    final dates = ref.watch(appDatesProvider);
    final statement = ref.watch(_statementProvider(_query));
    final scheme = Theme.of(context).colorScheme;

    final ranges = {
      StatementRange.wholeLease: l10n.wholeLease,
      StatementRange.thisYear: l10n.thisYear,
      StatementRange.last3Months: l10n.last3Months,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statement)),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final MapEntry(key: range, value: label) in ranges.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _range == range,
                      onSelected: (_) => setState(() => _range = range),
                    ),
                  ),
                ChoiceChip(
                  key: const Key('customRange'),
                  label: Text(
                    _range == StatementRange.custom && _custom != null
                        ? '${dates.date(_custom!.start)} – ${dates.date(_custom!.end)}'
                        : l10n.customRange,
                  ),
                  selected: _range == StatementRange.custom,
                  onSelected: (_) => _pickCustom(),
                ),
              ],
            ),
          ),
          Expanded(
            child: statement.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(_statementProvider(_query)),
              ),
              data: (s) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  Text('${dates.date(s.from)} – ${dates.date(s.to)}'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _row(
                            l10n.openingBalance,
                            _balance(l10n, s.opening, locale),
                          ),
                          _row(
                            l10n.totalCharged,
                            formatBirr(s.charged, locale: locale),
                          ),
                          _row(
                            l10n.totalPaid,
                            formatBirr(s.paid, locale: locale),
                          ),
                          const Divider(),
                          _row(
                            l10n.closingBalance,
                            _balance(l10n, s.closing, locale),
                            key: const Key('closingBalance'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: s.closing > 0 ? scheme.error : null,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (s.lines.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.statementEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final line in s.lines)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        line.isPayment ? Icons.south_west : Icons.north_east,
                        color: line.isPayment ? Colors.green : scheme.outline,
                      ),
                      title: Text(line.description),
                      subtitle: Text(
                        '${dates.date(line.date)} · ${_balance(l10n, line.balance, locale)}',
                      ),
                      trailing: Text(
                        '${line.isPayment ? '−' : '+'}${formatBirr(line.amount, locale: locale)}',
                        style: TextStyle(
                          color: line.isPayment ? Colors.green.shade700 : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('shareStatement'),
                    onPressed: _sharing ? null : () => _share(s),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(l10n.shareStatementPdf),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Key? key, TextStyle? style}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            Text(value, key: key, style: style),
          ],
        ),
      );
}
