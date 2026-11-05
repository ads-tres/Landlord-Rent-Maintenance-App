import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small key-value wrapper so tests can swap in an in-memory store.
abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
}

class SecureKeyValueStore implements KeyValueStore {
  SecureKeyValueStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) => value == null
      ? _storage.delete(key: key)
      : _storage.write(key: key, value: value);
}

class MemoryKeyValueStore implements KeyValueStore {
  MemoryKeyValueStore([Map<String, String>? initial]) : _values = {...?initial};

  final Map<String, String> _values;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }
}

final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => SecureKeyValueStore(),
);

/// Holds the API token in memory (for the Dio interceptor) and in secure storage.
class TokenStore {
  TokenStore(this._store);

  static const _key = 'auth_token';

  final KeyValueStore _store;
  String? _token;

  String? get token => _token;

  Future<String?> load() async => _token = await _store.read(_key);

  Future<void> save(String? token) async {
    _token = token;
    await _store.write(_key, token);
  }
}

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(ref.watch(keyValueStoreProvider)),
);
