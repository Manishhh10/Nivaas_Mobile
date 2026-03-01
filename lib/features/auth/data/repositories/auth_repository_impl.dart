import 'package:dartz/dartz.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/error/failures.dart';
import 'package:nivaas/features/auth/data/datasource/remote/auth_remote_datasource.dart';
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
    String phoneNumber, {
    String? confirmPassword,
  }) async {
    try {
      final request = RegisterRequest(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword ?? password,
        phoneNumber: phoneNumber,
      );
      final response = await remoteDataSource.register(request);

      if (response.user != null) {
        final userEntity = UserEntity(
          id: response.user!.id,
          name: response.user!.name,
          email: response.user!.email,
          phoneNumber: response.user!.phoneNumber,
          role: response.user!.role,
        );
        return Right(userEntity);
      } else {
        return Left(Failure(message: response.message ?? 'Registration failed'));
      }
    } catch (e) {
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) msg = msg.substring(11);
      return Left(Failure(message: msg));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await remoteDataSource.login(request);

      if (response.token != null) {
        // Save token first
        await apiClient.setAuthToken(response.token!);

        // Now call verify to get user data
        final verifyResponse = await remoteDataSource.verify();
        if (verifyResponse.user != null) {
          final u = verifyResponse.user!;
          final userEntity = UserEntity(
            id: u.id,
            name: u.name,
            email: u.email,
            phoneNumber: u.phoneNumber,
            profileImagePath: u.image,
            role: u.role,
          );
          return Right(userEntity);
        } else {
          return Left(Failure(message: 'Failed to fetch user data'));
        }
      } else {
        return Left(Failure(message: response.message ?? 'Login failed'));
      }
    } catch (e) {
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) msg = msg.substring(11);
      return Left(Failure(message: msg));
    }
  }

  @override
  Future<Either<Failure, String>> forgotPassword(String email) async {
    try {
      final result = await remoteDataSource.forgotPassword(email);
      return Right(result['message'] ?? 'OTP sent to email');
    } catch (e) {
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) msg = msg.substring(11);
      return Left(Failure(message: msg));
    }
  }

  @override
  Future<Either<Failure, String>> resetPassword(
    String email,
    String otp,
    String password,
    String confirmPassword,
  ) async {
    try {
      final result = await remoteDataSource.resetPassword(email, otp, password, confirmPassword);
      return Right(result['message'] ?? 'Password reset successful');
    } catch (e) {
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) msg = msg.substring(11);
      return Left(Failure(message: msg));
    }
  }
}
