import 'package:dio/dio.dart';

/// A failed API call, with Laravel validation errors when the server sent them.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
    this.isNetworkError = false,
  });

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException(
        message: e.message ?? 'Network error',
        isNetworkError: true,
      );
    }

    final data = response.data;
    final fieldErrors = <String, String>{};
    String message = 'Request failed (${response.statusCode})';

    if (data is Map) {
      if (data['message'] is String) message = data['message'] as String;
      final errors = data['errors'];
      if (errors is Map) {
        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            fieldErrors['$key'] = '${value.first}';
          }
        });
      }
    }

    return ApiException(
      message: message,
      statusCode: response.statusCode,
      fieldErrors: fieldErrors,
    );
  }

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;
  final bool isNetworkError;

  bool get isUnauthorized => statusCode == 401;
  bool get isValidation => statusCode == 422;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
