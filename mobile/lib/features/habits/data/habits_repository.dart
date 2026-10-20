import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/storage/local_cache_service.dart';
import '../domain/habit.dart';
import 'habits_remote_data_source.dart';

final habitsRemoteDataSourceProvider = Provider<HabitsRemoteDataSource>(
  (ref) => HabitsRemoteDataSource(ref.watch(dioProvider)),
);

final habitsRepositoryProvider = Provider<HabitsRepository>(
  (ref) => HabitsRepository(
    remoteDataSource: ref.watch(habitsRemoteDataSourceProvider),
    cache: ref.watch(localCacheServiceProvider),
  ),
);

class HabitCheckInResponse {
  const HabitCheckInResponse({
    required this.habitId,
    required this.logDate,
    required this.completed,
    required this.currentStreak,
    this.completedAt,
  });

  final String habitId;
  final String logDate;
  final bool completed;
  final int currentStreak;
  final DateTime? completedAt;

  factory HabitCheckInResponse.fromJson(Map<String, dynamic> json) {
    return HabitCheckInResponse(
      habitId: json['habitId'] as String,
      logDate: json['logDate'] as String,
      completed: (json['completed'] as bool?) ?? false,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)?.toLocal()
          : null,
    );
  }
}

/// Orchestrates habit CRUD, idempotent check-in, and local read caching (`04-architecture-security-testing.md` §12.1).
class HabitsRepository {
  HabitsRepository({
    required this._remoteDataSource,
    required this._cache,
  });

  final HabitsRemoteDataSource _remoteDataSource;
  final LocalCacheService _cache;

  static const String _cacheKey = 'habits_snapshot';

  Future<HabitsSnapshot> listHabits({bool? isActive}) async {
    try {
      final response = await _remoteDataSource.listHabits(isActive: isActive);
      final rawItems = (response['data'] as List<dynamic>?) ?? const [];
      final items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(Habit.fromJson)
          .toList();

      if (isActive == null) {
        await _cache.writeJson(_cacheKey, {
          'data': items.map((h) => h.toJson()).toList(),
        });
      }

      return HabitsSnapshot(items: items);
    } on DioException catch (error) {
      final apiException = ApiException.fromDioException(error);
      if (apiException.isNetworkError) {
        final cached = _readCachedHabits();
        if (cached != null) {
          return cached;
        }
      }
      throw apiException;
    }
  }

  Future<Habit> createHabit({
    required String name,
    String? description,
    List<int> activeDays = const [1, 2, 3, 4, 5, 6, 7],
    bool isActive = true,
  }) {
    return _guard(() async {
      final response = await _remoteDataSource.createHabit(
        name: name,
        description: description,
        activeDays: activeDays,
        isActive: isActive,
      );
      return Habit.fromJson(response['data'] as Map<String, dynamic>);
    });
  }

  Future<Habit> getHabit(String id) {
    return _guard(() async {
      final response = await _remoteDataSource.getHabit(id);
      return Habit.fromJson(response['data'] as Map<String, dynamic>);
    });
  }

  Future<Habit> updateHabit(
    String id, {
    String? name,
    String? description,
    bool includeNullDescription = false,
    List<int>? activeDays,
    bool? isActive,
  }) {
    return _guard(() async {
      final response = await _remoteDataSource.updateHabit(
        id,
        name: name,
        description: description,
        includeNullDescription: includeNullDescription,
        activeDays: activeDays,
        isActive: isActive,
      );
      return Habit.fromJson(response['data'] as Map<String, dynamic>);
    });
  }

  Future<void> deleteHabit(String id) {
    return _guard(() => _remoteDataSource.deleteHabit(id));
  }

  Future<List<HabitLog>> getLogs(
    String habitId, {
    String? from,
    String? to,
  }) {
    return _guard(() async {
      final response = await _remoteDataSource.getLogs(
        habitId,
        from: from,
        to: to,
      );
      final rawItems = (response['data'] as List<dynamic>?) ?? const [];
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(HabitLog.fromJson)
          .toList();
    });
  }

  Future<HabitCheckInResponse> checkIn(
    String habitId, {
    required String date,
    required bool completed,
  }) {
    return _guard(() async {
      final response = await _remoteDataSource.checkIn(
        habitId,
        date: date,
        completed: completed,
      );
      return HabitCheckInResponse.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    });
  }

  HabitsSnapshot? _readCachedHabits() {
    final json = _cache.readJson(_cacheKey);
    if (json == null) return null;
    try {
      final rawItems = (json['data'] as List<dynamic>?) ?? const [];
      final items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(Habit.fromJson)
          .toList();
      return HabitsSnapshot(items: items, isFromCache: true);
    } catch (_) {
      return null;
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
