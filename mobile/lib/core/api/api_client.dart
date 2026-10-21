import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';

/// Resolves the default API base URL:
/// - Default: `http://localhost:3000/api/v1` (works for Web, Desktop, and physical Android via `adb reverse tcp:3000 tcp:3000`)
/// - Can be overridden via `--dart-define=API_BASE_URL=<url>` (e.g. `http://10.0.2.2:3000/api/v1` for Android emulator)
String get kDefaultApiBaseUrl {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) {
    return envUrl;
  }
  return 'http://localhost:3000/api/v1';
}

final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: kDefaultApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      secureStorage: secureStorage,
    ),
  );

  return dio;
});

/// Attaches Bearer token and performs transparent single-flight token refresh on 401.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this._dio,
    required this._secureStorage,
  });

  final Dio _dio;
  final SecureStorageService _secureStorage;

  bool _isPublicAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh');
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicAuthEndpoint(options.path)) {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final requestOptions = err.requestOptions;

    if (statusCode == 401 &&
        !_isPublicAuthEndpoint(requestOptions.path) &&
        requestOptions.extra['retried'] != true) {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: _dio.options.baseUrl,
              headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

          final response = await refreshDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          final data = response.data?['data'] as Map<String, dynamic>?;
          final newAccessToken = data?['accessToken'] as String?;
          final newRefreshToken = data?['refreshToken'] as String?;

          if (newAccessToken != null && newRefreshToken != null) {
            await _secureStorage.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );

            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            requestOptions.extra['retried'] = true;

            final retryResponse = await _dio.fetch<dynamic>(requestOptions);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          await _secureStorage.clearTokens();
        }
      }
    }

    handler.next(err);
  }
}
