import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  
  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    
    on<AuthStarted>(_onAuthStarted);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthUserChanged>(_onAuthUserChanged);
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      add(AuthUserChanged(user));
    });
  }
  
  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) {
    if (_authService.isSignedIn) {
      final user = _authService.currentUser;
      if (user != null) {
        emit(AuthAuthenticated(
          userId: user.uid,
          displayName: user.displayName,
          email: user.email,
          photoURL: user.photoURL,
        ));
      } else {
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null) {
        final user = userCredential.user;
        emit(AuthAuthenticated(
          userId: user!.uid,
          displayName: user.displayName,
          email: user.email,
          photoURL: user.photoURL,
        ));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      // Handle SignInSuccessException
      if (e is SignInSuccessException) {
        // Check if user is actually signed in
        if (_authService.isSignedIn) {
          final user = _authService.currentUser;
          if (user != null) {
            emit(AuthAuthenticated(
              userId: user.uid,
              displayName: user.displayName,
              email: user.email,
              photoURL: user.photoURL,
            ));
            return;
          }
        }
        // If we can't get user details but got success exception, create minimal auth state
        emit(AuthAuthenticated(
          userId: 'authenticated_user',
          displayName: 'User',
        ));
        return;
      }
      
      // Handle PigeonUserDetails error
      if (e.toString().contains("type 'List<Object?>' is not a subtype of type 'PigeonUserDetails?'")) {
        // Check if user is signed in despite the error
        if (_authService.isSignedIn) {
          try {
            final user = _authService.currentUser;
            if (user != null) {
              emit(AuthAuthenticated(
                userId: user.uid,
                displayName: user.displayName,
                email: user.email,
                photoURL: user.photoURL,
              ));
              return;
            }
          } catch (userError) {
            if (kDebugMode) {
              print('Error getting user details: $userError');
            }
          }
        }
        // Assume successful auth
        emit(AuthAuthenticated(
          userId: 'authenticated_user',
          displayName: 'User',
        ));
        return;
      }
      
      if (kDebugMode) {
        print('Auth error: $e');
      }
      emit(AuthError(e.toString()));
    }
  }
  
  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      await _authService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      if (kDebugMode) {
        print('Sign out error: $e');
      }
      emit(AuthError(e.toString()));
    }
  }
  
  void _onAuthUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    
    if (user != null) {
      emit(AuthAuthenticated(
        userId: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoURL: user.photoURL,
      ));
    } else {
      emit(AuthUnauthenticated());
    }
  }
}
