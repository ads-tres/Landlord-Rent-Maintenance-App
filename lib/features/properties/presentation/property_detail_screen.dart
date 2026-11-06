import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/locale_controller.dart';
import '../../../core/utils/money.dart';

import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../data/properties_repository.dart';
import '../domain/unit.dart';
import '../../auth/application/auth_controller.dart';

class PropertyDetailScreen extends ConsumerWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final int propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final property = ref.watch(propertyProvider(propertyId));
    final locale = ref.watch(localeControllerProvider).languageCode;
    final caretaker = ref.watch(isCaretakerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(property.value?.name ?? ''),
        actions: [
          PopupMenuButton<String>(
            key: const Key('propertyMenu'),
            onSelected: (route) =>
                context.push('/properties/$propertyId/$route'),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'meters',
                child: ListTile(
                  leading: const Icon(Icons.electric_meter_outlined),
                  title: Text(l10n.sharedMeters),
                ),
              ),
              PopupMenuItem(
                value: 'equipment',
                child: ListTile(
                  leading: const Icon(Icons.electrical_services),
                  title: Text(l10n.equipment),
                ),
              ),
              if (!caretaker)
                PopupMenuItem(
                  value: 'expenses',
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(l10n.expenses),
                  ),
                ),
              PopupMenuItem(
                value: 'announce',
                child: ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: Text(l10n.announce),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: caretaker
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addUnit(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.addUnit),
            ),
      body: property.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(propertyProvider(propertyId)),
        ),
        data: (p) => RefreshIndicator(
          onRefresh: () => ref.refresh(propertyProvider(propertyId).future),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (p.location(l10n.woreda).isNotEmpty ||
                  (p.address ?? '').isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(
                    p.location(l10n.woreda).isNotEmpty
                        ? p.location(l10n.woreda)
                        : p.address!,
                  ),
                  subtitle:
                      p.location(l10n.woreda).isNotEmpty &&
                          (p.address ?? '').isNotEmpty
                      ? Text(p.address!)
                      : null,
                ),
              const Divider(height: 1),
              if (p.units.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: EmptyView(
                    message: l10n.unitsEmpty,
                    icon: Icons.meeting_room_outlined,
                  ),
                )
              else
                for (final unit in p.units)
                  ListTile(
                    leading: IconButton(
                      key: Key('unitHistory-${unit.id}'),
                      tooltip: l10n.unitHistory,
                      icon: const Icon(Icons.history),
                      onPressed: () =>
                          context.push('/units/${unit.id}/history'),
                    ),
                    title: Text(unit.label),
                    subtitle: Text(
                      unit.activeLease != null
                          ? [
                              unit.activeLease!.tenantName ?? '',
                              formatBirr(
                                unit.activeLease!.monthlyRent,
                                locale: locale,
                              ),
                            ].join(' · ')
                          : l10n.unitVacantTapToLease,
                    ),
                    trailing: _StatusChip(status: unit.status),
                    onTap: () => unit.activeLease != null
                        ? context.push('/leases/${unit.activeLease!.id}')
                        : (caretaker
                              ? null
                              : _vacantUnitActions(context, ref, unit)),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addUnit(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final label = TextEditingController();
    final bedrooms = TextEditingController();

    final saved = await showFormSheet(
      context,
      FormSheet(
        title: l10n.addUnit,
        onSave: () => ref
            .read(propertiesRepositoryProvider)
            .addUnit(
              propertyId,
              label: label.text.trim(),
              bedrooms: int.tryParse(bedrooms.text),
            ),
        fieldsBuilder: (context, errors) => [
          TextFormField(
            controller: label,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.unitLabel,
              hintText: l10n.unitLabelHint,
              errorText: errors['label'],
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          fieldGap,
          TextFormField(
            controller: bedrooms,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.bedrooms,
              errorText: errors['bedrooms'],
            ),
          ),
        ],
      ),
    );

    if (saved) {
      ref.invalidate(propertyProvider(propertyId));
      ref.invalidate(propertiesProvider);
    }
  }

  Future<void> _vacantUnitActions(
    BuildContext context,
    WidgetRef ref,
    Unit unit,
  ) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.addLease),
              onTap: () => Navigator.pop(context, 'lease'),
            ),
            ListTile(
              key: const Key('listUnitAction'),
              leading: const Icon(Icons.campaign_outlined),
              title: Text(
                unit.openListingId != null ? l10n.viewListing : l10n.listUnit,
              ),
              onTap: () => Navigator.pop(context, 'listing'),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(l10n.unitHistory),
              onTap: () => Navigator.pop(context, 'history'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;

    if (choice == 'history') {
      await context.push('/units/${unit.id}/history');
    } else if (choice == 'lease') {
      context.push(
        Uri(
          path: '/leases/new',
          queryParameters: {
            'unitId': '${unit.id}',
            'unitLabel': unit.label,
            'propertyId': '$propertyId',
          },
        ).toString(),
      );
    } else if (unit.openListingId != null) {
      await context.push('/listings/${unit.openListingId}');
      ref.invalidate(propertyProvider(propertyId));
    } else {
      await context.push(
        '/listings/new?unitId=${unit.id}&unitLabel=${Uri.encodeQueryComponent(unit.label)}',
      );
      ref.invalidate(propertyProvider(propertyId));
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final UnitStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final vacant = status == UnitStatus.vacant;
    return Chip(
      label: Text(vacant ? l10n.statusVacant : l10n.statusOccupied),
      backgroundColor: vacant
          ? scheme.tertiaryContainer
          : scheme.secondaryContainer,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
