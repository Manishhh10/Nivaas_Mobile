class AuthResponse {
  final bool success;
  final String? token;
  final UserData? data;
  final String? message;

  AuthResponse({
    required this.success,
    this.token,
    this.data,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      token: json['token'],
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
      message: json['message'],
    );
  }
}

class UserData {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }
}