class Technician {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final bool isActive;

  Technician({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.isActive = true,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'] ?? 0,
      name: json['full_name'] ?? json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'is_active': isActive,
    };
  }

  @override
  String toString() => name;
}
