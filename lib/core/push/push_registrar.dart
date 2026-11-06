import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../router.dart';
import 'push_service.dart';

/// Keeps the phone registered for push while someone is logged in with push on,
/// opens the right screen when a notification is tapped, and shows alerts that
/// arrive while the app is open.
class PushRegistrar extends ConsumerStatefulWidget {
  const PushRegistrar({super.key, required this.child, this.messengerKey});

  final Widget child;
  final GlobalKey<ScaffoldMessengerState>? messengerKey;

  @override
  ConsumerState<PushRegistrar> createState() => _PushRegistrarState();
}

class _PushRegistrarState extends ConsumerState<PushRegistrar> {
  StreamSubscription<String>? _refresh;
  StreamSubscription<PushMessage>? _messages;
  int? _registeredFor;

  @override
  void initState() {
    super.initState();
    final push = ref.read(pushServiceProvider);
    _messages = push.messages.listen(_onMessage);
    _refresh = push.onTokenRefresh.listen((t) => _register(token: t));
    ref.listenManual(authControllerProvider, (previous, next) {
      final user = next.value;
      if (user == null) {
        _registeredFor = null;
      } else if (_registeredFor != user.id && user.pushEnabled) {
        _register();
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _messages?.cancel();
    super.dispose();
  }

  Future<void> _register({String? token}) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || !user.pushAvailable || !user.pushEnabled) return;
    try {
      final t = token ?? await ref.read(pushServiceProvider).token();
      if (t == null) return;
      await ref.read(authRepositoryProvider).registerDevice(t);
      _registeredFor = user.id;
    } catch (_) {
      // Offline or no permission: try again on the next start.
    }
  }

  void _open(String? route) {
    if (route == null || route.isEmpty) return;
    ref.read(routerProvider).push(route);
  }

  void _onMessage(PushMessage m) {
    if (m.opened) {
      _open(m.route);
      return;
    }
    final messenger = widget.messengerKey?.currentState;
    final context = widget.messengerKey?.currentContext;
    if (messenger == null || context == null || m.body == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(m.body!),
        duration: const Duration(seconds: 6),
        action: m.route == null
            ? null
            : SnackBarAction(
                label: AppLocalizations.of(context).open,
                onPressed: () => _open(m.route),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
