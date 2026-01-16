import 'package:dartz/dartz.dart';
import 'package:nivaas/core/error/failures.dart';
import 'package:nivaas/features/auth/domain/entities/user_entity.dart';

abstract class IAuthRepository {
  Future<Either<Failure, UserEntity>> register(String name, String email, String password, String phoneNumber);
  Future<Either<Failure, UserEntity>> login(String email, String password);
}
