import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/attendance/domain/failures/attendance_failure.dart';
import '../../features/incidents/domain/failures/incident_failure.dart';
import '../../features/location/domain/failures/location_failure.dart';
import '../../features/shifts/domain/failures/shift_failure.dart';
import '../../features/sites/domain/failures/site_failure.dart';
import 'app_exception.dart';

class FailureMapper {
  /// Converts any exception or error object into a clean, human-readable user message.
  static String mapToMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred.';

    // String error messages
    if (error is String) {
      return _mapStringError(error);
    }

    // Domain Failures
    if (error is AttendanceFailure) {
      return error.message;
    }
    if (error is LocationFailure) {
      return error.message;
    }
    if (error is IncidentFailure) {
      return error.message;
    }
    if (error is ShiftFailure) {
      return error.message;
    }
    if (error is SiteFailure) {
      return error.message;
    }

    // Custom AppException types
    if (error is NetworkException) {
      return 'Network connection unavailable. Please check your internet connection and try again.';
    }
    if (error is ValidationException) {
      return error.message.isNotEmpty
          ? error.message
          : 'Invalid data submitted.';
    }
    if (error is SecurityException) {
      return error.message.isNotEmpty
          ? error.message
          : 'Access denied due to security policy.';
    }
    if (error is AppException) {
      return error.message;
    }

    // Socket / IO Network Exceptions
    if (error is SocketException) {
      return 'Network connection unavailable. Please check your internet connection and try again.';
    }

    // Firebase Exceptions
    if (error is FirebaseException) {
      return _mapFirebaseException(error);
    }

    // Generic Exception toString mapping
    final str = error.toString();
    return _mapStringError(str);
  }

  static String _mapFirebaseException(FirebaseException exception) {
    switch (exception.code) {
      case 'network-request-failed':
      case 'unavailable':
        return 'Network connection lost. Please check your internet connection and retry.';
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'not-found':
        return 'The requested record or resource was not found.';
      case 'already-exists':
        return 'A record with this information already exists.';
      case 'resource-exhausted':
        return 'Request limit exceeded. Please wait a moment and try again.';
      case 'unauthenticated':
        return 'Your session has expired. Please log in again.';
      case 'deadline-exceeded':
        return 'Operation timed out. Please retry.';
      default:
        if (exception.message != null && exception.message!.isNotEmpty) {
          return exception.message!;
        }
        return 'Firebase error (${exception.code}). Please try again.';
    }
  }

  static String _mapStringError(String error) {
    final lower = error.toLowerCase();

    // Permission scenarios
    if (lower.contains('camera permission')) {
      return 'Camera permission is required to scan site QR codes. Please enable camera access.';
    }
    if (lower.contains('location permission')) {
      return 'Location permission is required for site check-in. Please enable location access.';
    }
    if (lower.contains('permission denied') ||
        lower.contains('permission_denied')) {
      return 'Permission denied. Please grant the required permissions in settings.';
    }

    // Location / Geofence scenarios
    if (lower.contains('outside permitted') ||
        lower.contains('outside geofence')) {
      return 'You are outside the permitted site area. Please move closer to the site location.';
    }
    if (lower.contains('location service disabled') ||
        lower.contains('gps disabled')) {
      return 'Location services (GPS) are disabled on your device. Please turn on location.';
    }

    // QR scenarios
    if (lower.contains('invalid qr') || lower.contains('malformed qr')) {
      return 'Invalid QR code. Please scan an authorized site QR code.';
    }
    if (lower.contains('mismatched site qr') || lower.contains('wrong site')) {
      return 'Scanned QR code belongs to a different site. Please scan the correct site QR.';
    }

    // Expired Shift scenarios
    if (lower.contains('expired shift') || lower.contains('shift expired')) {
      return 'This shift has expired or is no longer active for check-in.';
    }
    if (lower.contains('shift ended') || lower.contains('already completed')) {
      return 'This shift has already been completed.';
    }

    // Network scenarios
    if (lower.contains('network') ||
        lower.contains('socketexception') ||
        lower.contains('offline')) {
      return 'Network connection error. Please check your connection and retry.';
    }

    // Fallback cleaning raw Exception prefix
    if (error.startsWith('Exception: ')) {
      return error.substring(11);
    }
    return error;
  }
}
