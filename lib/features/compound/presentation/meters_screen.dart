import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../properties/data/properties_repository.dart';
import '../data/compound_repository.dart';
import '../domain/compound.dart';
import 'labels.dart';

/// Shared water and electricity meters of a property.
class MetersScreen extends ConsumerWidget {
  const MetersScreen({super.key, required this.propertyId});

  final int propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    final meters = ref.watch(metersProvider(propertyId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sharedMeters)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<Meter>(
            MaterialPageRoute(
              builder: (_) => AddMeterScreen(propertyId: propertyId),
            ),
          );
          if (created != null) ref.invalidate(metersProvider(propertyId));
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addMeter),
      ),
      body: meters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(metersProvider(propertyId)),
        ),
        data: (items) => items.isEmpty
            ? EmptyView(
                message: l10n.sharedMetersEmpty,
                icon: Icons.electric_meter_outlined,
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  for (final m in items)
                    ListTile(
                      leading: CircleAvatar(child: Icon(m.kind.icon)),
                      title: Text(m.name),
                      subtitle: Text(
                        [
                          m.splitMethod.label(l10n),
                          m.units.map((u) => u.label).join(', '),
                          if (m.lastBillPeriod != null)
                            '${dates.period(m.lastBillPeriod!)}: ${formatBirr(m.lastBillAmount ?? 0, locale: locale)}',
                        ].join('\n'),
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/meters/${m.id}'),
                    ),
                ],
              ),
      ),
    );
  }
}

class AddMeterScreen extends ConsumerStatefulWidget {
  const AddMeterScreen({super.key, required this.propertyId});

  final int propertyId;

  @override
  ConsumerState<AddMeterScreen> createState() => _AddMeterScreenState();
}

class _AddMeterScreenState extends ConsumerState<AddMeterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  MeterKind _kind = MeterKind.electricity;
  SplitMethod _method = SplitMethod.equal;
  final Set<int> _selected = {};
  final Map<int, TextEditingController> _shares = {};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    for (final c in _shares.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _total => _selected.fold(
    0.0,
    (s, id) => s + (double.tryParse(_shares[id]?.text ?? '') ?? 0),
  );

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_selected.isEmpty) {
      setState(() => _error = l10n.selectUnits);
      return;
    }
    if (_method == SplitMethod.percent && (_total - 100).abs() > 0.01) {
      setState(() => _error = l10n.sharesTotal(_total.toStringAsFixed(1)));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final meter = await ref
          .read(compoundRepositoryProvider)
          .createMeter(
            widget.propertyId,
            name: _name.text.trim(),
            kind: _kind,
            method: _method,
            units: {
              for (final id in _selected)
                id: _method == SplitMethod.percent
                    ? double.tryParse(_shares[id]?.text ?? '')
                    : null,
            },
          );
      if (mounted) Navigator.of(context).pop(meter);
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error =
              e.fieldErrors.values.firstOrNull ?? friendlyError(context, e),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final property = ref.watch(propertyProvider(widget.propertyId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addMeter)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('meterNameField'),
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.meterName,
                hintText: l10n.meterNameHint,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.required : null,
            ),
            fieldGap,
            SegmentedButton<MeterKind>(
              segments: [
                for (final k in MeterKind.values)
                  ButtonSegment(
                    value: k,
                    icon: Icon(k.icon),
                    label: Text(k.label(l10n)),
                  ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            fieldGap,
            DropdownButtonFormField<SplitMethod>(
              initialValue: _method,
              decoration: InputDecoration(labelText: l10n.splitMethod),
              items: [
                for (final m in SplitMethod.values)
                  DropdownMenuItem(value: m, child: Text(m.label(l10n))),
              ],
              onChanged: (v) => setState(() => _method = v ?? _method),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.meterUnits,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            property.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(propertyProvider(widget.propertyId)),
              ),
              data: (p) => Column(
                children: [
                  for (final u in p.units)
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _selected.contains(u.id),
                            title: Text(u.label),
                            onChanged: (v) => setState(
                              () => v == true
                                  ? _selected.add(u.id)
                                  : _selected.remove(u.id),
                            ),
                          ),
                        ),
                        if (_method == SplitMethod.percent &&
                            _selected.contains(u.id))
                          SizedBox(
                            width: 90,
                            child: TextField(
                              controller: _shares.putIfAbsent(
                                u.id,
                                TextEditingController.new,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              decoration: InputDecoration(
                                labelText: l10n.sharePercent,
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            if (_method == SplitMethod.percent)
              Text(
                l10n.sharesTotal(_total.toStringAsFixed(1)),
                style: TextStyle(
                  color: (_total - 100).abs() > 0.01
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('saveMeterButton'),
              onPressed: _saving ? null : _save,
              child: Text(l10n.addMeter),
            ),
          ],
        ),
      ),
    );
  }
}
