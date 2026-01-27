import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class MediaService {
  /// Get presigned upload URL from backend
  static Future<Map<String, String>> getUploadUrl({
    required int installationId,
    required String fileType,
    required String clientName,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/app/installations/$installationId/upload-url'),
      headers: {'Content-Type': 'application/json'},
      body: '{"file_type": "$fileType", "client_name": "$clientName"}',
    );

    if (response.statusCode == 200) {
      final data = response.body;
      // Parse JSON manually to avoid dependency
      final uploadUrl = _extractJsonValue(data, 'upload_url');
      final publicUrl = _extractJsonValue(data, 'public_url');
      return {'upload_url': uploadUrl, 'public_url': publicUrl};
    }
    throw Exception('Failed to get upload URL');
  }

  /// Upload image bytes directly to R2
  static Future<bool> uploadToR2(String uploadUrl, Uint8List imageBytes, {bool isPng = false}) async {
    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': isPng ? 'image/png' : 'image/jpeg'},
      body: imageBytes,
    );
    return response.statusCode == 200;
  }

  /// Save media reference to backend
  static Future<bool> saveMediaReference({
    required int installationId,
    String? signatureUrl,
    List<String>? photosBefore,
    List<String>? photosAfter,
  }) async {
    final body = <String, dynamic>{};
    if (signatureUrl != null) body['signature_url'] = signatureUrl;
    if (photosBefore != null) body['photos_before'] = photosBefore;
    if (photosAfter != null) body['photos_after'] = photosAfter;

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/app/installations/$installationId/save-media'),
      headers: {'Content-Type': 'application/json'},
      body: _toJson(body),
    );
    return response.statusCode == 200;
  }

  static String _extractJsonValue(String json, String key) {
    final regex = RegExp('"$key"\\s*:\\s*"([^"]+)"');
    final match = regex.firstMatch(json);
    return match?.group(1) ?? '';
  }

  static String _toJson(Map<String, dynamic> map) {
    final entries = map.entries.map((e) {
      if (e.value is List) {
        final list = (e.value as List).map((v) => '"$v"').join(',');
        return '"${e.key}": [$list]';
      }
      return '"${e.key}": "${e.value}"';
    }).join(',');
    return '{$entries}';
  }
}
