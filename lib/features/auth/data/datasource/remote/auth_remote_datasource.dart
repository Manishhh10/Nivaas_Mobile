import 'package:dio/dio.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/features/auth/data/models/auth_response.dart';
import 'package:nivaas/features/auth/data/models/login_request.dart';
import 'package:nivaas/features/auth/data/models/register_request.dart';

abstract class IAuthRemoteDataSource {
  Future<RegisterResponse> register(RegisterRequest request);
  Future<LoginResponse> login(LoginRequest request);
  Future<VerifyResponse> verify();
  Future<Map<String, dynamic>> forgotPassword(String email);
  Future<Map<String, dynamic>> resetPassword(String email, String otp, String password, String confirmPassword);
}

class AuthRemoteDataSource implements IAuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource({required this.apiClient});

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await apiClient.post(ApiEndpoints.register, data: request.toJson());
      return RegisterResponse.fromJson(response.data);
    } on DioException catch (e) {
      final msg = _extractError(e, 'Registration failed');
      throw Exception(msg);
    }
  }

  String _extractError(DioException e, String fallback) {
    // Connection errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Backend may be unreachable from this device. For physical phone, use LAN IP with --dart-define=API_BASE_URL=http://<PC_LAN_IP>:5000/api';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server from this device. If using USB, run: adb reverse tcp:5000 tcp:5000';
    }
    // Try to extract message from response
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        return data['message'];
      }
      if (data is String && data.isNotEmpty) {
        return data;
      }
    } catch (_) {}
    return e.message ?? fallback;
  }

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await apiClient.post(ApiEndpoints.login, data: request.toJson());
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e, 'Login failed'));
    }
  }

  @override
  Future<VerifyResponse> verify() async {
    try {
      final response = await apiClient.get(ApiEndpoints.verify);
      return VerifyResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e, 'Verification failed'));
    }
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await apiClient.post(ApiEndpoints.forgotPassword, data: {'email': email});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e, 'Failed to send OTP'));
    }
  }

  @override
  Future<Map<String, dynamic>> resetPassword(String email, String otp, String password, String confirmPassword) async {
    try {
      final response = await apiClient.post(ApiEndpoints.resetPassword, data: {
        'email': email,
        'otp': otp,
        'password': password,
        'confirmPassword': confirmPassword,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e, 'Failed to reset password'));
    }
  }
}