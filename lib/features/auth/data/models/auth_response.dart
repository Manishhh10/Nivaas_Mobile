/// Login response: { message, data: { token } }
class LoginResponse {
  final String? message;
  final String? token;

  LoginResponse({this.message, this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return LoginResponse(
      message: json['message'],
      token: data is Map<String, dynamic> ? data['token'] : null,
    );
  }
}

/// Register response: { message, user: { _id, name, email, phoneNumber } }
class RegisterResponse {
  final String? message;
  final UserData? user;

  RegisterResponse({this.message, this.user});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
    );
  }
}

/// Verify response: { message, user: {...}, hostStatus: {...} }
class VerifyResponse {
  final String? message;
  final UserData? user;
  final HostStatus? hostStatus;

  VerifyResponse({this.message, this.user, this.hostStatus});

  factory VerifyResponse.fromJson(Map<String, dynamic> json) {
    return VerifyResponse(
      message: json['message'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      hostStatus: json['hostStatus'] != null
          ? HostStatus.fromJson(json['hostStatus'])
          : null,
    );
  }
}

class UserData {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? image;
  final String role;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.image,
    this.role = 'user',
  });

  bool get isAdmin => role.trim().toLowerCase() == 'admin';

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      image: json['image'],
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'image': image,
        'role': role,
      };
}

class HostStatus {
  final String status;
  final String? rejectionReason;
  final bool isVerifiedHost;

  HostStatus({
    required this.status,
    this.rejectionReason,
    required this.isVerifiedHost,
  });

  factory HostStatus.fromJson(Map<String, dynamic> json) {
    return HostStatus(
      status: json['status'] ?? 'none',
      rejectionReason: json['rejectionReason'],
      isVerifiedHost: json['isVerifiedHost'] ?? false,
    );
  }
}