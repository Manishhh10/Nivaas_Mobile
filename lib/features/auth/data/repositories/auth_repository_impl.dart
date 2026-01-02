import 'package:dartz/dartz.dart';
import 'package:nivaas/core/error/failures.dart';
import 'package:nivaas/features/auth/data/datasources/auth_datasource.dart';
import 'package:nivaas/features/auth/domain/entities/user_entity.dart';
import 'package:nivaas/features/auth/domain/repositories/auth_repository.dart';

class AuthRepository implements IAuthRepository {
  final IAuthDataSource dataSource;

  AuthRepository({required this.dataSource});

  @override
  Future<Either<Failure, UserEntity>> signup(
    String email,
    String password,
  ) async {
    try {
      final success = await dataSource.signup(email, password);
      if (success) {
        final user = await dataSource.getUserByEmail(email);
        if (user != null) {
          return Right(user.toEntity());
        }
        return Left(Failure(message: 'Failed to retrieve user'));
      }
      return Left(Failure(message: 'User already exists'));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
  ) async {
    try {
      final success = await dataSource.login(email, password);
      if (success) {
        final user = await dataSource.getUserByEmail(email);
        if (user != null) {
          return Right(user.toEntity());
        }
        return Left(Failure(message: 'Failed to retrieve user'));
      }
      return Left(Failure(message: 'Invalid email or password'));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }
}
