import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/storage/secure_store.dart';
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
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .updateMe(name: name, locale: locale, calendarPref: calendarPref);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } on ApiException {
      // Token may already be invalid; log out locally anyway.
    }
    await signOutLocally();
  }

  Future<void> signOutLocally() async {
    await ref.read(tokenStoreProvider).save(null);
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);
