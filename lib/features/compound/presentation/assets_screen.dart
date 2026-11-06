import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_dates.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../payments/data/payments_repository.dart';
import '../data/compound_repository.dart';
import '../domain/compound.dart';
import 'labels.dart';

/// Generator, water tank and pump services. With [propertyId] null it shows what is
/// due within a week across all properties (from the home screen).
class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key, this.propertyId});

  final int? propertyId;

  void _refresh(WidgetRef ref) {
    ref.invalidate(assetsProvider(propertyId));
    ref.invalidate(assetsProvider(null));
    ref.invalidate(dashboardProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dates = ref.watch(appDatesProvider);
    final assets = ref.watch(assetsProvider(propertyId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          propertyId == null ? l10n.dashboardServicesDue : l10n.equipment,
        ),
      ),
      floatingActionButton: propertyId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                if (await _addAsset(context, ref)) _refresh(ref);
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addEquipment),
            ),
      body: assets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => _refresh(ref)),
        data: (items) => items.isEmpty
            ? EmptyView(
                message: l10n.equipmentEmpty,
                icon: Icons.electrical_services,
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  for (final a in items)
                    ListTile(
                      leading: CircleAvatar(child: Icon(a.kind.icon)),
                      title: Text(a.name),
                      subtitle: Text(
                        [
                          if (a.propertyName != null && propertyId == null)
                            a.propertyName!,
                          a.lastServicedOn == null
                              ? l10n.neverServiced
                              : '${l10n.lastServiced}: ${dates.date(a.lastServicedOn!)}',
                          if (a.nextServiceOn != null)
                            l10n.nextService(dates.date(a.nextServiceOn!)),
                        ].join('\n'),
                      ),
                      isThreeLine: true,
                      trailing: Chip(
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                        backgroundColor: a.overdue
                            ? scheme.errorContainer
                            : (a.daysUntilService ?? 99) <= 7
                            ? scheme.tertiaryContainer
                            : scheme.surfaceContainerHighest,
                        label: Text(
                          a.overdue
                              ? l10n.serviceOverdue
                              : l10n.serviceDueIn(a.daysUntilService ?? 0),
                        ),
                      ),
                      onTap: () async {
                        if (await _logService(context, ref, a)) _refresh(ref);
                      },
                    ),
                ],
              ),
      ),
    );
  }

  Future<bool> _addAsset(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController();
    final interval = TextEditingController(text: '90');
    var kind = AssetKind.generator;
    DateTime? last;

    return showFormSheet(
      context,
      FormSheet(
        title: l10n.addEquipment,
        onSave: () => ref
            .read(compoundRepositoryProvider)
            .createAsset(
              propertyId!,
              kind: kind,
              name: name.text.trim().isEmpty
                  ? kind.label(l10n)
                  : name.text.trim(),
              intervalDays: int.parse(interval.text),
              lastServicedOn: last,
            ),
        fieldsBuilder: (context, errors) => [
          StatefulBuilder(
            builder: (context, setState) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<AssetKind>(
                  initialValue: kind,
                  decoration: InputDecoration(labelText: l10n.equipmentKind),
                  items: [
                    for (final k in AssetKind.values)
                      DropdownMenuItem(
                        value: k,
                        child: Row(
                          children: [
                            Icon(k.icon, size: 20),
                            const SizedBox(width: 8),
                            Text(k.label(l10n)),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => kind = v ?? kind),
                ),
                fieldGap,
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: l10n.equipmentName,
                    hintText: kind.label(l10n),
                    errorText: errors['name'],
                  ),
                ),
                fieldGap,
                TextFormField(
                  controller: interval,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.serviceEveryDays,
                    errorText: errors['service_interval_days'],
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return n == null || n < 7 || n > 730 ? l10n.required : null;
                  },
                ),
                fieldGap,
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: last ?? DateTime.now(),
                      firstDate: DateTime(2015),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => last = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.lastServiced,
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      last == null
                          ? l10n.neverServiced
                          : ref.read(appDatesProvider).date(last!),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _logService(BuildContext context, WidgetRef ref, Asset asset) {
    final l10n = AppLocalizations.of(context);
    final cost = TextEditingController();
    final notes = TextEditingController();
    var on = dateOnly(DateTime.now());

    return showFormSheet(
      context,
      FormSheet(
        title: '${l10n.logService} · ${asset.name}',
        onSave: () => ref
            .read(compoundRepositoryProvider)
            .logService(
              asset.id,
              servicedOn: on,
              cost: parseBirr(cost.text),
              notes: notes.text.trim(),
            ),
        fieldsBuilder: (context, errors) => [
          StatefulBuilder(
            builder: (context, setState) => InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: on,
                  firstDate: DateTime(2015),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => on = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.servicedOn,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(ref.read(appDatesProvider).date(on)),
              ),
            ),
          ),
          fieldGap,
          TextFormField(
            controller: cost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: l10n.serviceCost,
              errorText: errors['cost'],
            ),
          ),
          fieldGap,
          TextFormField(
            controller: notes,
            decoration: InputDecoration(labelText: l10n.serviceNotes),
          ),
        ],
      ),
    );
  }
}
