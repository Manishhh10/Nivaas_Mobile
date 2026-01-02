import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String email;
  final String password;
  final DateTime createdAt;

  const UserEntity({
    required this.email,
    required this.password,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [email, password, createdAt];
}
