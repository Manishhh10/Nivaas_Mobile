import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:nivaas/core/services/hive/hive_service.dart';

class ApiService {
  final String baseUrl = 'http://10.0.2.2:3002/api/v1'; // For Android emulator

  Future<String?> getToken() async {
    final hiveService = HiveService();
    return hiveService.getToken();
  }

  Future<String?> uploadProfilePicture(File image) async {
    final token = await getToken();
    if (token == null) return null;

    final uri = Uri.parse('$baseUrl/profile');
    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(await http.MultipartFile.fromPath('profileImage', image.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      return data['data']['profileImage'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    final uri = Uri.parse('$baseUrl/profile');
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
      return responseData['data'];
    }
    throw Exception('Failed to update profile');
  }
}