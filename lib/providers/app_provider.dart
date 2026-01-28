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
  DateTime _selectedDate = DateTime.now();

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
  DateTime get selectedDate => _selectedDate;

  List<Installation> get todayInstallations {
    return _installations.where((i) {
      return i.scheduledDate.year == _selectedDate.year &&
          i.scheduledDate.month == _selectedDate.month &&
          i.scheduledDate.day == _selectedDate.day;
    }).toList()
      ..sort((a, b) {
        final timeA = a.scheduledTime ?? '23:59';
        final timeB = b.scheduledTime ?? '23:59';
        return timeA.compareTo(timeB);
      });
  }

  // Verificar si la fecha seleccionada es hoy
  bool get isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  // Cambiar fecha seleccionada
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    loadInstallations();
    notifyListeners();
  }

  // Ir al día anterior
  void previousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    loadInstallations();
    notifyListeners();
  }

  // Ir al día siguiente
  void nextDay() {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    loadInstallations();
    notifyListeners();
  }

  // Ir a hoy
  void goToToday() {
    _selectedDate = DateTime.now();
    loadInstallations();
    notifyListeners();
  }

  // Initialize
  Future<void> _init() async {
    // Verificar si hay sesión guardada
    final hasValidSession = await _authService.isLoggedIn();
    
    if (hasValidSession) {
      // Validar que el token siga siendo válido con el servidor
      final validation = await _apiService.validateToken();
      
      if (validation != null && validation['valid'] == true) {
        // Token válido, cargar datos del técnico
        _currentTechnician = await _authService.getCurrentTechnician();
        if (_currentTechnician != null) {
          await _startLocationTracking();
          await loadInstallations();
        }
      } else {
        // Token inválido, limpiar sesión
        await _authService.logout();
      }
    }
    
    notifyListeners();
  }

  // Theme
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Auth - Nuevo método con PIN
  Future<bool> loginWithPin(String documentId, String pin) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Llamar al API de login
      final response = await _apiService.loginTechnician(
        documentId: documentId,
        pin: pin,
      );
      
      // Guardar token y datos del técnico
      await _authService.saveAuthData(
        token: response['access_token'],
        technicianId: response['technician_id'],
        technicianName: response['technician_name'],
      );
      
      // Crear objeto Technician con los datos recibidos
      _currentTechnician = Technician(
        id: response['technician_id'],
        name: response['technician_name'],
        phone: '', // Se cargará después si es necesario
      );
      
      // Iniciar tracking y cargar instalaciones
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

  // Auth - Legacy (mantener por compatibilidad)
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
    _selectedDate = DateTime.now();
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
        date: _selectedDate,
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
      // Call API to start timer
      await _apiService.startTimer(installationId);
      // Reload full installation to get updated data
      await loadInstallationDetail(installationId);
      // Update in list
      if (_selectedInstallation != null) {
        _updateInstallationInList(_selectedInstallation!);
      }
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
      // Call API to stop timer
      await _apiService.stopTimer(installationId);
      // Reload full installation to get updated data
      await loadInstallationDetail(installationId);
      // Update in list
      if (_selectedInstallation != null) {
        _updateInstallationInList(_selectedInstallation!);
      }
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
