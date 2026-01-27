import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VideoCaptureWidget extends StatefulWidget {
  final String? existingVideoUrl;
  final Function(File) onVideoSelected;
  final int maxDurationSeconds;

  const VideoCaptureWidget({
    super.key,
    this.existingVideoUrl,
    required this.onVideoSelected,
    this.maxDurationSeconds = 60,
  });

  @override
  State<VideoCaptureWidget> createState() => _VideoCaptureWidgetState();
}

class _VideoCaptureWidgetState extends State<VideoCaptureWidget> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedVideo;
  bool _isRecording = false;

  Future<void> _recordVideo() async {
    setState(() => _isRecording = true);
    
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: Duration(seconds: widget.maxDurationSeconds),
      );

      if (video != null) {
        setState(() {
          _selectedVideo = File(video.path);
        });
        widget.onVideoSelected(_selectedVideo!);
      }
    } finally {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: Duration(seconds: widget.maxDurationSeconds),
    );

    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
      });
      widget.onVideoSelected(_selectedVideo!);
    }
  }

  void _removeVideo() {
    setState(() {
      _selectedVideo = null;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show existing video from server
    if (widget.existingVideoUrl != null && _selectedVideo == null) {
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
                  'Video de Instalacion',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF047857),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam, color: Color(0xFF047857), size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Video guardado',
                      style: TextStyle(color: Color(0xFF047857)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_filled, color: Color(0xFF047857), size: 32),
                    onPressed: () {
                      // TODO: Open video player
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reproducir video pendiente')),
                      );
                    },
                  ),
                ],
              ),
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
              Icon(Icons.videocam_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Video de Instalacion',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                'Max ${widget.maxDurationSeconds}s',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selected video preview
          if (_selectedVideo != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Video seleccionado',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        FutureBuilder<int>(
                          future: _selectedVideo!.length(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                _formatFileSize(snapshot.data!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _removeVideo,
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isRecording ? null : _recordVideo,
                  icon: Icon(_isRecording ? Icons.fiber_manual_record : Icons.videocam),
                  label: Text(_isRecording ? 'Grabando...' : 'Grabar'),
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
                child: OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.video_library),
                  label: const Text('Galeria'),
                  style: OutlinedButton.styleFrom(
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
