import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha1;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Where cached GET responses live. Files in production, memory in tests.
abstract class CacheStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> clear();
}

class FileCacheStore implements CacheStore {
  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/api_cache');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  String _name(String key) => sha1.convert(utf8.encode(key)).toString();

  @override
  Future<String?> read(String key) async {
    final file = File('${(await _dir()).path}/${_name(key)}.json');
    return file.existsSync() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String key, String value) async {
    await File('${(await _dir()).path}/${_name(key)}.json')
        .writeAsString(value, flush: true);
  }

  @override
  Future<void> clear() async {
    final dir = await _dir();
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}

class MemoryCacheStore implements CacheStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> clear() async => values.clear();
}

final cacheStoreProvider = Provider<CacheStore>((ref) => FileCacheStore());

/// True while the app is showing saved data because the server can't be reached.
class OfflineStatus extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool offline) {
    if (state != offline) state = offline;
  }
}

final offlineStatusProvider = NotifierProvider<OfflineStatus, bool>(
  OfflineStatus.new,
);

/// Keeps the last good copy of the main lists so the app opens without signal.
/// On a connection failure, a GET is answered from that copy and the app shows
/// an offline banner. Cleared on logout so another landlord never sees it.
class ResponseCacheInterceptor extends Interceptor {
  ResponseCacheInterceptor({
    required this.store,
    required this.onOfflineChanged,
  });

  final CacheStore store;
  final void Function(bool offline) onOfflineChanged;

  static const cachedPaths = [
    '/auth/me', '/dashboard', '/properties', '/units', '/tenants', '/leases', //
    '/charges', '/payments', '/maintenance', '/rules', '/reports/quarterly',
  ];

  static bool isCacheable(RequestOptions o) =>
      o.method == 'GET' &&
      o.responseType == ResponseType.json &&
      cachedPaths.any(
        (p) =>
            o.path == p || o.path.startsWith('$p/') || o.path.startsWith('$p?'),
      );

  static String keyFor(RequestOptions o) {
    final query =
        (o.queryParameters.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key)))
            .map((e) => '${e.key}=${e.value}')
            .join('&');
    return '${o.path}?$query';
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    onOfflineChanged(false);
    final options = response.requestOptions;
    if (isCacheable(options) &&
        (response.statusCode ?? 0) < 300 &&
        response.data != null) {
      store.write(keyFor(options), jsonEncode(response.data)).ignore();
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final noConnection =
        err.response == null &&
        (err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.unknown);

    if (noConnection) {
      onOfflineChanged(true);
      if (isCacheable(err.requestOptions)) {
        final cached = await store.read(keyFor(err.requestOptions));
        if (cached != null) {
          return handler.resolve(
            Response(
              requestOptions: err.requestOptions,
              data: jsonDecode(cached),
              statusCode: 200,
              extra: {'fromCache': true},
            ),
          );
        }
      }
    }
    handler.next(err);
  }
}
