import 'package:dartz/dartz.dart';
import 'package:nivaas/core/error/failures.dart';
import 'package:nivaas/features/auth/domain/entities/user_entity.dart';

abstract class IAuthRepository {
  Future<Either<Failure, UserEntity>> signup(String email, String password);
  Future<Either<Failure, UserEntity>> login(String email, String password);
}
