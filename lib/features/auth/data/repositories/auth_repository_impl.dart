import 'package:dartz/dartz.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/error/failures.dart';
import 'package:nivaas/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:nivaas/features/auth/data/models/login_request.dart';
import 'package:nivaas/features/auth/data/models/register_request.dart';
import 'package:nivaas/features/auth/domain/entities/user_entity.dart';
import 'package:nivaas/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final ApiClient apiClient;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.apiClient,
  });

  @override
  Future<Either<Failure, UserEntity>> register(
    String name,
    String email,
    String password,
    String phoneNumber,
  ) async {
    try {
      final request = RegisterRequest(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      final response = await remoteDataSource.register(request);

      if (response.success && response.data != null && response.token != null) {
        // Save token
        await apiClient.setAuthToken(response.token!);

        final userEntity = UserEntity(
          id: response.data!.id,
          name: response.data!.name,
          email: response.data!.email,
          phoneNumber: response.data!.phoneNumber,
        );
        return Right(userEntity);
      } else {
        return Left(Failure(message: response.message ?? 'Registration failed'));
      }
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await remoteDataSource.login(request);

      if (response.success && response.data != null && response.token != null) {
        // Save token
        await apiClient.setAuthToken(response.token!);

        final userEntity = UserEntity(
          id: response.data!.id,
          name: response.data!.name,
          email: response.data!.email,
          phoneNumber: response.data!.phoneNumber,
        );
        return Right(userEntity);
      } else {
        return Left(Failure(message: response.message ?? 'Login failed'));
      }
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }
}
