import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SignatureWidget extends StatefulWidget {
  final String? existingSignatureUrl;
  final Function(Uint8List) onSignatureSaved;
  final VoidCallback? onClear;

  const SignatureWidget({
    super.key,
    this.existingSignatureUrl,
    required this.onSignatureSaved,
    this.onClear,
  });

  @override
  State<SignatureWidget> createState() => _SignatureWidgetState();
}

class _SignatureWidgetState extends State<SignatureWidget> {
  List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _hasSigned = false;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
      _hasSigned = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _strokes.add(List.from(_currentStroke));
      _currentStroke = [];
    });
  }

  void _clear() {
    setState(() {
      _strokes = [];
      _currentStroke = [];
      _hasSigned = false;
    });
    widget.onClear?.call();
  }

  Future<void> _save() async {
    if (_strokes.isEmpty) return;

    // Create image from signature
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw white background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 400, 200),
      Paint()..color = Colors.white,
    );

    // Draw strokes
    for (final stroke in _strokes) {
      if (stroke.length > 1) {
        final path = Path();
        path.moveTo(stroke[0].dx, stroke[0].dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(400, 200);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      widget.onSignatureSaved(byteData.buffer.asUint8List());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show existing signature
    if (widget.existingSignatureUrl != null && !_hasSigned) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF047857).withAlpha(50)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF047857)),
                const SizedBox(width: 8),
                Text(
                  'Firma del Cliente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF047857),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.existingSignatureUrl!,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Firma registrada',
              style: TextStyle(color: Color(0xFF047857)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.draw_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Firma del Cliente',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: _SignaturePainter(_strokes, _currentStroke),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Limpiar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _strokes.isNotEmpty ? _save : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Guardar Firma'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _SignaturePainter(this.strokes, this.currentStroke);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length > 1) {
        final path = Path();
        path.moveTo(stroke[0].dx, stroke[0].dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    if (currentStroke.length > 1) {
      final path = Path();
      path.moveTo(currentStroke[0].dx, currentStroke[0].dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
