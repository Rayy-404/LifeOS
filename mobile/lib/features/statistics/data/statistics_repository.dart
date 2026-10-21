import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/storage/local_cache_service.dart';
import '../domain/statistics.dart';
import 'statistics_remote_data_source.dart';

final statisticsRemoteDataSourceProvider = Provider<StatisticsRemoteDataSource>(
  (ref) => StatisticsRemoteDataSource(ref.watch(dioProvider)),
);

final statisticsRepositoryProvider = Provider<StatisticsRepository>(
  (ref) => StatisticsRepository(
    remoteDataSource: ref.watch(statisticsRemoteDataSourceProvider),
    cache: ref.watch(localCacheServiceProvider),
  ),
);

/// Loads the three statistics calls as one bundle and caches the latest
/// snapshot for offline viewing (`04-architecture-security-testing.md` §12.1).
class StatisticsRepository {
  StatisticsRepository({
    required this._remoteDataSource,
    required this._cache,
  });

  final StatisticsRemoteDataSource _remoteDataSource;
  final LocalCacheService _cache;

  static const String _cacheKey = 'statistics_bundle';

  Future<StatisticsBundle> getBundle({
    required String weekStart,
    required String weekEnd,
    required String previousWeekStart,
    required String previousWeekEnd,
  }) async {
    try {
      final responses = await Future.wait([
        _remoteDataSource.getOverview(from: weekStart, to: weekEnd),
        _remoteDataSource.getOverview(
          from: previousWeekStart,
          to: previousWeekEnd,
        ),
        _remoteDataSource.getWeekly(weekStart: weekStart),
      ]);

      final bundle = StatisticsBundle(
        currentWeek: StatisticsOverview.fromJson(
          (responses[0]['data'] as Map<String, dynamic>?) ?? const {},
        ),
        previousWeek: StatisticsOverview.fromJson(
          (responses[1]['data'] as Map<String, dynamic>?) ?? const {},
        ),
        weekly: WeeklyStatistics.fromJson(
          (responses[2]['data'] as Map<String, dynamic>?) ?? const {},
        ),
      );

      await _cache.writeJson(_cacheKey, bundle.toJson());
      return bundle;
    } on DioException catch (error) {
      final apiException = ApiException.fromDioException(error);
      if (apiException.isNetworkError) {
        final cached = _readCachedBundle();
        if (cached != null) return cached;
      }
      throw apiException;
    }
  }

  StatisticsBundle? _readCachedBundle() {
    final json = _cache.readJson(_cacheKey);
    if (json == null) return null;
    try {
      return StatisticsBundle.fromJson({...json, 'isFromCache': true});
    } catch (_) {
      return null;
    }
  }
}
