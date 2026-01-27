class ApiConfig {
  static const String baseUrl = 'https://zafesys-suite-production.up.railway.app/api/v1';
  
  // Endpoints públicos (para app de técnicos - sin auth)
  static const String techniciansList = '/technicians/app/list';
  static const String technicianInstallations = '/technicians/app'; // + /{id}/installations
  
  // Endpoints autenticados
  static const String technicians = '/technicians';
  static const String installations = '/installations';
  
  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  
  // GPS Tracking
  static const int locationUpdateIntervalMinutes = 5;
  static const int workStartHour = 7;  // 7 AM Colombia
  static const int workEndHour = 19;   // 7 PM Colombia
}