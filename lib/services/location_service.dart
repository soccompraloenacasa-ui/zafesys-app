import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../models/location.dart';
import 'api_service.dart';

class LocationService {
  final ApiService _apiService;
  Timer? _locationTimer;
  int? _technicianId;

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

    // Schedule periodic updates
    _locationTimer = Timer.periodic(
      Duration(minutes: ApiConfig.locationUpdateIntervalMinutes),
      (_) => _sendCurrentLocation(),
    );
  }

  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _technicianId = null;
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

      final location = TechnicianLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      await _apiService.sendLocation(_technicianId!, location);
    } catch (_) {
      // Silently fail - we don't want to interrupt the user
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
