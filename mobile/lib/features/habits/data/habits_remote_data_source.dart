import 'package:dio/dio.dart';

/// Raw HTTP access to `/api/v1/habits` endpoints (`03-technical-spec.md` Section 4.3).
class HabitsRemoteDataSource {
  HabitsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> listHabits({bool? isActive}) async {
    final queryParameters = <String, dynamic>{
      'isActive': ?isActive,
    };

    final response = await _dio.get<Map<String, dynamic>>(
      '/habits',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> createHabit({
    required String name,
    String? description,
    required List<int> activeDays,
    bool isActive = true,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/habits',
      data: {
        'name': name,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        'activeDays': activeDays,
        'isActive': isActive,
      },
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> getHabit(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/habits/$id');
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateHabit(
    String id, {
    String? name,
    String? description,
    bool includeNullDescription = false,
    List<int>? activeDays,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{
      'name': ?name,
      if (description != null)
        'description': description
      else if (includeNullDescription)
        'description': null,
      'activeDays': ?activeDays,
      'isActive': ?isActive,
    };

    final response = await _dio.patch<Map<String, dynamic>>(
      '/habits/$id',
      data: payload,
    );
    return response.data ?? const {};
  }

  Future<void> deleteHabit(String id) async {
    await _dio.delete<void>('/habits/$id');
  }

  Future<Map<String, dynamic>> getLogs(
    String habitId, {
    String? from,
    String? to,
  }) async {
    final queryParameters = <String, dynamic>{
      'from': ?from,
      'to': ?to,
    };

    final response = await _dio.get<Map<String, dynamic>>(
      '/habits/$habitId/logs',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> checkIn(
    String habitId, {
    required String date,
    required bool completed,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/habits/$habitId/logs/$date',
      data: {
        'completed': completed,
      },
    );
    return response.data ?? const {};
  }
}
