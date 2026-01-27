import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoCaptureWidget extends StatefulWidget {
  final String title;
  final List<String> existingPhotos;
  final Function(List<File>) onPhotosChanged;
  final int maxPhotos;

  const PhotoCaptureWidget({
    super.key,
    required this.title,
    required this.existingPhotos,
    required this.onPhotosChanged,
    this.maxPhotos = 5,
  });

  @override
  State<PhotoCaptureWidget> createState() => _PhotoCaptureWidgetState();
}

class _PhotoCaptureWidgetState extends State<PhotoCaptureWidget> {
  final ImagePicker _picker = ImagePicker();
  List<File> _newPhotos = [];

  Future<void> _takePhoto() async {
    if (_newPhotos.length + widget.existingPhotos.length >= widget.maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximo ${widget.maxPhotos} fotos')),
      );
      return;
    }

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1920,
    );

    if (photo != null) {
      setState(() {
        _newPhotos.add(File(photo.path));
      });
      widget.onPhotosChanged(_newPhotos);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_newPhotos.length + widget.existingPhotos.length >= widget.maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximo ${widget.maxPhotos} fotos')),
      );
      return;
    }

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
    );

    if (photo != null) {
      setState(() {
        _newPhotos.add(File(photo.path));
      });
      widget.onPhotosChanged(_newPhotos);
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _newPhotos.removeAt(index);
    });
    widget.onPhotosChanged(_newPhotos);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPhotos = widget.existingPhotos.length + _newPhotos.length;

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
              Icon(Icons.camera_alt_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '$totalPhotos/${widget.maxPhotos}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Existing photos from server
          if (widget.existingPhotos.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.existingPhotos.map((url) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // New photos
          if (_newPhotos.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _newPhotos.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        entry.value,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removePhoto(entry.key),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camara'),
                  style: OutlinedButton.styleFrom(
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
                  icon: const Icon(Icons.photo_library),
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
