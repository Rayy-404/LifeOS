import 'package:dio/dio.dart';

/// Raw HTTP access to `/api/v1/dashboard/today` (`03-technical-spec.md` Section 4.6).
class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getToday({String? date}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/dashboard/today',
      queryParameters: {
        'date': ?date,
      },
    );
    return response.data ?? const {};
  }
}
