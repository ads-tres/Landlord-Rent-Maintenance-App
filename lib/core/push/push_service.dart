import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';

/// A tapped or foreground notification: its text and the screen it points to.
typedef PushMessage = ({String? body, String? route, bool opened});

/// Push notifications. The Firebase version is used when the build has Firebase
/// settings; otherwise [NoPushService] keeps everything off.
abstract class PushService {
  /// The phone's push token, after asking for permission. Null when unavailable.
  Future<String?> token();

  Stream<String> get onTokenRefresh;

  /// Notifications received while the app is open, and ones the user tapped.
  Stream<PushMessage> get messages;
}

class NoPushService implements PushService {
  const NoPushService();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<PushMessage> get messages => const Stream.empty();
}

class FirebasePushService implements PushService {
  FirebasePushService(this._messaging);

  final FirebaseMessaging _messaging;
  final _messages = StreamController<PushMessage>.broadcast();
  bool _listening = false;

  /// Starts Firebase with the build's settings. Returns null if that fails.
  static Future<FirebasePushService?> start() async {
    if (!AppConfig.firebaseConfigured) return null;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: AppConfig.firebaseApiKey,
          appId: AppConfig.firebaseAppId,
          messagingSenderId: AppConfig.firebaseSenderId,
          projectId: AppConfig.firebaseProjectId,
        ),
      );
      return FirebasePushService(FirebaseMessaging.instance);
    } catch (e) {
      debugPrint('Push disabled: $e');
      return null;
    }
  }

  PushMessage _from(RemoteMessage m, {required bool opened}) => (
    body: m.notification?.body,
    route: m.data['route'] as String?,
    opened: opened,
  );

  void _listen() {
    if (_listening) return;
    _listening = true;
    FirebaseMessaging.onMessage.listen(
      (m) => _messages.add(_from(m, opened: false)),
    );
    FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => _messages.add(_from(m, opened: true)),
    );
    // Opened from a notification while the app was closed.
    _messaging.getInitialMessage().then((m) {
      if (m != null) _messages.add(_from(m, opened: true));
    });
  }

  @override
  Future<String?> token() async {
    _listen();
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return null;
    // The server sends with FCM HTTP v1 `message.token`, which takes the
    // registration token (not the newer installation ID from register()).
    // ignore: deprecated_member_use
    return _messaging.getToken();
  }

  @override
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get messages {
    _listen();
    return _messages.stream;
  }
}

/// Overridden in main() with the Firebase service when the build has Firebase settings.
final pushServiceProvider = Provider<PushService>(
  (ref) => const NoPushService(),
);
