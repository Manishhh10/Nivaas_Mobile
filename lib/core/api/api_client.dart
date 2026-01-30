import 'package:dio/dio.dart';
import 'package:nivaas/core/services/connectivity/connectivity_service.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:3002/api/v1'; // For Android emulator
  final Dio _dio;
  final HiveService _hiveService;
  final ConnectivityService _connectivity;

  ApiClient()
      : _dio = Dio(),
        _hiveService = HiveService(),
        _connectivity = ConnectivityService() {
    _setupDio();
  }

  void _setupDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Check connectivity
        final isConnected = await _connectivity.isConnected();
        if (!isConnected) {
          return handler.reject(
            DioException(
              requestOptions: options,
              error: 'No internet connection',
              type: DioExceptionType.connectionError,
            ),
          );
        }

        // Add auth token if available
        final token = _hiveService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, clear storage
          _hiveService.logout();
          // You might want to navigate to login screen here
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }

  Future<void> setAuthToken(String token) async {
    await _hiveService.saveToken(token);
  }

  Future<String?> getAuthToken() async {
    return _hiveService.getToken();
  }

  Future<void> clearAuthToken() async {
    _hiveService.logout();
  }
}
