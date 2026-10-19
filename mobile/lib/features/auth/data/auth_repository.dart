import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_session.dart';
import '../domain/user.dart';
import 'auth_remote_data_source.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    storage: ref.watch(secureStorageServiceProvider),
    cache: ref.watch(localCacheServiceProvider),
  ),
);

/// Orchestrates auth HTTP calls, secure token storage, and the local read cache
/// (`04-architecture-security-testing.md` Sections 12.1 & 13.1).
class AuthRepository {
  AuthRepository({
    required this._remoteDataSource,
    required this._storage,
    required this._cache,
  });

  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storage;
  final LocalCacheService _cache;

  static const String _cachedUserKey = 'auth_user';

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String timezone,
  }) {
    return _guard(() async {
      final body = await _remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        timezone: timezone,
      );
      return _persistSession(body);
    });
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final body = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      return _persistSession(body);
    });
  }

  Future<User> me() {
    return _guard(() async {
      final body = await _remoteDataSource.me();
      final user = User.fromJson(body['data'] as Map<String, dynamic>);
      await _cache.writeJson(_cachedUserKey, user.toJson());
      return user;
    });
  }

  /// Best-effort server-side revocation of the stored refresh token.
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return;
    }
    try {
      await _remoteDataSource.logout(refreshToken);
    } on DioException {
      // Local cleanup proceeds even if revocation cannot reach the server.
    }
  }

  User? readCachedUser() {
    final json = _cache.readJson(_cachedUserKey);
    if (json == null) {
      return null;
    }
    try {
      return User.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<AuthSession> _persistSession(Map<String, dynamic> responseBody) async {
    final data = responseBody['data'] as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;

    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _cache.writeJson(_cachedUserKey, user.toJson());

    return AuthSession(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: (data['expiresIn'] as num?)?.toInt() ?? 900,
    );
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
