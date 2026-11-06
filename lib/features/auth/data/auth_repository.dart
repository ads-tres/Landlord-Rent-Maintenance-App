import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/app_user.dart';

class LoginResult {
  const LoginResult({
    required this.token,
    required this.user,
    required this.isNew,
  });

  final String token;
  final AppUser user;
  final bool isNew;
}

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<void> requestCode(String phone, {required String locale}) async {
    await _api.post('/auth/otp', data: {'phone': phone, 'locale': locale});
  }

  Future<LoginResult> verify(
    String phone,
    String code, {
    required String locale,
  }) async {
    final data = await _api.post(
      '/auth/verify',
      data: {
        'phone': phone,
        'code': code,
        'device_name': 'kiray-app',
        'locale': locale,
      },
    ) as Map<String, dynamic>;

    return LoginResult(
      token: data['token'] as String,
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
      isNew: data['is_new'] as bool? ?? false,
    );
  }

  Future<AppUser> me() async {
    final data = await _api.get('/auth/me') as Map<String, dynamic>;
    return AppUser.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<AppUser> updateMe({
    String? name,
    String? locale,
    String? calendarPref,
    bool? smsReminders,
    bool? pushEnabled,
  }) async {
    final data = await _api.patch(
      '/auth/me',
      data: {
        'name': ?name,
        'locale': ?locale,
        'calendar_pref': ?calendarPref,
        'sms_reminders': ?smsReminders,
        'push_enabled': ?pushEnabled,
      },
    ) as Map<String, dynamic>;
    return AppUser.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// One-time t.me link that opens the bot and links this landlord.
  Future<String> telegramLinkUrl() async {
    final data = await _api.post('/telegram/link') as Map<String, dynamic>;
    return (data['data'] as Map<String, dynamic>)['url'] as String;
  }

  Future<void> telegramUnlink() => _api.delete('/telegram/link');

  /// Registers this phone for push notifications.
  Future<void> registerDevice(String token) =>
      _api.post('/devices', data: {'token': token, 'platform': 'android'});

  /// Stops push notifications for this account on this phone.
  Future<void> unregisterDevice(String token) =>
      _api.delete('/devices', data: {'token': token});

  Future<void> logout() async {
    await _api.post('/auth/logout');
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);
