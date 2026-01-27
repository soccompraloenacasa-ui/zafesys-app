import 'package:flutter/material.dart';
import '../models/technician.dart';
import '../models/installation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  late final LocationService _locationService;

  Technician? _currentTechnician;
  List<Technician> _technicians = [];
  List<Installation> _installations = [];
  Installation? _selectedInstallation;
  bool _isLoading = false;
  String? _error;
  ThemeMode _themeMode = ThemeMode.light;

  AppProvider() {
    _locationService = LocationService(_apiService);
    _init();
  }

  // Getters
  Technician? get currentTechnician => _currentTechnician;
  List<Technician> get technicians => _technicians;
  List<Installation> get installations => _installations;
  Installation? get selectedInstallation => _selectedInstallation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ThemeMode get themeMode => _themeMode;
  bool get isLoggedIn => _currentTechnician != null;

  List<Installation> get todayInstallations {
    final now = DateTime.now();
    return _installations.where((i) {
      return i.scheduledDate.year == now.year &&
          i.scheduledDate.month == now.month &&
          i.scheduledDate.day == now.day;
    }).toList()
      ..sort((a, b) {
        final timeA = a.scheduledTime ?? '23:59';
        final timeB = b.scheduledTime ?? '23:59';
        return timeA.compareTo(timeB);
      });
  }

  // Initialize
  Future<void> _init() async {
    _currentTechnician = await _authService.getCurrentTechnician();
    if (_currentTechnician != null) {
      await _startLocationTracking();
      await loadInstallations();
    }
    notifyListeners();
  }

  // Theme
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Auth
  Future<void> loadTechnicians() async {
    _setLoading(true);
    _clearError();
    try {
      _technicians = await _apiService.getTechnicians();
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  Future<bool> login(Technician technician) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.saveTechnician(technician);
      _currentTechnician = technician;
      await _startLocationTracking();
      await loadInstallations();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _locationService.stopTracking();
    await _authService.logout();
    _currentTechnician = null;
    _installations = [];
    _selectedInstallation = null;
    notifyListeners();
  }

  // Location
  Future<void> _startLocationTracking() async {
    if (_currentTechnician == null) return;

    final hasPermission = await _locationService.requestPermissions();
    if (hasPermission) {
      _locationService.startTracking(_currentTechnician!.id);
    }
  }

  // Installations
  Future<void> loadInstallations() async {
    if (_currentTechnician == null) return;

    _setLoading(true);
    _clearError();
    try {
      _installations = await _apiService.getTechnicianInstallations(
        _currentTechnician!.id,
        date: DateTime.now(),
      );
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  Future<void> loadInstallationDetail(int installationId) async {
    _setLoading(true);
    _clearError();
    try {
      _selectedInstallation = await _apiService.getInstallationDetail(installationId);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  Future<bool> startTimer(int installationId) async {
    _clearError();
    try {
      final updated = await _apiService.startTimer(installationId);
      _selectedInstallation = updated;
      _updateInstallationInList(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> stopTimer(int installationId) async {
    _clearError();
    try {
      final updated = await _apiService.stopTimer(installationId);
      _selectedInstallation = updated;
      _updateInstallationInList(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> completeInstallation(int installationId) async {
    _clearError();
    try {
      final updated = await _apiService.updateInstallation(
        installationId,
        {'status': 'completed'},
      );
      _selectedInstallation = updated;
      _updateInstallationInList(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> updateInstallationStatus(int installationId, String status) async {
    _clearError();
    try {
      await _apiService.updateInstallationStatus(installationId, status);
      // Reload installation detail to get updated data
      await loadInstallationDetail(installationId);
      // Also update in list
      if (_selectedInstallation != null) {
        _updateInstallationInList(_selectedInstallation!);
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void _updateInstallationInList(Installation updated) {
    final index = _installations.indexWhere((i) => i.id == updated.id);
    if (index != -1) {
      _installations[index] = updated;
    }
  }

  // Helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
