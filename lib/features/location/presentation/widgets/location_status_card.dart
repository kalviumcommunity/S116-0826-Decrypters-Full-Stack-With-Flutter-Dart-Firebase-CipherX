import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/location_data.dart';
import '../../domain/entities/location_permission_state.dart';
import '../../domain/failures/location_failure.dart';
import '../providers/location_controller.dart';
import '../providers/location_providers.dart';

class LocationStatusCard extends ConsumerWidget {
  final VoidCallback? onLocationAcquired;

  const LocationStatusCard({
    super.key,
    this.onLocationAcquired,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationControllerProvider);
    final permissionAsync = ref.watch(locationPermissionProvider);
    final serviceEnabledAsync = ref.watch(isLocationServiceEnabledProvider);

    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(128),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.my_location_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GPS Location Service',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                permissionAsync.when(
                  data: (permission) =>
                      _PermissionBadge(permission: permission),
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const Divider(height: 24),
            serviceEnabledAsync.when(
              data: (enabled) {
                if (!enabled) {
                  return const _ErrorBanner(
                    message:
                        'GPS location services are disabled on this device.',
                    icon: Icons.location_off_rounded,
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            locationAsync.when(
              data: (location) {
                if (location == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No location acquired yet. Tap below to acquire current GPS coordinates.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return _LocationDetails(location: location);
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Acquiring high-accuracy GPS coordinates...'),
                    ],
                  ),
                ),
              ),
              error: (error, _) {
                final message = error is LocationFailure
                    ? error.message
                    : 'Failed to acquire location: $error';
                return _ErrorBanner(
                  message: message,
                  icon: Icons.error_outline_rounded,
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: locationAsync.isLoading
                    ? null
                    : () async {
                        final loc = await ref
                            .read(locationControllerProvider.notifier)
                            .fetchLocation();
                        if (loc != null && onLocationAcquired != null) {
                          onLocationAcquired!();
                        }
                      },
                icon: const Icon(Icons.gps_fixed_rounded),
                label: Text(
                  locationAsync.value == null
                      ? 'Acquire Current Location'
                      : 'Refresh GPS Location',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionBadge extends StatelessWidget {
  final LocationPermissionState permission;

  const _PermissionBadge({required this.permission});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (permission) {
      case LocationPermissionState.granted:
        bg = Colors.green.withAlpha(38);
        fg = Colors.green.shade800;
        label = 'Granted';
        break;
      case LocationPermissionState.denied:
        bg = Colors.orange.withAlpha(38);
        fg = Colors.orange.shade900;
        label = 'Denied';
        break;
      case LocationPermissionState.permanentlyDenied:
        bg = Colors.red.withAlpha(38);
        fg = Colors.red.shade900;
        label = 'Blocked';
        break;
      case LocationPermissionState.unableToDetermine:
        bg = Colors.grey.withAlpha(38);
        fg = Colors.grey.shade800;
        label = 'Unknown';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LocationDetails extends StatelessWidget {
  final LocationData location;

  const _LocationDetails({required this.location});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(102),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _DetailRow(
            label: 'Latitude',
            value: location.latitude.toStringAsFixed(6),
          ),
          const SizedBox(height: 6),
          _DetailRow(
            label: 'Longitude',
            value: location.longitude.toStringAsFixed(6),
          ),
          const SizedBox(height: 6),
          _DetailRow(
            label: 'Accuracy',
            value: '±${location.accuracy.toStringAsFixed(1)} m',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final IconData icon;

  const _ErrorBanner({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onErrorContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
