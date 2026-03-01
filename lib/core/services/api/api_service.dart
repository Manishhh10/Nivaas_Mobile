import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';

class ApiService {
  final String baseUrl = 'http://10.0.2.2:5000/api'; // For Android emulator

  Future<String?> getToken() async {
    final hiveService = HiveService();
    return hiveService.getToken();
  }

  /// Resolves the MIME content type from a file extension for image uploads.
  MediaType _imageMediaType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
        return MediaType('image', 'heic');
      case 'heif':
        return MediaType('image', 'heif');
      default:
        return MediaType('image', 'jpeg'); // safe default for photos
    }
  }

  Future<String?> uploadProfilePicture(File image, String userId) async {
    final token = await getToken();
    if (token == null) return null;

    final uri = Uri.parse('$baseUrl/auth/$userId');
    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      image.path,
      contentType: _imageMediaType(image.path),
    ));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      return data['user']?['image'];
    }
    final responseData = await response.stream.bytesToString();
    String message = 'Failed to upload profile picture';
    try {
      final data = json.decode(responseData);
      message = data['message']?.toString() ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<Map<String, dynamic>?> updateProfile(String userId, Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    final uri = Uri.parse('$baseUrl/auth/$userId');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['user'];
    }
    String message = 'Failed to update profile';
    try {
      final responseData = json.decode(response.body);
      message = responseData['message']?.toString() ?? message;
    } catch (_) {}
    throw Exception(message);
  }
}