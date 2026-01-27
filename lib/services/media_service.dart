import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class MediaService {
  // Timeouts para uploads
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const Duration _uploadTimeout = Duration(seconds: 120); // 2 min para archivos grandes
  static const Duration _videoUploadTimeout = Duration(seconds: 300); // 5 min para videos

  /// Get presigned upload URL from backend
  static Future<Map<String, String>> getUploadUrl({
    required int installationId,
    required String fileType,
    required String clientName,
  }) async {
    try {
      // RUTA CORREGIDA: /tech/ en lugar de /app/
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tech/installations/$installationId/upload-url'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file_type': fileType,
          'client_name': clientName,
        }),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'upload_url': data['upload_url'] as String,
          'public_url': data['public_url'] as String,
        };
      } else if (response.statusCode == 404) {
        throw Exception('Instalación no encontrada');
      } else {
        final errorBody = response.body;
        throw Exception('Error del servidor: $errorBody');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      }
      rethrow;
    }
  }

  /// Upload bytes directly to R2 with retry logic
  static Future<bool> uploadToR2(
    String uploadUrl,
    Uint8List bytes,
    {bool isPng = false, bool isVideo = false, int maxRetries = 3}
  ) async {
    String contentType = 'image/jpeg';
    if (isPng) contentType = 'image/png';
    if (isVideo) contentType = 'video/mp4';

    final timeout = isVideo ? _videoUploadTimeout : _uploadTimeout;

    int retryCount = 0;
    Exception? lastError;

    while (retryCount < maxRetries) {
      try {
        final response = await http.put(
          Uri.parse(uploadUrl),
          headers: {'Content-Type': contentType},
          body: bytes,
        ).timeout(timeout);

        if (response.statusCode == 200) {
          return true;
        } else {
          throw Exception('Upload falló con código: ${response.statusCode}');
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        retryCount++;

        if (retryCount < maxRetries) {
          // Esperar antes de reintentar (exponential backoff)
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }
    }

    throw lastError ?? Exception('Upload falló después de $maxRetries intentos');
  }

  /// Save media reference to backend
  static Future<bool> saveMediaReference({
    required int installationId,
    String? signatureUrl,
    List<String>? photosBefore,
    List<String>? photosAfter,
    String? videoUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (signatureUrl != null) body['signature_url'] = signatureUrl;
      if (photosBefore != null && photosBefore.isNotEmpty) body['photos_before'] = photosBefore;
      if (photosAfter != null && photosAfter.isNotEmpty) body['photos_after'] = photosAfter;
      if (videoUrl != null) body['video_url'] = videoUrl;

      // RUTA CORREGIDA: /tech/ en lugar de /app/
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tech/installations/$installationId/save-media'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorBody = response.body;
        throw Exception('Error guardando media: $errorBody');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Tiempo de espera agotado al guardar.');
      }
      rethrow;
    }
  }

  /// Validar tamaño de archivo antes de subir
  static bool validateFileSize(Uint8List bytes, {bool isVideo = false}) {
    final maxSize = isVideo
        ? 200 * 1024 * 1024  // 200 MB para video
        : 10 * 1024 * 1024;  // 10 MB para fotos/firma
    return bytes.length <= maxSize;
  }

  /// Obtener tamaño formateado
  static String getFileSizeString(Uint8List bytes) {
    final sizeInKB = bytes.length / 1024;
    if (sizeInKB > 1024) {
      return '${(sizeInKB / 1024).toStringAsFixed(1)} MB';
    }
    return '${sizeInKB.toStringAsFixed(0)} KB';
  }
}
