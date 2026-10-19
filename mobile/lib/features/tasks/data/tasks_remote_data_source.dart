import 'package:dio/dio.dart';

/// Raw HTTP access to `/api/v1/tasks` endpoints (`03-technical-spec.md` Section 4.2).
class TasksRemoteDataSource {
  TasksRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> listTasks({
    String? status,
    String? priority,
    String? from,
    String? to,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      'status': ?status,
      'priority': ?priority,
      'from': ?from,
      'to': ?to,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    final response = await _dio.get<Map<String, dynamic>>(
      '/tasks',
      queryParameters: queryParameters,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueAt,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/tasks',
      data: {
        'title': title,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        'status': ?status,
        'priority': ?priority,
        if (dueAt != null) 'dueAt': dueAt.toUtc().toIso8601String(),
      },
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> getTask(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/tasks/$id');
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateTask(
    String id, {
    String? title,
    String? description,
    bool includeNullDescription = false,
    String? status,
    String? priority,
    DateTime? dueAt,
    bool includeNullDueAt = false,
  }) async {
    final payload = <String, dynamic>{
      'title': ?title,
      if (description != null)
        'description': description
      else if (includeNullDescription)
        'description': null,
      'status': ?status,
      'priority': ?priority,
      if (dueAt != null)
        'dueAt': dueAt.toUtc().toIso8601String()
      else if (includeNullDueAt)
        'dueAt': null,
    };

    final response = await _dio.patch<Map<String, dynamic>>(
      '/tasks/$id',
      data: payload,
    );
    return response.data ?? const {};
  }

  Future<void> deleteTask(String id) async {
    await _dio.delete<void>('/tasks/$id');
  }
}
