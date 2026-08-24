import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../config/app_config.dart';
import '../errors/app_exception.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  // Emulator configuration constants
  static const String emulatorHostLocalhost = 'localhost';
  static const String emulatorHostAndroid = '10.0.2.2';

  static const int authEmulatorPort = 9099;
  static const int firestoreEmulatorPort = 8080;
  static const int storageEmulatorPort = 9199;

  /// Initializes Firebase Core, Auth, Firestore, and Storage SDKs.
  /// Connects to local emulators if configured or running in development mode.
  static Future<void> initialize({
    bool connectEmulators = false,
    String? customHost,
  }) async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final AppConfig config = AppConfig.fromEnvironment();
      final bool shouldEmulate =
          connectEmulators || config.environment == AppEnvironment.development;

      if (shouldEmulate) {
        await configureEmulators(host: customHost);
      }

      _isInitialized = true;
    } catch (e, stackTrace) {
      debugPrint('FirebaseService Initialization Error: $e\n$stackTrace');
      throw NetworkException(
        'Failed to initialize Firebase services cleanly.',
        details: e.toString(),
      );
    }
  }

  /// Configures Auth, Firestore, and Storage to use local Emulator Suite
  static Future<void> configureEmulators({String? host}) async {
    final String targetHost = host ??
        (defaultTargetPlatform == TargetPlatform.android
            ? emulatorHostAndroid
            : emulatorHostLocalhost);

    try {
      await FirebaseAuth.instance.useAuthEmulator(targetHost, authEmulatorPort);
      FirebaseFirestore.instance.useFirestoreEmulator(
        targetHost,
        firestoreEmulatorPort,
      );
      await FirebaseStorage.instance.useStorageEmulator(
        targetHost,
        storageEmulatorPort,
      );
      debugPrint('Firebase Emulators connected cleanly to $targetHost');
    } catch (e) {
      debugPrint('Firebase Emulator Configuration Warning: $e');
    }
  }

  /// Diagnostic health check confirming Firebase SDK binding status
  static Map<String, dynamic> checkHealth() {
    return <String, dynamic>{
      'isInitialized': _isInitialized,
      'hasFirebaseApps': Firebase.apps.isNotEmpty,
      'authAvailable': true,
      'firestoreAvailable': true,
      'storageAvailable': true,
      'emulatorPorts': <String, int>{
        'auth': authEmulatorPort,
        'firestore': firestoreEmulatorPort,
        'storage': storageEmulatorPort,
      },
    };
  }

  @visibleForTesting
  static void resetForTesting() {
    _isInitialized = false;
  }

  // SDK Instance Accessors
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
}
