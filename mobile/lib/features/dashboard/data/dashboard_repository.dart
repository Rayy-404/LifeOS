import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_call_guard.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/local_cache_service.dart';
import '../domain/dashboard_summary.dart';
import 'dashboard_remote_data_source.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>(
  (ref) => DashboardRemoteDataSource(ref.watch(dioProvider)),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(
    remoteDataSource: ref.watch(dashboardRemoteDataSourceProvider),
    cache: ref.watch(localCacheServiceProvider),
  ),
);

/// Orchestrates `GET /dashboard/today` and local read caching (`04-architecture-security-testing.md` §12.1).
class DashboardRepository {
  DashboardRepository({
    required this._remoteDataSource,
    required this._cache,
  });

  final DashboardRemoteDataSource _remoteDataSource;
  final LocalCacheService _cache;

  static const String _cacheKey = 'dashboard_snapshot';

  Future<DashboardSnapshot> getToday({String? date}) async {
    return guardApiCallWithCacheFallback<DashboardSnapshot>(
      action: () async {
        final response = await _remoteDataSource.getToday(date: date);
        final rawData = response['data'];
        final data = rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : const <String, dynamic>{};
        final snapshot = DashboardSnapshot.fromJson(data);

        await _cache.writeJson(_cacheKey, snapshot.toJson());
        return snapshot;
      },
      readCache: _readCachedDashboard,
    );
  }

  Future<DashboardSnapshot?> _readCachedDashboard() async {
    final json = await _cache.readJson(_cacheKey);
    if (json == null) return null;
    try {
      return DashboardSnapshot.fromJson(json, isFromCache: true);
    } catch (_) {
      return null;
    }
  }
}
