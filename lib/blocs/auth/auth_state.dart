abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userId;
  final String? displayName;
  final String? email;
  final String? photoURL;
  
  AuthAuthenticated({
    required this.userId,
    this.displayName,
    this.email,
    this.photoURL,
  });
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  AuthError(this.message);
}
