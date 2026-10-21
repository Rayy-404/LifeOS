import 'package:dio/dio.dart';
import '../errors/api_exception.dart';

/// Runs [action] and converts transport failures into the standard
/// [ApiException] so every feature handles API errors identically
/// (`03-technical-spec.md` Section 4 — Format Error API Standar).
Future<T> guardApiCall<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (error) {
    throw ApiException.fromDioException(error);
  }
}

/// Runs [action] and falls back to the local read cache when the request fails
/// because the device is offline (`04-architecture-security-testing.md` §12.1).
Future<T> guardApiCallWithCacheFallback<T>({
  required Future<T> Function() action,
  required Future<T?> Function() readCache,
}) async {
  try {
    return await action();
  } on DioException catch (error) {
    final apiException = ApiException.fromDioException(error);
    if (apiException.isNetworkError) {
      final cached = await readCache();
      if (cached != null) return cached;
    }
    throw apiException;
  }
}
