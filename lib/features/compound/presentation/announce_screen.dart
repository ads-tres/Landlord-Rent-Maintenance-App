import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/compound_repository.dart';
import '../domain/compound.dart';

/// One message to every current tenant of a property. The landlord sees how many go
/// free on Telegram and how many SMS it costs before sending.
class AnnounceScreen extends ConsumerStatefulWidget {
  const AnnounceScreen({super.key, required this.propertyId});

  final int propertyId;

  @override
  ConsumerState<AnnounceScreen> createState() => _AnnounceScreenState();
}

class _AnnounceScreenState extends ConsumerState<AnnounceScreen> {
  final _body = TextEditingController();
  AnnouncementPreview? _preview;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_body.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final p = await ref
          .read(compoundRepositoryProvider)
          .previewAnnouncement(widget.propertyId, _body.text.trim());
      if (mounted) setState(() => _preview = p);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(compoundRepositoryProvider)
          .sendAnnouncement(widget.propertyId, _body.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).announcementSent)),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final p = _preview;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.announce)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('announcementField'),
            controller: _body,
            maxLength: 300,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => setState(() => _preview = null),
            decoration: InputDecoration(
              labelText: l10n.announcement,
              hintText: l10n.announcementHint,
              alignLabelWithHint: true,
            ),
          ),
          if (p != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.announcementRecipients(p.recipients),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(l10n.announcementChannels(p.telegram, p.sms)),
                    Text(
                      [
                        l10n.announcementSms(p.smsSegments),
                        if (p.estimatedCost != null)
                          l10n.announcementCost(
                            formatBirr(p.estimatedCost!, locale: locale),
                          ),
                      ].join(' · '),
                    ),
                    const Divider(),
                    Text(
                      p.text,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          if (p == null)
            OutlinedButton(
              key: const Key('checkAnnouncement'),
              onPressed: _busy ? null : _check,
              child: Text(l10n.announcementPreview),
            )
          else
            FilledButton.icon(
              key: const Key('sendAnnouncement'),
              onPressed: _busy || p.recipients == 0 ? null : _send,
              icon: const Icon(Icons.campaign_outlined),
              label: Text(l10n.announcementSend),
            ),
        ],
      ),
    );
  }
}
