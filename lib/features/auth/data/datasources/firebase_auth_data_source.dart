import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/auth_user.dart';
import '../../domain/failures/auth_failure.dart';

class FirebaseAuthDataSource {
  final fb.FirebaseAuth _firebaseAuth;

  FirebaseAuthDataSource({fb.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  AuthUser? get currentUser {
    final fb.User? user = _firebaseAuth.currentUser;
    return _mapFirebaseUser(user);
  }

  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final fb.UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      final AuthUser? user = _mapFirebaseUser(credential.user);
      if (user == null) {
        throw const UnknownAuthFailure('User missing after authentication.');
      }
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw UnknownAuthFailure(e.toString());
    }
  }

  Future<AuthUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final fb.UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      final AuthUser? user = _mapFirebaseUser(credential.user);
      if (user == null) {
        throw const UnknownAuthFailure('User missing after registration.');
      }

      // Send verification email on sign-up as per requirements
      try {
        await credential.user?.sendEmailVerification();
      } catch (_) {
        // Non-blocking error for email verification delivery
      }

      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw UnknownAuthFailure(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw UnknownAuthFailure(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw UnknownAuthFailure(e.toString());
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final fb.User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UserNotFoundFailure('No authenticated user found.');
      }
      await user.sendEmailVerification();
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw UnknownAuthFailure(e.toString());
    }
  }

  AuthUser? _mapFirebaseUser(fb.User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  static AuthFailure mapFirebaseAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return InvalidEmailFailure(e.message);
      case 'invalid-credential':
        return InvalidCredentialsFailure(e.message);
      case 'user-disabled':
        return UserDisabledFailure(e.message);
      case 'user-not-found':
        return UserNotFoundFailure(e.message);
      case 'wrong-password':
        return WrongPasswordFailure(e.message);
      case 'email-already-in-use':
        return EmailAlreadyInUseFailure(e.message);
      case 'weak-password':
        return WeakPasswordFailure(e.message);
      case 'operation-not-allowed':
        return OperationNotAllowedFailure(e.message);
      case 'too-many-requests':
        return TooManyRequestsFailure(e.message);
      case 'network-request-failed':
        return NetworkRequestFailedFailure(e.message);
      default:
        return UnknownAuthFailure(e.message, e.code);
    }
  }
}
