import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../data/properties_repository.dart';

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final properties = ref.watch(propertiesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProperties)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addProperty(context, ref),
        icon: const Icon(Icons.add_home_work_outlined),
        label: Text(l10n.addProperty),
      ),
      body: properties.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(propertiesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyView(
              message: l10n.propertiesEmpty,
              icon: Icons.home_work_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(propertiesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = items[i];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.home_work_outlined),
                  ),
                  title: Text(p.name),
                  subtitle: Text(
                    [
                      if (p.location(l10n.woreda).isNotEmpty)
                        p.location(l10n.woreda),
                      l10n.unitsCount(p.unitsCount),
                      if (p.vacantUnitsCount > 0)
                        l10n.vacantCount(p.vacantUnitsCount),
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/properties/${p.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _addProperty(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController();
    final subCity = TextEditingController();
    final woreda = TextEditingController();
    final address = TextEditingController();

    final saved = await showFormSheet(
      context,
      FormSheet(
        title: l10n.addProperty,
        onSave: () => ref
            .read(propertiesRepositoryProvider)
            .create(
              name: name.text.trim(),
              subCity: subCity.text.trim(),
              woreda: woreda.text.trim(),
              address: address.text.trim(),
            ),
        fieldsBuilder: (context, errors) => [
          TextFormField(
            controller: name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.propertyName,
              hintText: l10n.propertyNameHint,
              errorText: errors['name'],
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          fieldGap,
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: subCity,
                  decoration: InputDecoration(
                    labelText: l10n.subCity,
                    errorText: errors['sub_city'],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: woreda,
                  decoration: InputDecoration(
                    labelText: l10n.woreda,
                    errorText: errors['woreda'],
                  ),
                ),
              ),
            ],
          ),
          fieldGap,
          TextFormField(
            controller: address,
            decoration: InputDecoration(
              labelText: l10n.address,
              errorText: errors['address'],
            ),
          ),
        ],
      ),
    );

    if (saved) ref.invalidate(propertiesProvider);
  }
}
