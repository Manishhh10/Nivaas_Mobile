import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:nivaas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nivaas/features/auth/domain/repositories/auth_repository.dart';
import 'package:nivaas/features/auth/domain/usecases/login_usecase.dart';
import 'package:nivaas/features/auth/domain/usecases/signup_usecase.dart';
import 'package:nivaas/features/auth/presentation/view_model/auth_state.dart';

// Hive Service Provider
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

// Data Source Provider
final authDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return AuthLocalDataSource(hiveService: hiveService);
});

// Repository Provider
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final dataSource = ref.watch(authDataSourceProvider);
  return AuthRepository(dataSource: dataSource);
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

  Future<void> signup(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    final result = await _signupUseCase(email, password);
    
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
