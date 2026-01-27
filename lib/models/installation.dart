enum InstallationStatus {
  pendiente,
  programada,
  enCamino,
  enProgreso,
  completada,
  cancelada,
}

class Installation {
  final int id;
  final String clientName;
  final String? clientPhone;
  final String? clientEmail;
  final String address;
  final String city;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final InstallationStatus status;
  final String? productName;
  final String? productModel;
  final String? productImageUrl;
  final String? notes;
  final String? addressNotes;
  final DateTime? timerStartedAt;
  final DateTime? timerStoppedAt;
  final int? durationMinutes;
  final double? totalPrice;
  final double? amountPaid;
  final String? paymentStatus;
  final String? signatureUrl;
  final List<String>? photosBefore;
  final List<String>? photosAfter;

  Installation({
    required this.id,
    required this.clientName,
    this.clientPhone,
    this.clientEmail,
    required this.address,
    required this.city,
    required this.scheduledDate,
    this.scheduledTime,
    required this.status,
    this.productName,
    this.productModel,
    this.productImageUrl,
    this.notes,
    this.addressNotes,
    this.timerStartedAt,
    this.timerStoppedAt,
    this.durationMinutes,
    this.totalPrice,
    this.amountPaid,
    this.paymentStatus,
    this.signatureUrl,
    this.photosBefore,
    this.photosAfter,
  });

  factory Installation.fromJson(Map<String, dynamic> json) {
    // Handle nested lead object or direct fields
    final lead = json['lead'] as Map<String, dynamic>?;
    final clientName = json['lead_name'] ?? lead?['name'] ?? json['client_name'] ?? json['clientName'] ?? '';
    final clientPhone = json['lead_phone'] ?? lead?['phone'] ?? json['client_phone'] ?? json['clientPhone'];
    final clientEmail = lead?['email'] ?? json['client_email'] ?? json['clientEmail'];

    // Handle nested product object or direct fields
    final product = json['product'] as Map<String, dynamic>?;
    final productName = json['product_name'] ?? product?['name'] ?? json['productName'];
    final productModel = json['product_model'] ?? product?['model'];
    final productImageUrl = json['product_image'] ?? json['product_image_url'] ?? product?['image_url'];

    // Handle notes (API uses customer_notes)
    final notes = json['customer_notes'] ?? json['notes'];
    final addressNotes = json['address_notes'];

    // Handle photos arrays
    List<String>? photosBefore;
    if (json['photos_before'] != null) {
      photosBefore = List<String>.from(json['photos_before']);
    }
    
    List<String>? photosAfter;
    if (json['photos_after'] != null) {
      photosAfter = List<String>.from(json['photos_after']);
    }

    return Installation(
      id: json['id'] ?? 0,
      clientName: clientName,
      clientPhone: clientPhone,
      clientEmail: clientEmail,
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      scheduledDate: DateTime.parse(json['scheduled_date'] ?? json['scheduledDate'] ?? DateTime.now().toIso8601String()),
      scheduledTime: json['scheduled_time'] ?? json['scheduledTime'],
      status: _parseStatus(json['status']),
      productName: productName,
      productModel: productModel,
      productImageUrl: productImageUrl,
      notes: notes,
      addressNotes: addressNotes,
      timerStartedAt: json['timer_started_at'] != null
          ? DateTime.parse(json['timer_started_at'])
          : (json['timerStartedAt'] != null ? DateTime.parse(json['timerStartedAt']) : null),
      timerStoppedAt: json['timer_ended_at'] != null
          ? DateTime.parse(json['timer_ended_at'])
          : (json['timer_stopped_at'] != null ? DateTime.parse(json['timer_stopped_at']) : null),
      durationMinutes: json['installation_duration_minutes'] ?? json['duration_minutes'] ?? json['durationMinutes'],
      totalPrice: json['total_price'] != null ? double.tryParse(json['total_price'].toString()) : null,
      amountPaid: json['amount_paid'] != null ? double.tryParse(json['amount_paid'].toString()) : null,
      paymentStatus: json['payment_status'],
      signatureUrl: json['signature_url'],
      photosBefore: photosBefore,
      photosAfter: photosAfter,
    );
  }

  static InstallationStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'programada':
        return InstallationStatus.programada;
      case 'en_camino':
      case 'encamino':
        return InstallationStatus.enCamino;
      case 'in_progress':
      case 'inprogress':
      case 'en_progreso':
      case 'enprogreso':
        return InstallationStatus.enProgreso;
      case 'completed':
      case 'completada':
      case 'completado':
        return InstallationStatus.completada;
      case 'cancelled':
      case 'cancelada':
      case 'cancelado':
        return InstallationStatus.cancelada;
      default:
        return InstallationStatus.pendiente;
    }
  }

  bool get isTimerRunning => timerStartedAt != null && timerStoppedAt == null;

  String get statusText {
    switch (status) {
      case InstallationStatus.pendiente:
        return 'Pendiente';
      case InstallationStatus.programada:
        return 'Programada';
      case InstallationStatus.enCamino:
        return 'En Camino';
      case InstallationStatus.enProgreso:
        return 'En Progreso';
      case InstallationStatus.completada:
        return 'Completada';
      case InstallationStatus.cancelada:
        return 'Cancelada';
    }
  }

  String get statusValue {
    switch (status) {
      case InstallationStatus.pendiente:
        return 'pendiente';
      case InstallationStatus.programada:
        return 'programada';
      case InstallationStatus.enCamino:
        return 'en_camino';
      case InstallationStatus.enProgreso:
        return 'en_progreso';
      case InstallationStatus.completada:
        return 'completada';
      case InstallationStatus.cancelada:
        return 'cancelada';
    }
  }

  // Get next status in the flow
  InstallationStatus? get nextStatus {
    switch (status) {
      case InstallationStatus.pendiente:
      case InstallationStatus.programada:
        return InstallationStatus.enCamino;
      case InstallationStatus.enCamino:
        return InstallationStatus.enProgreso;
      case InstallationStatus.enProgreso:
        return InstallationStatus.completada;
      default:
        return null;
    }
  }

  Installation copyWith({
    int? id,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? address,
    String? city,
    DateTime? scheduledDate,
    String? scheduledTime,
    InstallationStatus? status,
    String? productName,
    String? productModel,
    String? productImageUrl,
    String? notes,
    String? addressNotes,
    DateTime? timerStartedAt,
    DateTime? timerStoppedAt,
    int? durationMinutes,
    double? totalPrice,
    double? amountPaid,
    String? paymentStatus,
    String? signatureUrl,
    List<String>? photosBefore,
    List<String>? photosAfter,
  }) {
    return Installation(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      address: address ?? this.address,
      city: city ?? this.city,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      productName: productName ?? this.productName,
      productModel: productModel ?? this.productModel,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      notes: notes ?? this.notes,
      addressNotes: addressNotes ?? this.addressNotes,
      timerStartedAt: timerStartedAt ?? this.timerStartedAt,
      timerStoppedAt: timerStoppedAt ?? this.timerStoppedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalPrice: totalPrice ?? this.totalPrice,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      photosBefore: photosBefore ?? this.photosBefore,
      photosAfter: photosAfter ?? this.photosAfter,
    );
  }
}
