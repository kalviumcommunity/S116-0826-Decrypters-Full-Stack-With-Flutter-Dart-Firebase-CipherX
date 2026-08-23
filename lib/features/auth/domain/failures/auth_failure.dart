import 'package:flutter/foundation.dart';

@immutable
abstract class AuthFailure implements Exception {
  final String message;
  final String? code;

  const AuthFailure(this.message, [this.code]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthFailure &&
        other.runtimeType == runtimeType &&
        other.message == message &&
        other.code == code;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, code);

  @override
  String toString() => '$runtimeType: $message (${code ?? "no-code"})';
}

class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure([String? message])
      : super(message ?? 'Enter a valid email address.', 'invalid-email');
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([String? message])
      : super(
            message ?? 'Email or password is incorrect.', 'invalid-credential');
}

class UserDisabledFailure extends AuthFailure {
  const UserDisabledFailure([String? message])
      : super(message ?? 'This account has been disabled.', 'user-disabled');
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure([String? message])
      : super(message ?? 'No account found with this email.', 'user-not-found');
}

class WrongPasswordFailure extends AuthFailure {
  const WrongPasswordFailure([String? message])
      : super(message ?? 'Email or password is incorrect.', 'wrong-password');
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure([String? message])
      : super(message ?? 'An account already exists with this email.',
            'email-already-in-use');
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([String? message])
      : super(
            message ?? 'Password is too weak. Please use a stronger password.',
            'weak-password');
}

class OperationNotAllowedFailure extends AuthFailure {
  const OperationNotAllowedFailure([String? message])
      : super(message ?? 'Operation is not allowed.', 'operation-not-allowed');
}

class TooManyRequestsFailure extends AuthFailure {
  const TooManyRequestsFailure([String? message])
      : super(message ?? 'Too many attempts. Please try again later.',
            'too-many-requests');
}

class NetworkRequestFailedFailure extends AuthFailure {
  const NetworkRequestFailedFailure([String? message])
      : super(
            message ??
                'Unable to connect. Check your internet connection and try again.',
            'network-request-failed');
}

class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure([String? message, String? code])
      : super(message ?? 'Something went wrong. Please try again.',
            code ?? 'unknown');
}
