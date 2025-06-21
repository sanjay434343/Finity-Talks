abstract class AuthEvent {}

class AuthStarted extends AuthEvent {}

class AuthSignInRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class AuthUserChanged extends AuthEvent {
  final dynamic user;
  
  AuthUserChanged(this.user);
}
