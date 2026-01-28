import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/technician.dart';

class AuthService {
  static const String _technicianKey = 'current_technician';
  static const String _tokenKey = 'auth_token';

  // Guardar datos del técnico y token
  Future<void> saveAuthData({
    required String token,
    required int technicianId,
    required String technicianName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    
    // Guardar datos básicos del técnico
    final technicianData = {
      'id': technicianId,
      'name': technicianName,
    };
    await prefs.setString(_technicianKey, jsonEncode(technicianData));
  }

  // Obtener token guardado
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Verificar si hay token válido
  Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Legacy: Guardar técnico (mantener por compatibilidad)
  Future<void> saveTechnician(Technician technician) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_technicianKey, jsonEncode(technician.toJson()));
  }

  // Obtener técnico actual
  Future<Technician?> getCurrentTechnician() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_technicianKey);
    if (data != null) {
      try {
        final json = jsonDecode(data);
        // Si tiene toda la info, parsear como Technician
        if (json.containsKey('phone')) {
          return Technician.fromJson(json);
        }
        // Si solo tiene id y name (nuevo formato), crear Technician básico
        return Technician(
          id: json['id'] as int,
          name: json['name'] as String,
          phone: '',
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Logout - limpiar todos los datos
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_technicianKey);
    await prefs.remove(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final hasToken = await hasValidToken();
    final technician = await getCurrentTechnician();
    return hasToken && technician != null;
  }
}
