class TechnicianLocation {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  TechnicianLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }

  factory TechnicianLocation.fromJson(Map<String, dynamic> json) {
    return TechnicianLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
