import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../geofence/domain/services/geofence_engine.dart';
import '../../../guard/presentation/providers/guard_shifts_provider.dart';
import '../../../identity/domain/entities/user_profile.dart';
import '../../../identity/presentation/providers/identity_providers.dart';
import '../../../location/domain/entities/location_data.dart';
import '../../../location/domain/failures/location_failure.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../../qr/domain/services/qr_validator.dart';
import '../../../shifts/domain/entities/shift.dart';
import '../../../sites/domain/entities/site.dart';
import '../../../sites/presentation/providers/site_providers.dart';
import '../providers/attendance_providers.dart';

/// Screen enabling security guards to verify readiness across 6 security gates
/// and execute secure, authoritative check-in.
class GuardCheckInScreen extends ConsumerStatefulWidget {
  const GuardCheckInScreen({super.key});

  @override
  ConsumerState<GuardCheckInScreen> createState() => _GuardCheckInScreenState();
}

class _GuardCheckInScreenState extends ConsumerState<GuardCheckInScreen> {
  late final MobileScannerController _scannerController;
  bool _isProcessingScan = false;
  bool _isSubmitting = false;
  bool _hasCameraPermissionError = false;

  // Gate verification states
  LocationData? _currentLocation;
  String? _gpsError;
  bool _isAcquiringGps = false;

  Site? _site;
  bool _isLoadingSite = false;
  String? _siteError;

  String? _scannedQrData;
  String? _qrError;
  bool _isQrVerified = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _acquireGps();
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _acquireGps() async {
    if (!mounted || _isAcquiringGps) return;
    setState(() {
      _isAcquiringGps = true;
      _gpsError = null;
    });

    try {
      final loc = await ref.read(locationServiceProvider).getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentLocation = loc;
          _gpsError = null;
          _isAcquiringGps = false;
        });
      }
    } on LocationPermissionDeniedFailure {
      if (mounted) {
        setState(() {
          _currentLocation = null;
          _gpsError = 'Location permission is required.';
          _isAcquiringGps = false;
        });
      }
    } on LocationPermissionPermanentlyDeniedFailure {
      if (mounted) {
        setState(() {
          _currentLocation = null;
          _gpsError = 'Location permission is permanently denied in settings.';
          _isAcquiringGps = false;
        });
      }
    } on LocationServiceDisabledFailure {
      if (mounted) {
        setState(() {
          _currentLocation = null;
          _gpsError = 'Location services are disabled.';
          _isAcquiringGps = false;
        });
      }
    } on LocationTimeoutFailure {
      if (mounted) {
        setState(() {
          _currentLocation = null;
          _gpsError = 'Location acquisition timed out.';
          _isAcquiringGps = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentLocation = null;
          _gpsError = 'Location unavailable.';
          _isAcquiringGps = false;
        });
      }
    }
  }

  Future<void> _loadSite(String organizationId, String siteId) async {
    if (_site != null && _site!.siteId == siteId) return;
    if (_isLoadingSite) return;

    setState(() {
      _isLoadingSite = true;
      _siteError = null;
    });

    try {
      final siteRepo = ref.read(siteRepositoryProvider);
      final site = await siteRepo.getSite(
        organizationId: organizationId,
        siteId: siteId,
      );
      if (mounted) {
        setState(() {
          _site = site;
          _isLoadingSite = false;
          if (site == null) {
            _siteError = 'Assigned site not found.';
          } else if (site.status != SiteStatus.active) {
            _siteError = 'Assigned site is inactive.';
          } else {
            _siteError = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSite = false;
          _siteError = 'Error loading site details.';
        });
      }
    }
  }

  Future<void> _handleBarcode(BarcodeCapture capture, Shift shift) async {
    if (_isProcessingScan || _isQrVerified) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    setState(() {
      _isProcessingScan = true;
    });

    try {
      final profile = ref.read(currentUserProfileProvider).asData?.value;
      if (profile == null) {
        setState(() {
          _qrError = 'Guard profile not loaded.';
          _isQrVerified = false;
        });
        return;
      }

      const validator = QrValidator();
      final qrResult = await validator.validateRawQr(
        rawQrData: rawValue,
        organizationId: profile.organizationId,
        siteRepository: ref.read(siteRepositoryProvider),
      );

      if (!qrResult.isValid) {
        setState(() {
          _scannedQrData = null;
          _isQrVerified = false;
          _qrError = 'QR code is invalid.';
        });
      } else if (qrResult.siteId != shift.siteId) {
        setState(() {
          _scannedQrData = null;
          _isQrVerified = false;
          _qrError = 'QR code is for a different site (${qrResult.siteId}).';
        });
      } else {
        setState(() {
          _scannedQrData = rawValue;
          _isQrVerified = true;
          _qrError = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingScan = false;
        });
      }
    }
  }

  Future<void> _executeCheckIn(Shift shift) async {
    if (_isSubmitting || _scannedQrData == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(checkInControllerProvider.notifier).checkIn(
            shiftId: shift.shiftId,
            rawQrData: _scannedQrData!,
          );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _resetCheckIn() {
    ref.read(checkInControllerProvider.notifier).reset();
    setState(() {
      _isProcessingScan = false;
      _isSubmitting = false;
      _scannedQrData = null;
      _isQrVerified = false;
      _qrError = null;
    });
    _acquireGps();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guardShiftsAsync = ref.watch(guardShiftsProvider);
    final activeAttendanceAsync = ref.watch(activeAttendanceProvider);
    final checkInState = ref.watch(checkInControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Secure Check-In'),
        centerTitle: true,
        actions: [
          if (!checkInState.isLoading &&
              !checkInState.isSuccess &&
              !_hasCameraPermissionError)
            IconButton(
              icon: const Icon(Icons.flash_on_rounded),
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

              final profile =
                  ref.watch(currentUserProfileProvider).asData?.value;
              if (profile != null && _site == null && !_isLoadingSite) {
                _loadSite(profile.organizationId, todayShift.siteId);
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

              return _buildReadinessView(theme, todayShift, profile);
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

  Widget _buildReadinessView(
    ThemeData theme,
    Shift shift,
    UserProfile? profile,
  ) {
    // 1. Gate: Authenticated
    final bool authOk = profile != null &&
        profile.uid.isNotEmpty &&
        profile.role == UserRole.guard;
    final String? authReason =
        authOk ? null : 'User is not authenticated as Guard.';

    // 2. Gate: Valid Shift
    final bool shiftOk = shift.status != ShiftStatus.cancelled;
    final String? shiftReason =
        shiftOk ? null : 'Shift is cancelled or inactive.';

    // 3. Gate: Correct Site
    final bool siteOk = _site != null && _site!.status == SiteStatus.active;
    final String? siteReason = _siteError;

    // 4. Gate: GPS Available
    final bool gpsOk = _currentLocation != null && _gpsError == null;
    final String? gpsReason = _gpsError;

    // 5. Gate: Inside Geofence
    bool geofenceOk = false;
    String? geofenceReason;
    double? calculatedDistance;

    if (gpsOk && siteOk) {
      final geofenceResult = const GeofenceEngine().evaluateWithLocationAndSite(
        location: _currentLocation!,
        site: _site!,
      );
      calculatedDistance = geofenceResult.distanceMeters;

      if (geofenceResult.isWithinGeofence) {
        geofenceOk = true;
      } else if (geofenceResult.isPoorAccuracy) {
        geofenceReason =
            'Poor GPS accuracy (±${_currentLocation!.accuracy.toStringAsFixed(1)}m > 50m).';
      } else if (geofenceResult.isOutside) {
        geofenceReason = 'Outside geofence.';
      } else {
        geofenceReason = 'Geofence evaluation failed.';
      }
    } else if (!gpsOk) {
      geofenceReason = 'Waiting for GPS signal.';
    } else {
      geofenceReason = 'Waiting for site coordinates.';
    }

    // 6. Gate: QR Verified
    final bool qrOk = _isQrVerified && _scannedQrData != null;
    final String? qrReason =
        _qrError ?? (_isQrVerified ? null : 'QR scan required.');

    final bool allGatesReady =
        authOk && shiftOk && siteOk && gpsOk && geofenceOk && qrOk;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Camera Scanner Box (Compact card)
          _buildScannerBox(theme, shift),
          const SizedBox(height: 16),

          // Shift summary banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _site?.name ?? 'Site: ${shift.siteId}',
                        style: AppTextStyles.titleMedium().copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Shift: ${shift.startTime.toFormattedString()} - ${shift.endTime.toFormattedString()}',
                        style: AppTextStyles.caption(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: _isAcquiringGps
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh GPS & Checklist',
                  onPressed: _acquireGps,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Checklist Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.borderLight),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'VERIFICATION CHECKLIST',
                        style: AppTextStyles.caption(
                          color: AppColors.textSecondaryLight,
                        ).copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '${[
                          authOk,
                          shiftOk,
                          siteOk,
                          gpsOk,
                          geofenceOk,
                          qrOk
                        ].where((e) => e).length}/6 Passed',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildChecklistItem(
                    title: 'Authenticated',
                    isPassed: authOk,
                    detail: authOk
                        ? (profile.displayName.isNotEmpty
                            ? profile.displayName
                            : 'Guard Session Active')
                        : null,
                    reason: authReason,
                  ),
                  _buildChecklistItem(
                    title: 'Valid Shift',
                    isPassed: shiftOk,
                    detail: shiftOk
                        ? '${shift.startTime.toFormattedString()} - ${shift.endTime.toFormattedString()}'
                        : null,
                    reason: shiftReason,
                  ),
                  _buildChecklistItem(
                    title: 'Correct Site',
                    isPassed: siteOk,
                    detail: siteOk ? _site!.name : null,
                    reason: siteReason,
                  ),
                  _buildChecklistItem(
                    title: 'GPS Available',
                    isPassed: gpsOk,
                    detail: gpsOk
                        ? '±${_currentLocation!.accuracy.toStringAsFixed(1)}m accuracy'
                        : null,
                    reason: gpsReason,
                    trailingAction: !gpsOk
                        ? TextButton(
                            onPressed: _acquireGps,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Retry GPS'),
                          )
                        : null,
                  ),
                  _buildChecklistItem(
                    title: 'Inside Geofence',
                    isPassed: geofenceOk,
                    detail: geofenceOk
                        ? '${calculatedDistance?.toStringAsFixed(1)}m from site center'
                        : null,
                    reason: geofenceReason,
                  ),
                  _buildChecklistItem(
                    title: 'QR Verified',
                    isPassed: qrOk,
                    detail: qrOk ? 'Official Site QR Confirmed' : null,
                    reason: qrReason,
                    trailingAction: qrOk
                        ? TextButton(
                            onPressed: () {
                              setState(() {
                                _scannedQrData = null;
                                _isQrVerified = false;
                                _qrError = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Rescan'),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Readiness Badge & Action
          if (allGatesReady) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF10B981),
                  width: 1.5,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF059669),
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'READY FOR CHECK-IN',
                    style: TextStyle(
                      color: Color(0xFF047857),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                key: const Key('check_in_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSubmitting ? null : () => _executeCheckIn(shift),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.how_to_reg_rounded, size: 22),
                label: Text(
                  _isSubmitting ? 'CHECKING IN...' : 'CHECK IN',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 54,
              child: FilledButton(
                key: const Key('check_in_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.borderLight,
                  foregroundColor: AppColors.textSecondaryLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: null,
                child: const Text(
                  'CHECK IN (PENDING VERIFICATION)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScannerBox(ThemeData theme, Shift shift) {
    if (_hasCameraPermissionError) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_outlined,
                    size: 40, color: AppColors.error),
                const SizedBox(height: 8),
                const Text(
                  'Camera Permission Required',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasCameraPermissionError = false;
                    });
                    _scannerController.start();
                  },
                  child: const Text('Grant Camera Access'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) => _handleBarcode(capture, shift),
              errorBuilder: (context, error, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_hasCameraPermissionError) {
                    setState(() {
                      _hasCameraPermissionError = true;
                    });
                  }
                });
                return const SizedBox.shrink();
              },
            ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isQrVerified
                      ? const Color(0xFF10B981)
                      : Colors.white.withValues(alpha: 0.7),
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            Positioned(
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isQrVerified
                      ? '✓ QR Code Scanned'
                      : 'Align site QR inside frame',
                  style: TextStyle(
                    color: _isQrVerified
                        ? const Color(0xFF34D399)
                        : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required bool isPassed,
    String? detail,
    String? reason,
    Widget? trailingAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPassed
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : const Color(0xFFEF4444).withValues(alpha: 0.12),
            ),
            child: Icon(
              isPassed ? Icons.check_rounded : Icons.close_rounded,
              size: 17,
              color:
                  isPassed ? const Color(0xFF059669) : const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isPassed
                            ? AppColors.textPrimaryLight
                            : const Color(0xFFDC2626),
                      ),
                    ),
                    if (detail != null && isPassed) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          detail,
                          style: AppTextStyles.caption(
                            color: AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (!isPassed && reason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailingAction != null) trailingAction,
        ],
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
}
