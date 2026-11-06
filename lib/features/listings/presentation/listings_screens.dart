import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/phone_number.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../properties/data/properties_repository.dart';
import '../../repairs/presentation/repair_widgets.dart'
    show AuthImage, pickRepairPhoto;
import '../data/listings_repository.dart';
import '../domain/listing.dart';

extension ListingStatusLabel on ListingStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ListingStatus.draft => l10n.listingDraft,
    ListingStatus.live => l10n.listingLive,
    ListingStatus.closed => l10n.listingClosed,
    ListingStatus.suspended => l10n.listingSuspended,
  };
}

extension ApplicationStatusLabel on ApplicationStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ApplicationStatus.newApp => l10n.appNew,
    ApplicationStatus.shortlisted => l10n.appShortlisted,
    ApplicationStatus.rejected => l10n.appRejected,
    ApplicationStatus.approved => l10n.appApproved,
  };
}

/// All of the landlord's listings.
class ListingsScreen extends ConsumerWidget {
  const ListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final listings = ref.watch(listingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.listings)),
      body: listings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(listingsProvider),
        ),
        data: (items) => items.isEmpty
            ? EmptyView(
                message: l10n.listingsEmpty,
                icon: Icons.campaign_outlined,
              )
            : ListView(
                children: [
                  for (final l in items)
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.campaign_outlined),
                      ),
                      title: Text(
                        [
                          l.unitLabel,
                          l.propertyName,
                        ].whereType<String>().join(' · '),
                      ),
                      subtitle: Text(
                        '${formatBirr(l.askingRent, locale: locale)} · ${l10n.applications}: ${l.applicationsCount}',
                      ),
                      trailing: Chip(
                        label: Text(l.status.label(l10n)),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                      ),
                      onTap: () async {
                        await context.push('/listings/${l.id}');
                        ref.invalidate(listingsProvider);
                      },
                    ),
                ],
              ),
      ),
    );
  }
}

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({
    super.key,
    required this.unitId,
    required this.unitLabel,
  });

  final int unitId;
  final String unitLabel;

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rent = TextEditingController();
  final _description = TextEditingController();
  DateTime _from = dateOnly(DateTime.now());
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _rent.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final listing = await ref
          .read(listingsRepositoryProvider)
          .create(
            widget.unitId,
            askingRent: parseBirr(_rent.text)!,
            availableFrom: _from,
            description: _description.text.trim(),
          );
      if (mounted) context.pushReplacement('/listings/${listing.id}');
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
    final dates = ref.watch(appDatesProvider);
    return Scaffold(
      appBar: AppBar(title: Text('${l10n.listUnit} · ${widget.unitLabel}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('askingRentField'),
              controller: _rent,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(labelText: l10n.askingRent),
              validator: (v) =>
                  (parseBirr(v ?? '') ?? 0) < 100 ? l10n.amountInvalid : null,
            ),
            fieldGap,
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _from,
                  firstDate: dateOnly(DateTime.now()),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _from = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.availableFrom,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(dates.date(_from)),
              ),
            ),
            fieldGap,
            TextFormField(
              controller: _description,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: l10n.listingDescription,
                hintText: l10n.listingDescriptionHint,
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('createListingButton'),
              onPressed: _saving ? null : _save,
              child: Text(l10n.createListing),
            ),
          ],
        ),
      ),
    );
  }
}

/// One listing: rent check, share text, photos, publish/close and applications.
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final int listingId;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      ref.invalidate(listingProvider(listingId));
      ref.invalidate(applicationsProvider(listingId));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.fieldErrors.values.firstOrNull ?? friendlyError(context, e),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    final listing = ref.watch(listingProvider(listingId));
    final repo = ref.read(listingsRepositoryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.listings)),
      body: listing.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(listingProvider(listingId)),
        ),
        data: (l) {
          final check = l.rentCheck;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        l.unitLabel,
                        l.propertyName,
                      ].whereType<String>().join(' · '),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Chip(
                    label: Text(l.status.label(l10n)),
                    side: BorderSide.none,
                  ),
                ],
              ),
              Text(
                formatBirr(l.askingRent, locale: locale),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('${l10n.availableFrom}: ${dates.date(l.availableFrom)}'),
              if (l.status == ListingStatus.live && l.expiresAt != null)
                Text(l10n.expiresOn(dates.date(l.expiresAt!))),
              if (l.reportCount > 0)
                Text(
                  l10n.listingReports(l.reportCount),
                  style: TextStyle(color: scheme.error),
                ),
              if ((l.description ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l.description!),
                ),
              if (check?.lastRent != null) ...[
                const SizedBox(height: 12),
                Card(
                  key: const Key('rentCheckCard'),
                  color: check!.exceeds
                      ? scheme.errorContainer
                      : scheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      check.exceeds
                          ? l10n.rentAboveCap(
                              formatBirr(check.lastRent!, locale: locale),
                              check.capPercent.toStringAsFixed(
                                check.capPercent % 1 == 0 ? 0 : 1,
                              ),
                              formatBirr(check.maxAllowed!, locale: locale),
                            )
                          : l10n.rentWithinCap(
                              formatBirr(check.lastRent!, locale: locale),
                              formatBirr(check.maxAllowed!, locale: locale),
                            ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final url in l.photos)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 110,
                            child: AuthImage(url: url),
                          ),
                        ),
                      ),
                    if (l.photos.length < 6 && l.status != ListingStatus.closed)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final path = await pickRepairPhoto(context);
                          if (path != null && context.mounted) {
                            await _run(
                              context,
                              ref,
                              () => repo.addPhoto(listingId, path),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: Text(l10n.addListingPhoto),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (l.status == ListingStatus.draft)
                FilledButton.icon(
                  key: const Key('publishButton'),
                  onPressed: () => _run(
                    context,
                    ref,
                    () => repo.setStatus(listingId, 'live'),
                  ),
                  icon: const Icon(Icons.public),
                  label: Text(l10n.publish),
                ),
              if (l.status == ListingStatus.live) ...[
                FilledButton.icon(
                  key: const Key('shareListingButton'),
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: [
                        l.shareText['am'],
                        l.shareText['en'],
                      ].whereType<String>().join('\n\n'),
                    ),
                  ),
                  icon: const Icon(Icons.share),
                  label: Text(l10n.shareListing),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: l.url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
                    }
                  },
                  icon: const Icon(Icons.link),
                  label: Text(l10n.copyLink),
                ),
              ],
              if (l.status == ListingStatus.live ||
                  l.status == ListingStatus.draft ||
                  l.status == ListingStatus.suspended)
                TextButton(
                  onPressed: () => _run(
                    context,
                    ref,
                    () => repo.setStatus(listingId, 'closed'),
                  ),
                  child: Text(l10n.closeListing),
                ),
              const Divider(height: 32),
              Text(
                l10n.applications,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _Applications(
                listingId: listingId,
                run: (a) => _run(context, ref, a),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Applications extends ConsumerWidget {
  const _Applications({required this.listingId, required this.run});

  final int listingId;
  final Future<void> Function(Future<void> Function()) run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dates = ref.watch(appDatesProvider);
    final apps = ref.watch(applicationsProvider(listingId));
    final repo = ref.read(listingsRepositoryProvider);

    return apps.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () => ref.invalidate(applicationsProvider(listingId)),
      ),
      data: (items) => items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l10n.applicationsEmpty),
            )
          : Column(
              children: [
                for (final a in items)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  a.fullName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              Chip(
                                label: Text(a.status.label(l10n)),
                                visualDensity: VisualDensity.compact,
                                side: BorderSide.none,
                              ),
                            ],
                          ),
                          Text(
                            [
                              formatEthiopianPhone(a.phone),
                              if (a.householdSize != null)
                                l10n.householdSize(a.householdSize!),
                              if (a.moveInDate != null)
                                l10n.moveInOn(dates.date(a.moveInDate!)),
                            ].join(' · '),
                          ),
                          if ((a.message ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(a.message!),
                            ),
                          Wrap(
                            spacing: 4,
                            children: [
                              TextButton.icon(
                                onPressed: () =>
                                    launchUrl(Uri.parse('tel:${a.phone}')),
                                icon: const Icon(Icons.call),
                                label: Text(l10n.call),
                              ),
                              if (a.status == ApplicationStatus.newApp)
                                TextButton(
                                  onPressed: () => run(
                                    () => repo.setApplicationStatus(
                                      a.id,
                                      ApplicationStatus.shortlisted,
                                    ),
                                  ),
                                  child: Text(l10n.shortlist),
                                ),
                              if (a.status == ApplicationStatus.newApp ||
                                  a.status ==
                                      ApplicationStatus.shortlisted) ...[
                                TextButton(
                                  onPressed: () => run(
                                    () => repo.setApplicationStatus(
                                      a.id,
                                      ApplicationStatus.rejected,
                                    ),
                                  ),
                                  child: Text(l10n.reject),
                                ),
                                FilledButton(
                                  key: Key('approve-${a.id}'),
                                  onPressed: () => _approve(context, ref, a),
                                  child: Text(l10n.approve),
                                ),
                              ],
                              if (a.status == ApplicationStatus.approved &&
                                  a.leaseId != null)
                                FilledButton.tonal(
                                  onPressed: () =>
                                      context.push('/leases/${a.leaseId}'),
                                  child: Text(l10n.leaseTitle),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    ListingApplication a,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.approveConfirm(a.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.approve),
          ),
        ],
      ),
    );
    if (ok != true) return;

    ListingApplication? approved;
    await run(
      () async => approved = await ref
          .read(listingsRepositoryProvider)
          .setApplicationStatus(a.id, ApplicationStatus.approved),
    );
    ref.invalidate(propertiesProvider);
    if (approved?.leaseId != null && context.mounted) {
      context.push('/leases/${approved!.leaseId}');
    }
  }
}
