import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Reusable confirmation dialogs matching the Cipher-X design system.
class AppDialogs {
  AppDialogs._();

  /// Shows a modal confirmation dialog for destructive or high-impact actions.
  /// Returns `true` if confirmed, `false` if cancelled.
  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? AppColors.errorBadgeBg
                        : AppColors.accentRose,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isDestructive ? AppColors.error : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppColors.borderLight),
                foregroundColor: AppColors.textPrimaryLight,
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(cancelLabel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDestructive ? AppColors.error : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Specialized confirmation for logging out of the application.
  static Future<bool> confirmLogout(BuildContext context) {
    return showConfirmation(
      context: context,
      title: 'Log Out',
      message: 'Are you sure you want to end your active session in Cipher-X?',
      confirmLabel: 'Log Out',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );
  }

  /// Specialized confirmation for deactivating an operational entity.
  static Future<bool> confirmDeactivation(
    BuildContext context, {
    required String entityName,
    String entityType = 'entity',
    String? title,
    String? message,
  }) {
    return showConfirmation(
      context: context,
      title: title ?? 'Deactivate $entityName',
      message: message ??
          'Are you sure you want to deactivate this $entityType ($entityName)? They will no longer be treated as active until reactivated.',
      confirmLabel: 'Deactivate',
      isDestructive: true,
      icon: Icons.block_rounded,
    );
  }

  /// Specialized confirmation for resolving an operational incident.
  static Future<bool> confirmResolveIncident(
    BuildContext context, {
    required String incidentTitle,
  }) {
    return showConfirmation(
      context: context,
      title: 'Resolve Incident',
      message:
          'Are you sure you want to mark "$incidentTitle" as Resolved? This indicates security triage is complete and creates an immutable audit entry.',
      confirmLabel: 'Mark Resolved',
      isDestructive: false,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  /// Specialized confirmation for regenerating site QR codes.
  static Future<bool> confirmRegenerateQr(
    BuildContext context, {
    required String siteName,
  }) {
    return showConfirmation(
      context: context,
      title: 'Regenerate QR Code',
      message:
          'Regenerating the security QR token for "$siteName" will immediately invalidate all previously printed physical placards on site. Are you sure you want to proceed?',
      confirmLabel: 'Regenerate Token',
      isDestructive: true,
      icon: Icons.sync_problem_rounded,
    );
  }
}
