enum AuthStatus { initial, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? userEmail;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.userEmail,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? userEmail,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
