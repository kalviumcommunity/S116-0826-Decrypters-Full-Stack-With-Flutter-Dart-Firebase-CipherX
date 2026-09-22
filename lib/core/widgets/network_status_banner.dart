import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';

/// State representing the application's network connectivity.
enum NetworkStatus {
  online,
  offline,
  restored,
}

/// Provider monitoring device network availability.
final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, NetworkStatus>((ref) {
  return NetworkStatusNotifier();
});

class NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  Timer? _pollingTimer;
  bool _wasOffline = false;

  NetworkStatusNotifier() : super(NetworkStatus.online) {
    _startMonitoring();
  }

  void _startMonitoring() {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) return;
    _checkConnectivity();
    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (_wasOffline) {
          _wasOffline = false;
          state = NetworkStatus.restored;
          // Return to online after displaying the restored toast
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && state == NetworkStatus.restored) {
              state = NetworkStatus.online;
            }
          });
        } else if (state != NetworkStatus.restored) {
          state = NetworkStatus.online;
        }
      } else {
        _setOffline();
      }
    } on SocketException catch (_) {
      _setOffline();
    } on TimeoutException catch (_) {
      _setOffline();
    } catch (_) {
      // Keep existing state on generic probe failure
    }
  }

  void _setOffline() {
    _wasOffline = true;
    if (state != NetworkStatus.offline) {
      state = NetworkStatus.offline;
    }
  }

  /// Manually force a status check (e.g., after user retry tap)
  Future<void> checkNow() async {
    await _checkConnectivity();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

/// Banner showing real-time network connectivity status.
class NetworkStatusBanner extends ConsumerWidget {
  const NetworkStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);

    if (status == NetworkStatus.online) {
      return const SizedBox.shrink();
    }

    final isRestored = status == NetworkStatus.restored;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isRestored ? AppColors.success : AppColors.error,
      child: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRestored
                  ? Icons.wifi_rounded
                  : Icons.wifi_off_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isRestored
                  ? 'Connection restored.'
                  : "You're offline. Some operations may be unavailable.",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
