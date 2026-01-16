import 'package:dio/dio.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/features/auth/data/models/auth_response.dart';
import 'package:nivaas/features/auth/data/models/login_request.dart';
import 'package:nivaas/features/auth/data/models/register_request.dart';

abstract class IAuthRemoteDataSource {
  Future<AuthResponse> register(RegisterRequest request);
  Future<AuthResponse> login(LoginRequest request);
}

class AuthRemoteDataSource implements IAuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource({required this.apiClient});

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await apiClient.post(ApiEndpoints.register, data: request.toJson());
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Registration failed');
    }
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await apiClient.post(ApiEndpoints.login, data: request.toJson());
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Login failed');
    }
  }
}