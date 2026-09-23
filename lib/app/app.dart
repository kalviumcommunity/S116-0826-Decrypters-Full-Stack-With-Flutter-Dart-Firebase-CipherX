import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/services/fcm_service.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/identity/presentation/providers/identity_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class CipherXApp extends ConsumerStatefulWidget {
  const CipherXApp({super.key});

  @override
  ConsumerState<CipherXApp> createState() => _CipherXAppState();
}

class _CipherXAppState extends ConsumerState<CipherXApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotificationService();
    });
  }

  void _initializeNotificationService() {
    try {
      final fcmService = ref.read(fcmServiceProvider);
      fcmService.initialize();

      // Configure notification tap routing callback
      fcmService.setTapCallback((data) async {
        final route = data['route'] as String?;
        final alertId = data['alertId'] as String?;
        final notificationOrgId = data['organizationId'] as String?;

        final authUser = ref.read(authStateProvider).asData?.value;
        final profile = ref.read(currentUserProfileProvider).asData?.value;

        if (authUser == null || profile == null) return;

        // Security Check: Multi-Tenant Organization Isolation Boundary
        if (notificationOrgId != null &&
            notificationOrgId.isNotEmpty &&
            profile.organizationId != notificationOrgId) {
          debugPrint(
              'Security Alert: Blocked notification tap navigation across organization boundary.');
          return;
        }

        // Mark Firestore alert record as acknowledged / read on user tap
        if (alertId != null &&
            alertId.isNotEmpty &&
            profile.organizationId.isNotEmpty) {
          try {
            await FirebaseFirestore.instance
                .collection('organizations')
                .doc(profile.organizationId)
                .collection('alerts')
                .doc(alertId)
                .update({
              'status': 'acknowledged',
              'readAt': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            debugPrint('Error marking alert as acknowledged: $e');
          }
        }

        // Execute GoRouter navigation
        if (route != null && route.isNotEmpty) {
          ref.read(appRouterProvider).go(route);
        }
      });
    } catch (e) {
      debugPrint('FCM App Initialization Warning: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for authentication & profile changes for FCM token lifecycle management
    ref.listen(currentUserProfileProvider, (previous, next) {
      final profile = next.asData?.value;
      if (profile != null && profile.organizationId.isNotEmpty) {
        try {
          ref.read(fcmServiceProvider).registerDeviceToken(
                userId: profile.uid,
                organizationId: profile.organizationId,
                role: profile.role.name,
              );
        } catch (_) {}
      }
    });

    ref.listen(authStateProvider, (previous, next) {
      final authUser = next.asData?.value;
      if (authUser == null) {
        try {
          ref.read(fcmServiceProvider).unregisterDeviceToken();
        } catch (_) {}
      }
    });

    final routerConfig = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: routerConfig,
    );
  }
}
