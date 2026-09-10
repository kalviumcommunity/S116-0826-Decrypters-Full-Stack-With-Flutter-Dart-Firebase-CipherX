import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/router/app_router.dart';
import '../../../guard/presentation/providers/guard_shifts_provider.dart';
import '../../../shifts/domain/entities/shift.dart';
import '../providers/attendance_providers.dart';

/// Screen enabling security guards to perform secure, gate-verified attendance check-in.
class GuardCheckInScreen extends ConsumerStatefulWidget {
  const GuardCheckInScreen({super.key});

  @override
  ConsumerState<GuardCheckInScreen> createState() => _GuardCheckInScreenState();
}

class _GuardCheckInScreenState extends ConsumerState<GuardCheckInScreen> {
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _hasPermissionError = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture, Shift shift) async {
    if (_isProcessing) return;

    final checkInState = ref.read(checkInControllerProvider);
    if (checkInState.isLoading || checkInState.isSuccess) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await ref.read(checkInControllerProvider.notifier).checkIn(
            shiftId: shift.shiftId,
            rawQrData: rawValue,
          );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _resetCheckIn() {
    ref.read(checkInControllerProvider.notifier).reset();
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guardShiftsAsync = ref.watch(guardShiftsProvider);
    final activeAttendanceAsync = ref.watch(activeAttendanceProvider);
    final checkInState = ref.watch(checkInControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Check-In'),
        centerTitle: true,
        actions: [
          if (!checkInState.isLoading &&
              !checkInState.isSuccess &&
              !_hasPermissionError)
            IconButton(
              icon: const Icon(Icons.flash_on),
              tooltip: 'Toggle Flashlight',
              onPressed: () => _scannerController.toggleTorch(),
            ),
        ],
      ),
      body: activeAttendanceAsync.when(
        data: (activeAttendance) {
          if (activeAttendance != null && !activeAttendance.isCheckedOut) {
            return _buildAlreadyCheckedInView(theme, activeAttendance.shiftId);
          }

          return guardShiftsAsync.when(
            data: (data) {
              final todayShift = data.todayShift;
              if (todayShift == null) {
                return _buildNoShiftView(theme);
              }

              if (checkInState.isLoading) {
                return _buildLoadingView(theme, checkInState.phase);
              }

              if (checkInState.isSuccess) {
                return _buildSuccessView(theme, checkInState);
              }

              if (checkInState.isFailure) {
                return _buildFailureView(theme, checkInState.errorMessage);
              }

              return _buildScannerView(theme, todayShift);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading shift details: $error'),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Error loading attendance status: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildAlreadyCheckedInView(ThemeData theme, String shiftId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, size: 72, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Already Checked In',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You currently have an active check-in session for shift $shiftId.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.shift),
              icon: const Icon(Icons.badge_outlined),
              label: const Text('View Active Shift'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoShiftView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Shift Scheduled Today',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You do not have an active shift assigned for today. Contact your supervisor to receive a shift assignment.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(guardShiftsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Shifts'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView(ThemeData theme, CheckInVerificationPhase phase) {
    String message = 'Verifying check-in requirements...';
    switch (phase) {
      case CheckInVerificationPhase.verifyingIdentity:
        message = 'Verifying guard authentication & credentials...';
        break;
      case CheckInVerificationPhase.verifyingShift:
        message = 'Verifying shift assignment & site association...';
        break;
      case CheckInVerificationPhase.verifyingLocation:
        message = 'Acquiring high-accuracy GPS coordinates...';
        break;
      case CheckInVerificationPhase.verifyingQr:
        message = 'Validating site QR code...';
        break;
      case CheckInVerificationPhase.evaluatingGeofence:
        message = 'Evaluating site geofence perimeter...';
        break;
      case CheckInVerificationPhase.persisting:
        message = 'Creating authoritative attendance record...';
        break;
      default:
        message = 'Verifying security check-in pipeline...';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please do not close the application or leave the area.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(ThemeData theme, CheckInState state) {
    final result = state.result;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 72, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  '✓ Check-In Verified',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your presence has been cryptographically and geographically verified.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                if (result != null) ...[
                  ListTile(
                    leading: const Icon(Icons.business),
                    title: const Text('Site'),
                    subtitle: Text(
                      result.site.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Distance to Center'),
                    subtitle: Text(
                      '${result.distanceMeters.toStringAsFixed(1)} m (Radius: ${result.site.geofenceRadius.toStringAsFixed(0)} m)',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.gps_fixed),
                    title: const Text('GPS Accuracy'),
                    subtitle: Text(
                      '±${result.accuracyMeters.toStringAsFixed(1)} m',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Verified At'),
                    subtitle: Text(
                      result.verifiedAt.toLocal().toString().split('.')[0],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.shift),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Go to My Shifts'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFailureView(ThemeData theme, String? errorMessage) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 72, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Check-In Rejected',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  errorMessage ??
                      'Check-in verification failed. All security gates must pass.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _resetCheckIn,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Check-In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerView(ThemeData theme, Shift shift) {
    if (_hasPermissionError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined,
                  size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Camera Permission Required',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Camera access is required to scan the on-site QR code. Please grant permission in settings.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasPermissionError = false;
                  });
                  _scannerController.start();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Camera'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Row(
            children: [
              const Icon(Icons.qr_code_scanner, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shift: ${shift.startTime.toFormattedString()} - ${shift.endTime.toFormattedString()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Point camera at the official Cipher-X site QR code.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) => _handleBarcode(capture, shift),
                errorBuilder: (context, error, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_hasPermissionError) {
                      setState(() {
                        _hasPermissionError = true;
                      });
                    }
                  });
                  return const SizedBox.shrink();
                },
              ),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
