import 'dart:async';

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

  /// Serializes all keystore/WebCrypto operations so concurrent writes on a
  /// fresh web session cannot race when generating the `FlutterSecureStorage`
  /// AES-GCM master key in `localStorage`.
  static Completer<bool>? _activeLock;

  Future<T> _synchronized<T>(Future<T> Function() action) async {
    while (_activeLock != null) {
      try {
        await _activeLock!.future;
      } catch (_) {}
    }
    final lock = Completer<bool>();
    _activeLock = lock;
    try {
      return await action();
    } finally {
      if (identical(_activeLock, lock)) {
        _activeLock = null;
      }
      if (!lock.isCompleted) {
        lock.complete(true);
      }
    }
  }

  Future<String?> getAccessToken() => readValue(_accessTokenKey);

  Future<String?> getRefreshToken() => readValue(_refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await writeValue(_accessTokenKey, accessToken);
    await writeValue(_refreshTokenKey, refreshToken);
  }

  Future<void> clearTokens() async {
    await deleteValue(_accessTokenKey);
    await deleteValue(_refreshTokenKey);
  }

  /// Reads an arbitrary encrypted value.
  /// Catches non-Exception JS `DomException` (`OperationError`) on Web when an
  /// entry was encrypted with a stale/mismatched WebCrypto key, purges the
  /// unreadable entry, and returns `null`.
  Future<String?> readValue(String key) {
    return _synchronized(() async {
      try {
        return await _storage.read(key: key);
      } catch (_) {
        try {
          await _storage.delete(key: key);
        } catch (_) {}
        return null;
      }
    });
  }

  /// Writes an arbitrary encrypted value.
  Future<void> writeValue(String key, String value) {
    return _synchronized(() async {
      try {
        await _storage.write(key: key, value: value);
      } catch (_) {
        try {
          await _storage.deleteAll();
          await _storage.write(key: key, value: value);
        } catch (_) {}
      }
    });
  }

  /// Deletes an arbitrary encrypted value.
  Future<void> deleteValue(String key) {
    return _synchronized(() async {
      try {
        await _storage.delete(key: key);
      } catch (_) {}
    });
  }

  /// Returns every encrypted entry (used to purge the read cache).
  Future<Map<String, String>> readAll() {
    return _synchronized(() async {
      try {
        return await _storage.readAll();
      } catch (_) {
        return const <String, String>{};
      }
    });
  }
}
