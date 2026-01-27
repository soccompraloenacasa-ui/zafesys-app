import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import '../config/api_config.dart';
import '../models/location.dart';
import 'api_service.dart';

class LocationService {
  final ApiService _apiService;
  final Battery _battery = Battery();
  Timer? _locationTimer;
  int? _technicianId;
  int? _currentInstallationId;

  LocationService(this._apiService);

  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  void startTracking(int technicianId) {
    _technicianId = technicianId;
    _locationTimer?.cancel();

    // Send initial location
    _sendCurrentLocation();

    // Schedule periodic updates every 5 minutes
    _locationTimer = Timer.periodic(
      Duration(minutes: ApiConfig.locationUpdateIntervalMinutes),
      (_) => _sendCurrentLocation(),
    );
  }

  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _technicianId = null;
    _currentInstallationId = null;
  }

  /// Set current installation being worked on (for tracking purposes)
  void setCurrentInstallation(int? installationId) {
    _currentInstallationId = installationId;
  }

  /// Force send location now (useful when starting an installation)
  Future<void> sendLocationNow() async {
    await _sendCurrentLocation();
  }

  Future<void> _sendCurrentLocation() async {
    if (_technicianId == null) return;

    // Check if within working hours (Colombia timezone UTC-5)
    final now = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    final hour = now.hour;

    if (hour < ApiConfig.workStartHour || hour >= ApiConfig.workEndHour) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Get battery level
      int? batteryLevel;
      try {
        batteryLevel = await _battery.batteryLevel;
      } catch (_) {
        // Battery info not available
      }

      final location = TechnicianLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed > 0 ? position.speed : null,
        heading: position.heading > 0 ? position.heading : null,
        altitude: position.altitude != 0 ? position.altitude : null,
        batteryLevel: batteryLevel,
        installationId: _currentInstallationId,
        timestamp: DateTime.now(),
      );

      await _apiService.sendLocation(_technicianId!, location);
    } catch (e) {
      // Silently fail - we don't want to interrupt the user
      print('Error obteniendo/enviando ubicación: $e');
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      return null;
    }
  }
}
