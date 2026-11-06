import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Asks which language a document should be in: `am`, `en` or `both`.
Future<String?> pickDocumentLanguage(
  BuildContext context, {
  required String title,
  String? help,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(title),
            subtitle: help == null ? null : Text(help),
          ),
          for (final (code, label) in [
            ('am', 'አማርኛ'),
            ('en', 'English'),
            ('both', l10n.bothLanguages),
          ])
            ListTile(
              key: Key('documentLanguage-$code'),
              leading: const Icon(Icons.description_outlined),
              title: Text(label),
              onTap: () => Navigator.pop(context, code),
            ),
        ],
      ),
    ),
  );
}
