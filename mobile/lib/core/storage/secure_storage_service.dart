import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Encrypted credential & cache storage using Android Keystore
/// (`04-architecture-security-testing.md`).
///
/// Security audit F4: user data (cached dashboard/task/habit snapshots,
/// statistics, cached profile) is stored through this service instead of plain
/// `SharedPreferences`, so the payloads are encrypted by the platform keystore.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'lifeos_access_token';
  static const String _refreshTokenKey = 'lifeos_refresh_token';

  Future<String?> getAccessToken() => readValue(_accessTokenKey);

  Future<String?> getRefreshToken() => readValue(_refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      writeValue(_accessTokenKey, accessToken),
      writeValue(_refreshTokenKey, refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      deleteValue(_accessTokenKey),
      deleteValue(_refreshTokenKey),
    ]);
  }

  /// Reads an arbitrary encrypted value.
  Future<String?> readValue(String key) => _storage.read(key: key);

  /// Writes an arbitrary encrypted value.
  Future<void> writeValue(String key, String value) =>
      _storage.write(key: key, value: value);

  /// Deletes an arbitrary encrypted value.
  Future<void> deleteValue(String key) => _storage.delete(key: key);

  /// Returns every encrypted entry (used to purge the read cache).
  Future<Map<String, String>> readAll() => _storage.readAll();
}
