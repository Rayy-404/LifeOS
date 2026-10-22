import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Owns the app-wide authentication state and the full session lifecycle.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.unknown();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Called once from the Splash screen: restores or discards the stored session.
  Future<void> loadSession() async {
    final storage = ref.read(secureStorageServiceProvider);
    String? accessToken;
    String? refreshToken;
    try {
      accessToken = await storage.getAccessToken();
      refreshToken = await storage.getRefreshToken();
    } catch (_) {
      await _clearLocalSession();
      state = const AuthState.unauthenticated();
      return;
    }

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      state = const AuthState.unauthenticated();
      return;
    }

    try {
      final user = await _repository.me();
      state = AuthState.authenticated(user);
    } on ApiException catch (error) {
      if (error.isNetworkError) {
        try {
          final cachedUser = await _repository.readCachedUser();
          if (cachedUser != null) {
            state = AuthState.authenticated(cachedUser);
            return;
          }
        } catch (_) {}
      }
      await _clearLocalSession();
      state = const AuthState.unauthenticated();
    } catch (_) {
      await _clearLocalSession();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final session = await _repository.login(email: email, password: password);
    state = AuthState.authenticated(session.user);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String timezone,
  }) async {
    final session = await _repository.register(
      name: name,
      email: email,
      password: password,
      timezone: timezone,
    );
    state = AuthState.authenticated(session.user);
  }

  /// Revokes the refresh token server-side, then wipes tokens, cached reads,
  /// and scheduled local notifications (`04-architecture-security-testing.md` Section 12.3.5).
  Future<void> logout() async {
    await _repository.logout();
    await _clearLocalSession();
    state = const AuthState.unauthenticated();
  }

  Future<void> _clearLocalSession() async {
    final storage = ref.read(secureStorageServiceProvider);
    final cache = ref.read(localCacheServiceProvider);
    final notifications = ref.read(localNotificationServiceProvider);

    try {
      await storage.clearTokens();
    } catch (_) {}
    try {
      await cache.clearAllCache();
    } catch (_) {}
    try {
      await notifications.cancelAll();
    } catch (_) {}
  }
}
