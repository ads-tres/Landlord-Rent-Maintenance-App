import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'storage/secure_store.dart';

/// App language: Amharic by default, English as an option. Remembered on the device.
class LocaleController extends Notifier<Locale> {
  static const supported = [Locale('am'), Locale('en')];
  static const _key = 'locale';

  @override
  Locale build() {
    _restore();
    return const Locale('am');
  }

  Future<void> _restore() async {
    final saved = await ref.read(keyValueStoreProvider).read(_key);
    if (saved != null && supported.any((l) => l.languageCode == saved)) {
      state = Locale(saved);
    }
  }

  Future<void> set(Locale locale) async {
    state = locale;
    await ref.read(keyValueStoreProvider).write(_key, locale.languageCode);
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
