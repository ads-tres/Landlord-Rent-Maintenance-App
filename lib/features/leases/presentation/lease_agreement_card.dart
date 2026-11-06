import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../core/widgets/language_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../repairs/presentation/repair_widgets.dart';
import '../data/leases_repository.dart';
import '../domain/lease.dart';

/// The written lease: print the agreement, add extra terms, record the woreda
/// registration and keep photos of the signed copy.
class LeaseAgreementCard extends ConsumerWidget {
  const LeaseAgreementCard({
    super.key,
    required this.lease,
    required this.onChanged,
  });

  final Lease lease;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dates = ref.watch(appDatesProvider);
    final scheme = Theme.of(context).colorScheme;
    final registered = lease.registeredAt != null;

    return Card(
      key: const Key('leaseAgreementCard'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.leaseAgreement,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  registered ? Icons.verified_outlined : Icons.pending_outlined,
                  size: 18,
                  color: registered ? Colors.green : scheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    registered
                        ? [
                            l10n.registeredDate(
                              dates.date(lease.registeredAt!),
                            ),
                            if ((lease.registrationNumber ?? '').isNotEmpty)
                              l10n.registrationNo(lease.registrationNumber!),
                            if ((lease.registrationOffice ?? '').isNotEmpty)
                              lease.registrationOffice!,
                          ].join(' · ')
                        : l10n.notRegistered,
                    key: const Key('registrationStatus'),
                  ),
                ),
              ],
            ),
            if (lease.agreementBlanks.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                l10n.agreementBlanks(
                  lease.agreementBlanks
                      .map((b) => _blankLabel(l10n, b))
                      .join(', '),
                ),
                style: TextStyle(color: scheme.outline),
              ),
            ],
            if (lease.documentUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final url in lease.documentUrls)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 56,
                            child: AuthImage(url: url),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  key: const Key('agreementPdf'),
                  onPressed: () => _share(context, ref),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l10n.agreementPdf),
                ),
                TextButton.icon(
                  key: const Key('extraTerms'),
                  onPressed: () => _editTerms(context, ref),
                  icon: const Icon(Icons.rule),
                  label: Text(l10n.extraTerms),
                ),
                TextButton.icon(
                  key: const Key('recordRegistration'),
                  onPressed: () => _register(context, ref),
                  icon: const Icon(Icons.how_to_reg_outlined),
                  label: Text(
                    registered
                        ? l10n.editRegistration
                        : l10n.recordRegistration,
                  ),
                ),
                TextButton.icon(
                  key: const Key('addSignedCopy'),
                  onPressed: lease.documentUrls.length >= 10
                      ? null
                      : () => _addPhoto(context, ref),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(l10n.signedCopy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _blankLabel(AppLocalizations l10n, String field) =>
      switch (field) {
        'landlord_name' => l10n.missingLandlordName,
        'landlord_id_number' => l10n.missingLandlordIdNumber,
        'tenant_address' => l10n.missingTenantAddress,
        'tenant_id_number' => l10n.missingTenantIdNumber,
        'property_location' => l10n.missingPropertyLocation,
        'condition_notes' => l10n.missingConditionNotes,
        _ => field,
      };

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    String? done,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(friendlyError(context, e))),
        );
      }
    }
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final language = await pickDocumentLanguage(
      context,
      title: l10n.agreementLanguage,
      help: l10n.agreementLanguageHelp,
    );
    if (language == null || !context.mounted) return;
    await _run(context, () async {
      final path = await ref
          .read(leasesRepositoryProvider)
          .downloadAgreement(lease.id, language);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/pdf')],
          text: l10n.leaseAgreement,
        ),
      );
    });
  }

  Future<void> _editTerms(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final terms = TextEditingController(text: lease.extraTerms);
    final saved = await showFormSheet(
      context,
      FormSheet(
        title: l10n.extraTerms,
        onSave: () => ref
            .read(leasesRepositoryProvider)
            .setExtraTerms(lease.id, terms.text),
        fieldsBuilder: (context, errors) => [
          Text(l10n.extraTermsHelp),
          fieldGap,
          TextFormField(
            key: const Key('extraTermsField'),
            controller: terms,
            autofocus: true,
            minLines: 3,
            maxLines: 10,
            maxLength: 3000,
            decoration: InputDecoration(
              hintText: l10n.extraTermsHint,
              errorText: errors['extra_terms'],
            ),
          ),
        ],
      ),
    );
    if (saved) onChanged();
  }

  Future<void> _register(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final dates = ref.read(appDatesProvider);
    final repo = ref.read(leasesRepositoryProvider);
    final number = TextEditingController(text: lease.registrationNumber);
    final office = TextEditingController(text: lease.registrationOffice);
    var on = lease.registeredAt ?? dateOnly(DateTime.now());

    final saved = await showFormSheet(
      context,
      FormSheet(
        title: l10n.recordRegistration,
        onSave: () => repo.recordRegistration(
          lease.id,
          registeredAt: on,
          number: number.text,
          office: office.text,
        ),
        fieldsBuilder: (context, errors) => [
          StatefulBuilder(
            builder: (context, setState) => InkWell(
              key: const Key('registrationDate'),
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
                  labelText: l10n.registrationDate,
                  errorText: errors['registered_at'],
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(dates.date(on)),
              ),
            ),
          ),
          fieldGap,
          TextFormField(
            key: const Key('registrationNumberField'),
            controller: number,
            decoration: InputDecoration(
              labelText: l10n.registrationNumber,
              errorText: errors['registration_number'],
            ),
          ),
          fieldGap,
          TextFormField(
            controller: office,
            decoration: InputDecoration(
              labelText: l10n.registrationOffice,
              hintText: l10n.registrationOfficeHint,
              errorText: errors['registration_office'],
            ),
          ),
          if (lease.registeredAt != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('clearRegistration'),
                onPressed: () async {
                  Navigator.of(context).pop(false);
                  await repo.clearRegistration(lease.id);
                  onChanged();
                },
                child: Text(l10n.clearRegistration),
              ),
            ),
        ],
      ),
    );
    if (saved) onChanged();
  }

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final path = await pickRepairPhoto(context);
    if (path == null || !context.mounted) return;
    await _run(context, () async {
      await ref.read(leasesRepositoryProvider).addDocument(lease.id, path);
      onChanged();
    });
  }
}
