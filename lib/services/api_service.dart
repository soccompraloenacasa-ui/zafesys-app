import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/technician.dart';
import '../models/installation.dart';
import '../models/location.dart';
import 'auth_service.dart';

class ApiService {
  late final Dio _dio;
  final AuthService _authService = AuthService();

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

    // Interceptor para agregar token a las peticiones
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Si el token expiró, logout automático
        if (error.response?.statusCode == 401) {
          await _authService.logout();
        }
        return handler.next(error);
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  // ===== AUTH =====
  
  /// Login de técnico con cédula y PIN
  /// Retorna los datos de autenticación si es exitoso
  Future<Map<String, dynamic>> loginTechnician({
    required String documentId,
    required String pin,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/technician/login',
        data: {
          'document_id': documentId,
          'pin': pin,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Validar si el token actual es válido
  Future<Map<String, dynamic>?> validateToken() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;
      
      final response = await _dio.post(
        '/auth/technician/validate-token',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.data;
    } on DioException {
      return null;
    }
  }

  // ===== TECHNICIANS =====
  
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

  // ===== INSTALLATIONS =====
  
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

  // ===== STATUS =====
  
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

  // ===== TIMER =====
  
  Future<void> startTimer(int installationId) async {
    try {
      await _dio.post('${ApiConfig.installations}/app/$installationId/timer/start');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> stopTimer(int installationId) async {
    try {
      await _dio.post('${ApiConfig.installations}/app/$installationId/timer/stop');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ===== LOCATION TRACKING =====
  
  Future<void> sendLocation(int technicianId, TechnicianLocation location) async {
    try {
      await _dio.post(
        '/tech/location',
        queryParameters: {'technician_id': technicianId},
        data: location.toJson(),
      );
    } on DioException catch (e) {
      // Silently fail for location - don't interrupt user
      print('Error enviando ubicación: ${e.message}');
    }
  }

  // ===== ERROR HANDLING =====
  
  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Error de conexión. Verifica tu internet.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final data = e.response?.data;
        String? message;
        
        // Intentar extraer mensaje de diferentes formatos
        if (data is Map) {
          message = data['detail'] ?? data['message'] ?? data['error'];
        }
        
        if (statusCode == 401) {
          return message ?? 'Credenciales incorrectas';
        } else if (statusCode == 403) {
          return message ?? 'Acceso denegado';
        } else if (statusCode == 404) {
          return message ?? 'No encontrado';
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
