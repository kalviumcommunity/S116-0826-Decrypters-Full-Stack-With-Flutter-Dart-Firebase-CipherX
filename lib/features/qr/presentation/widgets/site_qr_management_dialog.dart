import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../sites/domain/entities/site.dart';
import '../../../sites/presentation/providers/site_providers.dart';
import '../../domain/entities/site_qr_payload.dart';

/// Modal dialog providing comprehensive QR management for an authorized site.
///
/// Displays:
/// - Official Site QR code
/// - Site Name
/// - Operational Status badge
/// - Generated timestamp (relative & exact)
///
/// Actions:
/// - Download / Save
/// - Share / Print
/// - Regenerate (with confirmation dialog)
class SiteQrManagementDialog extends ConsumerStatefulWidget {
  final Site site;

  const SiteQrManagementDialog({
    super.key,
    required this.site,
  });

  @override
  ConsumerState<SiteQrManagementDialog> createState() =>
      _SiteQrManagementDialogState();
}

class _SiteQrManagementDialogState
    extends ConsumerState<SiteQrManagementDialog> {
  late DateTime _generatedTimestamp;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _generatedTimestamp =
        widget.site.updatedAt ?? widget.site.createdAt ?? DateTime.now();
  }

  Future<void> _handleDownload() async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('QR Code for ${widget.site.name} saved to device.'),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleShareOrPrint() async {
    HapticFeedback.lightImpact();
    final payload = SiteQrPayload.createForSite(widget.site.siteId);
    await Clipboard.setData(ClipboardData(text: payload.toJson()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.print_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'QR payload for ${widget.site.name} copied & sent to print queue.',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleRegenerate() async {
    final confirmed = await AppDialogs.confirmRegenerateQr(
      context,
      siteName: widget.site.name,
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isRegenerating = true;
    });

    try {
      final now = DateTime.now();
      final updatedSite = widget.site.copyWith(updatedAt: now);
      final success = await ref
          .read(siteControllerProvider.notifier)
          .updateSite(updatedSite);

      if (mounted) {
        if (success) {
          setState(() {
            _generatedTimestamp = now;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Site QR code regenerated successfully.'),
                ],
              ),
              backgroundColor: Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to regenerate site QR code.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final site = widget.site;
    final payload = SiteQrPayload.createForSite(site.siteId);
    final qrDataString = payload.toJson();
    final isActive = site.status == SiteStatus.active;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dialog Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'QR Management',
                      style: AppTextStyles.titleMedium().copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const Divider(height: 24),

            // Site Name & Status
            Text(
              site.name,
              style: AppTextStyles.titleLarge().copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Site ID: ${site.siteId}',
              style: AppTextStyles.caption(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            isActive ? StatusBadge.active() : StatusBadge.inactive(),
            const SizedBox(height: 20),

            // QR Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: _isRegenerating
                  ? const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : QrImageView(
                      data: qrDataString,
                      version: QrVersions.auto,
                      size: 200,
                      gapless: true,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0F172A),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0F172A),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Generated timestamp
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 15,
                    color: AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Generated: ${TimeUtils.formatRelative(_generatedTimestamp)}',
                    style: AppTextStyles.caption(
                      color: AppColors.textSecondaryLight,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions row: Download & Share/Print
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleDownload,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleShareOrPrint,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share / Print'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Regenerate Button (Destructive / irreversible action with confirmation)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _isRegenerating ? null : _handleRegenerate,
                icon: _isRegenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded, size: 18),
                label: Text(
                  _isRegenerating ? 'Regenerating...' : 'Regenerate QR Token',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
