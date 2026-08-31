import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../identity/presentation/providers/identity_providers.dart';
import '../../../sites/presentation/providers/site_providers.dart';
import '../../domain/entities/qr_validation_result.dart';
import '../../domain/services/qr_validator.dart';

class SiteQrScannerScreen extends ConsumerStatefulWidget {
  final QrValidator validator;
  final Function(String rawData)? onScanOverride;

  const SiteQrScannerScreen({
    super.key,
    this.validator = const QrValidator(),
    this.onScanOverride,
  });

  @override
  ConsumerState<SiteQrScannerScreen> createState() =>
      _SiteQrScannerScreenState();
}

class _SiteQrScannerScreenState extends ConsumerState<SiteQrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessingScan = false;
  bool _isLoading = false;
  QrValidationResult? _validationResult;
  bool _hasPermissionError = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processRawQrData(String rawData) async {
    if (_isProcessingScan || _isLoading) return;

    setState(() {
      _isProcessingScan = true;
      _isLoading = true;
      _validationResult = null;
    });

    final profile = ref.read(currentUserProfileProvider).asData?.value;
    final organizationId = profile?.organizationId ?? '';
    final repository = ref.read(siteRepositoryProvider);

    final result = await widget.validator.validateRawQr(
      rawQrData: rawData,
      organizationId: organizationId,
      siteRepository: repository,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _validationResult = result;
      // If validation failed, allow rescanning after showing error UI
      if (!result.isValid) {
        _isProcessingScan = false;
      }
    });
  }

  void _resetScanner() {
    setState(() {
      _isProcessingScan = false;
      _isLoading = false;
      _validationResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Site QR Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner Camera View
          if (!_hasPermissionError)
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                if (_isProcessingScan) return;
                final barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final rawValue = barcode.rawValue;
                  if (rawValue != null && rawValue.isNotEmpty) {
                    _processRawQrData(rawValue);
                    break;
                  }
                }
              },
              errorBuilder: (context, error, child) {
                return _buildPermissionErrorView(theme, error.toString());
              },
            ),

          // Permission Error Fallback View
          if (_hasPermissionError)
            _buildPermissionErrorView(
              theme,
              'Camera permission denied or camera unavailable.',
            ),

          // Scanner Overlay Window
          if (!_hasPermissionError && _validationResult == null && !_isLoading)
            _buildScanOverlay(theme),

          // Loading View Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Verifying QR...',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Result Overlay (Valid / Invalid / Site Not Found)
          if (_validationResult != null && !_isLoading)
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SingleChildScrollView(
                  child: _buildResultCard(theme, _validationResult!),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Point camera at Cipher-X Site QR Code',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionErrorView(ThemeData theme, String errorDetails) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Camera Permission Denied',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Camera permission is required to scan site QR codes. Please grant camera permission and retry.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
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
              label: const Text('Retry / Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme, QrValidationResult result) {
    if (result.isValid) {
      final site = result.site!;
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 12),
              Text(
                '✓ QR Verified',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Site Name'),
                subtitle: Text(
                  site.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('Site ID'),
                subtitle: Text(site.siteId),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Address'),
                subtitle: Text(site.address),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _resetScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Another QR'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (result.isSiteNotFound) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wrong_location_outlined,
                  color: Colors.orange, size: 64),
              const SizedBox(height: 12),
              Text(
                'Site Not Found',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (result.siteId != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Site ID: ${result.siteId}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _resetScanner,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan Again'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Invalid QR Format / Type / Missing ID / Unsupported Version
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 64),
            const SizedBox(height: 12),
            Text(
              '✕ Invalid QR',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This QR code is not a valid Cipher-X site QR.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetScanner,
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
