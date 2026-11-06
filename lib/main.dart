import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/push/push_service.dart';
import 'features/auth/application/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Push is optional: builds without Firebase settings run without it.
  final push = await FirebasePushService.start();

  runApp(
    ProviderScope(
      overrides: [
        if (push != null) pushServiceProvider.overrideWithValue(push),
        // When the server rejects the token, sign out locally and return to login.
        unauthorizedHandlerProvider.overrideWith(
          (ref) =>
              () => ref.read(authControllerProvider.notifier).signOutLocally(),
        ),
      ],
      child: const KirayApp(),
    ),
  );
}
