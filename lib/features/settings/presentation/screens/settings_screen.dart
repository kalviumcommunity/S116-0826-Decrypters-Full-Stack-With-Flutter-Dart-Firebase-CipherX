import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/greeting_utils.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../identity/presentation/providers/identity_providers.dart';

/// Lightweight, production-safe application settings and system info screen.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _operationalAlerts = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final authUser = ref.watch(authStateProvider).asData?.value;
    final profile = profileAsync.asData?.value;
    final roleTitle = GreetingUtils.getRoleTitle(profile?.role);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Settings & Info'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionHeader('ACCOUNT & SECURITY'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.accentRose,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      profile?.displayName.isNotEmpty == true
                          ? profile!.displayName
                          : (authUser?.email ?? 'Authenticated User'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Role: $roleTitle • ${profile?.organizationId ?? 'General'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 22,
                    ),
                    title: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () async {
                      final confirmed = await AppDialogs.confirmLogout(context);
                      if (confirmed) {
                        ref.read(authControllerProvider.notifier).signOut();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Operational Notifications
            _buildSectionHeader('NOTIFICATIONS'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    activeTrackColor: AppColors.primary,
                    title: const Text(
                      'Operational Alerts',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Real-time notifications for critical site events & shift alerts.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _operationalAlerts,
                    onChanged: (val) {
                      setState(() {
                        _operationalAlerts = val;
                      });
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  SwitchListTile.adaptive(
                    activeTrackColor: AppColors.primary,
                    title: const Text(
                      'Sound Alerts',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Audible tone when new incidents or dispatches occur.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _soundEnabled,
                    onChanged: (val) {
                      setState(() {
                        _soundEnabled = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // System Permissions
            _buildSectionHeader('DEVICE PERMISSIONS'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text('High-Accuracy GPS'),
                    subtitle: Text(
                      'Required for geofence check-in verification.',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Chip(
                      label: Text('Active', style: TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.successBadgeBg,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Divider(height: 1, color: AppColors.borderLight),
                  ListTile(
                    leading: Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text('Camera Scanner'),
                    subtitle: Text(
                      'Required to scan site QR tokens.',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Chip(
                      label: Text('Active', style: TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.successBadgeBg,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About Section (Project Config Version 1.0.0, Team Decrypters)
            _buildSectionHeader('ABOUT CIPHER-X'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/cipher_x_logo.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cipher-X',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Security Workforce Operations',
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.primary,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 16),
                  _buildInfoRow('Application Version', '1.0.0'),
                  const SizedBox(height: 10),
                  _buildInfoRow('Development Team', 'Decrypters'),
                  const SizedBox(height: 10),
                  _buildInfoRow('Architecture', 'Zero Client Trust RBAC'),
                  const SizedBox(height: 10),
                  _buildInfoRow('Platform', 'Flutter / Cloud Firestore'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: AppTextStyles.caption(
          color: AppColors.textSecondaryLight,
        ).copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
