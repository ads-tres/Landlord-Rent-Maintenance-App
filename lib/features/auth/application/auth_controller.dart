import '../../../core/push/push_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/offline/response_cache.dart';
import '../../../core/storage/secure_store.dart';
import '../../payments/application/pending_payments.dart'
    show pendingPaymentsKey;
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

/// The signed-in landlord, or null when logged out.
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final tokens = ref.read(tokenStoreProvider);
    final token = await tokens.load();
    if (token == null) return null;

    try {
      return await ref.read(authRepositoryProvider).me();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await tokens.save(null);
        return null;
      }
      rethrow;
    }
  }

  Future<void> requestCode(String phone) {
    final locale = ref.read(localeControllerProvider).languageCode;
    return ref.read(authRepositoryProvider).requestCode(phone, locale: locale);
  }

  Future<void> verify(String phone, String code) async {
    final locale = ref.read(localeControllerProvider).languageCode;
    final result = await ref
        .read(authRepositoryProvider)
        .verify(phone, code, locale: locale);
    await ref.read(tokenStoreProvider).save(result.token);
    state = AsyncData(result.user);
  }

  Future<void> updateProfile({
    String? name,
    String? locale,
    String? calendarPref,
    bool? smsReminders,
    bool? pushEnabled,
    String? idNumber,
    String? address,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .updateMe(
          name: name,
          locale: locale,
          calendarPref: calendarPref,
          smsReminders: smsReminders,
          pushEnabled: pushEnabled,
          idNumber: idNumber,
          address: address,
        );
    state = AsyncData(user);
  }

  /// Reloads the profile without showing a loading state (e.g. after linking Telegram).
  Future<void> refreshUser() async {
    try {
      state = AsyncData(await ref.read(authRepositoryProvider).me());
    } on ApiException {
      // Keep what we have; it refreshes on the next start.
    }
  }

  /// Asks for the account to be deleted in 30 days (confirmed with the phone number).
  Future<void> requestDeletion(String phone) async => state = AsyncData(
    await ref.read(authRepositoryProvider).requestDeletion(phone),
  );

  Future<void> cancelDeletion() async => state = AsyncData(
    await ref.read(authRepositoryProvider).cancelDeletion(),
  );

  Future<void> logout() async {
    // Stop this phone getting the account's alerts before the token is revoked.
    final push = ref.read(pushServiceProvider);
    try {
      final token = await push.token();
      if (token != null) {
        await ref.read(authRepositoryProvider).unregisterDevice(token);
      }
    } catch (_) {
      // Best effort: the server also drops tokens Firebase reports as gone.
    }
    try {
      await ref.read(authRepositoryProvider).logout();
    } on ApiException {
      // Token may already be invalid; log out locally anyway.
    }
    await signOutLocally();
  }

  Future<void> signOutLocally() async {
    await ref.read(tokenStoreProvider).save(null);
    // Saved screens and unsent payments belong to this landlord only.
    await ref.read(cacheStoreProvider).clear();
    await ref.read(keyValueStoreProvider).write(pendingPaymentsKey, null);
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

/// True for a caretaker: landlord-only actions are hidden (the server refuses them too).
final isCaretakerProvider = Provider<bool>(
  (ref) => ref.watch(
    authControllerProvider.select((u) => u.value?.isCaretaker ?? false),
  ),
);
