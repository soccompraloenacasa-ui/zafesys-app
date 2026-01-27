import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/technician.dart';

class AuthService {
  static const String _technicianKey = 'current_technician';

  Future<void> saveTechnician(Technician technician) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_technicianKey, jsonEncode(technician.toJson()));
  }

  Future<Technician?> getCurrentTechnician() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_technicianKey);
    if (data != null) {
      return Technician.fromJson(jsonDecode(data));
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_technicianKey);
  }

  Future<bool> isLoggedIn() async {
    final technician = await getCurrentTechnician();
    return technician != null;
  }
}
