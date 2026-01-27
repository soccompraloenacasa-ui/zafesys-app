import 'package:flutter/material.dart';
import '../models/installation.dart';

class StatusBadge extends StatelessWidget {
  final InstallationStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _getText(),
        style: TextStyle(
          color: _getTextColor(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (status) {
      case InstallationStatus.pendiente:
        return const Color(0xFFFEF3C7); // Amber 100
      case InstallationStatus.programada:
        return const Color(0xFFE0E7FF); // Indigo 100
      case InstallationStatus.enCamino:
        return const Color(0xFFFED7AA); // Orange 200
      case InstallationStatus.enProgreso:
        return const Color(0xFFCFFAFE); // Cyan 100
      case InstallationStatus.completada:
        return const Color(0xFFD1FAE5); // Green 100
      case InstallationStatus.cancelada:
        return const Color(0xFFFEE2E2); // Red 100
    }
  }

  Color _getTextColor() {
    switch (status) {
      case InstallationStatus.pendiente:
        return const Color(0xFFB45309); // Amber 700
      case InstallationStatus.programada:
        return const Color(0xFF4338CA); // Indigo 700
      case InstallationStatus.enCamino:
        return const Color(0xFFC2410C); // Orange 700
      case InstallationStatus.enProgreso:
        return const Color(0xFF0E7490); // Cyan 700
      case InstallationStatus.completada:
        return const Color(0xFF047857); // Green 700
      case InstallationStatus.cancelada:
        return const Color(0xFFB91C1C); // Red 700
    }
  }

  String _getText() {
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
}
