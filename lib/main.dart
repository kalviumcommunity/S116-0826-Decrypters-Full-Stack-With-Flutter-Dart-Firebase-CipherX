import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseService.initialize();
  } catch (e) {
    debugPrint('Main Bootstrap Warning: Firebase initialization deferred: $e');
  }

  runApp(const ProviderScope(child: CipherXApp()));
}
