import 'dart:async';
import 'package:flutter/material.dart';
import '../models/installation.dart';
import '../utils/helpers.dart';

class TimerWidget extends StatefulWidget {
  final Installation installation;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final bool isLoading;

  const TimerWidget({
    super.key,
    required this.installation,
    required this.onStart,
    required this.onStop,
    this.isLoading = false,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _initTimer();
  }

  @override
  void didUpdateWidget(TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.installation.timerStartedAt != oldWidget.installation.timerStartedAt) {
      _initTimer();
    }
  }

  void _initTimer() {
    _timer?.cancel();

    if (widget.installation.isTimerRunning && widget.installation.timerStartedAt != null) {
      _updateElapsed();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateElapsed();
      });
    } else {
      _elapsed = Duration.zero;
    }
  }

  void _updateElapsed() {
    if (widget.installation.timerStartedAt != null) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.installation.timerStartedAt!);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = widget.installation.isTimerRunning;
    final isCompleted = widget.installation.status == InstallationStatus.completada;

    if (isCompleted) {
      return _buildCompletedState(theme);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isRunning
              ? [
                  theme.colorScheme.primary.withAlpha(15),
                  theme.colorScheme.primary.withAlpha(8),
                ]
              : [
                  theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                  theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRunning
              ? theme.colorScheme.primary.withAlpha(50)
              : theme.colorScheme.outline.withAlpha(30),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          if (isRunning) ...[
            // Running state
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(
                          (150 + 105 * _pulseController.value).toInt(),
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withAlpha(
                              (50 + 50 * _pulseController.value).toInt(),
                            ),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Text(
                  'Instalacion en curso',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Timer display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(20),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                Helpers.formatDuration(_elapsed),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Stop button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: widget.isLoading ? null : widget.onStop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.stop_rounded, size: 28),
                label: Text(
                  widget.isLoading ? 'Finalizando...' : '✓ FINALIZAR INSTALACIÓN',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Ready to start state
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.timer_outlined,
                size: 56,
                color: theme.colorScheme.primary.withAlpha(180),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Listo para iniciar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Presiona el boton para comenzar el timer',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: widget.isLoading ? null : widget.onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text(
                  widget.isLoading ? 'Iniciando...' : '▶ INICIAR INSTALACIÓN',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD1FAE5),
            Color(0xFFE6FFFA),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF047857).withAlpha(50),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF047857).withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: Color(0xFF047857),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Instalacion completada',
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF047857),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.installation.durationMinutes != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF047857).withAlpha(20),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: Color(0xFF047857),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Duracion: ${Helpers.formatDurationMinutes(widget.installation.durationMinutes)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF047857),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
