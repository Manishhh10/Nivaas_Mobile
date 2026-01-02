import 'package:dartz/dartz.dart';
import 'package:nivaas/core/error/failures.dart';
import 'package:nivaas/features/auth/domain/entities/user_entity.dart';
import 'package:nivaas/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final IAuthRepository repository;

  LoginUseCase({required this.repository});

  Future<Either<Failure, UserEntity>> call(
    String email,
    String password,
  ) async {
    return repository.login(email, password);
  }
}
