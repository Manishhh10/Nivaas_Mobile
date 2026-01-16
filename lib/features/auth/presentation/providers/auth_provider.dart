import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:nivaas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nivaas/features/auth/domain/repositories/auth_repository.dart';
import 'package:nivaas/features/auth/domain/usecases/login_usecase.dart';
import 'package:nivaas/features/auth/domain/usecases/signup_usecase.dart';
import 'package:nivaas/features/auth/presentation/view_model/auth_state.dart';

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Remote Data Source Provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSource(apiClient: apiClient);
});

// Repository Provider
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    apiClient: apiClient,
  );
});

// Use Cases Providers
final signupUseCaseProvider = Provider<SignupUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignupUseCase(repository: repository);
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository: repository);
});

// Auth State Notifier Provider
class AuthNotifier extends Notifier<AuthState> {
  late SignupUseCase _signupUseCase;
  late LoginUseCase _loginUseCase;

  @override
  AuthState build() {
    _signupUseCase = ref.watch(signupUseCaseProvider);
    _loginUseCase = ref.watch(loginUseCaseProvider);
    return const AuthState();
  }

  Future<void> signup(String name, String email, String password, String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _signupUseCase(name, email, password, phoneNumber);

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.success,
        userEmail: user.email,
      ),
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    final result = await _loginUseCase(email, password);
    
    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.success,
        userEmail: user.email,
      ),
    );
  }

  void clearError() {
    state = state.copyWith(
      status: AuthStatus.initial,
      errorMessage: null,
    );
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
