import 'package:dio/dio.dart';

/// Raw HTTP access to `/api/v1/statistics/*` (`03-technical-spec.md` §4.6).
class StatisticsRemoteDataSource {
  StatisticsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getOverview({
    required String from,
    required String to,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/statistics/overview',
      queryParameters: {'from': from, 'to': to},
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> getWeekly({required String weekStart}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/statistics/weekly',
      queryParameters: {'weekStart': weekStart},
    );
    return response.data ?? const {};
  }
}
