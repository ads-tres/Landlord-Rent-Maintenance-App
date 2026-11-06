import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../locale_controller.dart';
import '../offline/response_cache.dart';
import '../storage/secure_store.dart';
import 'api_exception.dart';

/// Called when the server rejects the token, so the app can return to login.
final unauthorizedHandlerProvider = Provider<void Function()>((ref) => () {});

final dioProvider = Provider<Dio>((ref) {
  final tokens = ref.watch(tokenStoreProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokens.token;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        final locale = ref.read(localeControllerProvider);
        options.headers['Accept-Language'] = locale.languageCode;
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401 && tokens.token != null) {
          ref.read(unauthorizedHandlerProvider)();
        }
        handler.next(error);
      },
    ),
  );

  // Last: answers GETs from the saved copy when there is no connection.
  dio.interceptors.add(
    ResponseCacheInterceptor(
      store: ref.watch(cacheStoreProvider),
      onOfflineChanged: (offline) =>
          ref.read(offlineStatusProvider.notifier).set(offline),
    ),
  );

  return dio;
});

/// Thin wrapper that turns Dio errors into [ApiException]s.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  /// Downloads a file (e.g. a PDF) as bytes.
  Future<List<int>> getBytes(String path, {Map<String, dynamic>? query}) async {
    final data = await _send(
      () => _dio.get<List<int>>(
        path,
        queryParameters: query,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf'},
        ),
      ),
    );
    return data as List<int>;
  }

  Future<dynamic> post(String path, {Object? data}) =>
      _send(() => _dio.post(path, data: data));

  Future<dynamic> put(String path, {Object? data}) =>
      _send(() => _dio.put(path, data: data));

  Future<dynamic> patch(String path, {Object? data}) =>
      _send(() => _dio.patch(path, data: data));

  Future<dynamic> delete(String path) => _send(() => _dio.delete(path));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
