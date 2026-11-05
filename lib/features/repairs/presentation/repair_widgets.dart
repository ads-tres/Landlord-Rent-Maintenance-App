import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/storage/secure_store.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/repair.dart';

extension RepairCategoryLabel on RepairCategory {
  String label(AppLocalizations l10n) => switch (this) {
    RepairCategory.water => l10n.categoryWater,
    RepairCategory.electric => l10n.categoryElectric,
    RepairCategory.plumbing => l10n.categoryPlumbing,
    RepairCategory.doorLock => l10n.categoryDoorLock,
    RepairCategory.roof => l10n.categoryRoof,
    RepairCategory.appliance => l10n.categoryAppliance,
    RepairCategory.other => l10n.categoryOther,
  };

  IconData get icon => switch (this) {
    RepairCategory.water => Icons.water_drop_outlined,
    RepairCategory.electric => Icons.bolt_outlined,
    RepairCategory.plumbing => Icons.plumbing,
    RepairCategory.doorLock => Icons.lock_outline,
    RepairCategory.roof => Icons.roofing,
    RepairCategory.appliance => Icons.kitchen_outlined,
    RepairCategory.other => Icons.build_outlined,
  };
}

class RepairStatusChip extends StatelessWidget {
  const RepairStatusChip({super.key, required this.status});

  final RepairStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (label, bg, fg) = switch (status) {
      RepairStatus.open => (
        l10n.repairOpen,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      RepairStatus.inProgress => (
        l10n.repairInProgress,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      RepairStatus.done => (
        l10n.repairDone,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
    };
    return Chip(
      label: Text(label, style: TextStyle(color: fg)),
      backgroundColor: bg,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Loads a private photo with the landlord's token.
class AuthImage extends ConsumerWidget {
  const AuthImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(tokenStoreProvider).token;
    return Image.network(
      url,
      fit: fit,
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
      errorBuilder: (_, _, _) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

/// Picks a photo from the camera or gallery, already shrunk on the phone
/// (max 1280 px, JPEG quality 70 — usually under 250 KB) to save mobile data.
Future<String?> pickRepairPhoto(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.takePhoto),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.choosePhoto),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1280,
    maxHeight: 1280,
    imageQuality: 70,
  );
  return file?.path;
}
