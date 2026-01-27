import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/technician.dart';
import '../models/installation.dart';
import '../models/location.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  // Technicians
  Future<List<Technician>> getTechnicians() async {
    try {
      final response = await _dio.get(ApiConfig.techniciansList);
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? response.data['technicians'] ?? []);
      return data.map((json) => Technician.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Installations
  Future<List<Installation>> getTechnicianInstallations(int technicianId, {DateTime? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['target_date'] = date.toIso8601String().split('T')[0];
      }

      final response = await _dio.get(
        '${ApiConfig.technicianInstallations}/$technicianId/installations',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? response.data['installations'] ?? []);
      return data.map((json) => Installation.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Installation> getInstallationDetail(int installationId) async {
    try {
      final response = await _dio.get('${ApiConfig.installations}/app/$installationId');
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return Installation.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Installation> updateInstallation(int installationId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.installations}/$installationId',
        data: data,
      );
      final responseData = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return Installation.fromJson(responseData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Status Update
  Future<void> updateInstallationStatus(int installationId, String status) async {
    try {
      await _dio.patch(
        '${ApiConfig.installations}/app/$installationId/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Timer
  Future<Installation> startTimer(int installationId) async {
    try {
      final response = await _dio.post('${ApiConfig.installations}/app/$installationId/timer/start');
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return Installation.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Installation> stopTimer(int installationId) async {
    try {
      final response = await _dio.post('${ApiConfig.installations}/app/$installationId/timer/stop');
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return Installation.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Location Tracking
  Future<void> sendLocation(int technicianId, TechnicianLocation location) async {
    try {
      await _dio.post(
        '${ApiConfig.technicians}/$technicianId/location',
        data: location.toJson(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Error de conexión. Verifica tu internet.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final message = e.response?.data?['message'] ?? e.response?.data?['error'];
        if (statusCode == 401) {
          return 'No autorizado. Inicia sesión nuevamente.';
        } else if (statusCode == 404) {
          return 'Recurso no encontrado.';
        } else if (statusCode >= 500) {
          return 'Error del servidor. Intenta más tarde.';
        }
        return message ?? 'Error: $statusCode';
      case DioExceptionType.cancel:
        return 'Solicitud cancelada.';
      default:
        return 'Error de conexión. Verifica tu internet.';
    }
  }
}
