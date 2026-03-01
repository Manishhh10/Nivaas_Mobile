import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:nivaas/core/services/connectivity/connectivity_service.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';

class ApiClient {
  // LAN IP of the PC running the backend (same Wi-Fi network).
  // Update this if your PC's IP changes.
  static const String _manualBaseUrl = 'http://192.168.1.75:5000/api';
  static const String _defaultBaseUrl = 'http://localhost:5000/api';
  static const String _emulatorBaseUrl = 'http://10.0.2.2:5000/api';
  static const String _loopbackBaseUrl = 'http://127.0.0.1:5000/api';
  static const String _altBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL_ALT');
  static const String _baseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

  /// The base URL that last succeeded in reaching the backend.
  /// Used by NivaasImage to build correct image URLs on any device.
  static String? _resolvedBaseUrl;
  static String get resolvedBaseUrl => _resolvedBaseUrl ?? baseUrl;

  static String get baseUrl {
    if (_manualBaseUrl.trim().isNotEmpty) {
      return _manualBaseUrl;
    }
    if (_baseUrlFromEnv.trim().isNotEmpty) {
      return _baseUrlFromEnv;
    }
    return _defaultBaseUrl;
  }

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
    _dio.options.baseUrl = _preferredBaseUrl();
    _dio.options.connectTimeout = const Duration(seconds: 3);
    _dio.options.receiveTimeout = const Duration(seconds: 20);

    if (kDebugMode) {
      debugPrint('ApiClient baseUrl => ${_dio.options.baseUrl}');
    }

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Intentionally do not hard-block requests by connectivity status.
        // For local development backends (10.0.2.2 / LAN IP), connectivity_plus
        // can report false negatives and cause login timeouts/failures.
        await _connectivity.isConnected();

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
    return _requestWithFallback(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _requestWithFallback(
      method: 'POST',
      path: path,
      data: data,
    );
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _requestWithFallback(
      method: 'PUT',
      path: path,
      data: data,
    );
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return _requestWithFallback(
      method: 'PATCH',
      path: path,
      data: data,
    );
  }

  Future<Response> delete(String path) async {
    return _requestWithFallback(method: 'DELETE', path: path);
  }

  List<String> _candidateBaseUrls() {
    final candidates = <String>[
      _preferredBaseUrl(),
      if (_baseUrlFromEnv.trim().isNotEmpty) _baseUrlFromEnv,
      if (_altBaseUrlFromEnv.trim().isNotEmpty) _altBaseUrlFromEnv,
      _loopbackBaseUrl,
      _emulatorBaseUrl,
      baseUrl,
      _defaultBaseUrl,
    ];

    final unique = <String>[];
    for (final candidate in candidates) {
      final url = _normalizeBaseUrl(candidate);
      if (url.isEmpty) continue;
      if (!unique.contains(url)) unique.add(url);
    }
    return unique;
  }

  String _preferredBaseUrl() {
    if (_manualBaseUrl.trim().isNotEmpty) {
      return _normalizeBaseUrl(_manualBaseUrl);
    }
    if (_baseUrlFromEnv.trim().isNotEmpty) {
      return _normalizeBaseUrl(_baseUrlFromEnv);
    }
    return _normalizeBaseUrl(_defaultBaseUrl);
  }

  String _normalizeBaseUrl(String url) {
    var next = url.trim();
    if (next.isEmpty) return next;
    if (!next.startsWith('http://') && !next.startsWith('https://')) {
      next = 'http://$next';
    }
    if (!next.endsWith('/api')) {
      if (next.endsWith('/')) {
        next = '${next}api';
      } else {
        next = '$next/api';
      }
    }
    return next;
  }

  bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  Future<Response> _requestWithFallback({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    DioException? lastNetworkError;

    for (final candidateBaseUrl in _candidateBaseUrls()) {
      _dio.options.baseUrl = candidateBaseUrl;
      try {
        late final Response response;
        switch (method) {
          case 'GET':
            response = await _dio.get(path, queryParameters: queryParameters);
          case 'POST':
            response = await _dio.post(path, data: data);
          case 'PUT':
            response = await _dio.put(path, data: data);
          case 'PATCH':
            response = await _dio.patch(path, data: data);
          case 'DELETE':
            response = await _dio.delete(path);
          default:
            throw UnsupportedError('Unsupported HTTP method: $method');
        }
        // Remember which base URL actually worked
        _resolvedBaseUrl = candidateBaseUrl;
        return response;
      } on DioException catch (error) {
        if (_isNetworkError(error)) {
          lastNetworkError = error;
          continue;
        }
        rethrow;
      }
    }

    if (lastNetworkError != null) {
      throw DioException(
        requestOptions: lastNetworkError.requestOptions,
        response: lastNetworkError.response,
        type: lastNetworkError.type,
        error:
            'Unable to reach backend. Tried: ${_candidateBaseUrls().join(', ')}',
        message: lastNetworkError.message,
      );
    }

    throw Exception('Request failed before network call');
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
