import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../identity/presentation/providers/identity_providers.dart';
import '../../../shifts/domain/entities/shift.dart';
import '../providers/guard_shifts_provider.dart';

class GuardHomeScreen extends ConsumerWidget {
  const GuardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final guardShiftsAsync = ref.watch(guardShiftsProvider);
    final activeAttendanceAsync = ref.watch(activeAttendanceProvider);

    final profile = profileAsync.asData?.value;
    final guardName = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : 'Guard';

    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning,'
        : now.hour < 17
            ? 'Good afternoon,'
            : 'Good evening,';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(guardShiftsProvider);
            ref.invalidate(activeAttendanceProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar with Official Logo & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowColor,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/cipher_x_logo.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cipher-X',
                          style: AppTextStyles.titleMedium(
                            color: AppColors.textPrimaryLight,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowColor,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.textSecondaryLight,
                          size: 18,
                        ),
                      ),
                      tooltip: 'Logout',
                      onPressed: () =>
                          ref.read(authControllerProvider.notifier).signOut(),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Guard Greeting Area
                Text(
                  greeting,
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.textSecondaryLight,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      guardName,
                      style: AppTextStyles.displayLarge(
                        color: AppColors.textPrimaryLight,
                      ).copyWith(fontSize: 26),
                    ),
                    const SizedBox(width: 6),
                    const Text('🛡️', style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Post verified & operations active',
                  style: AppTextStyles.caption(
                    color: AppColors.primaryLight,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                // Hero Section (Dual Cards matching Reference Screen 2)
                guardShiftsAsync.when(
                  data: (shiftData) {
                    final todayShift = shiftData.todayShift;
                    final activeAttendance =
                        activeAttendanceAsync.asData?.value;
                    final isOnDuty = activeAttendance != null;

                    return Row(
                      children: [
                        // Left Hero: Shift Status (Wine Gradient)
                        Expanded(
                          flex: 6,
                          child: AppCard.wineHero(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Live Shift',
                                      style: AppTextStyles.caption(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOnDuty
                                            ? AppColors.success
                                            : Colors.white
                                                .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isOnDuty ? 'ON DUTY' : 'READY',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  isOnDuty
                                      ? 'Active Post'
                                      : (todayShift != null
                                          ? 'Assigned'
                                          : 'No Shift'),
                                  style: AppTextStyles.headlineLarge(
                                    color: Colors.white,
                                  ).copyWith(fontSize: 22),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  todayShift != null
                                      ? '${todayShift.startTime} - ${todayShift.endTime}'
                                      : 'Standby for assignment',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Right Hero: Security Status (Pearl White Card)
                        Expanded(
                          flex: 5,
                          child: AppCard.pearl(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Security Score',
                                  style: AppTextStyles.caption(
                                    color: AppColors.textSecondaryLight,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  isOnDuty ? '100%' : '95%',
                                  style: AppTextStyles.headlineLarge(
                                    color: AppColors.textPrimaryLight,
                                  ).copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isOnDuty
                                      ? 'Geofence Active'
                                      : 'Optimal Standby',
                                  style: TextStyle(
                                    color: isOnDuty
                                        ? AppColors.success
                                        : AppColors.textSecondaryLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: isOnDuty ? 1.0 : 0.95,
                                    backgroundColor: AppColors.borderLight,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isOnDuty
                                          ? AppColors.success
                                          : AppColors.primary,
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 26),

                // Quick Access Section (Matching Reference Screen 2)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Access',
                      style: AppTextStyles.titleMedium(
                        color: AppColors.textPrimaryLight,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.shift),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4 Squircle Quick Access Cards
                Row(
                  children: [
                    _buildQuickActionSquircle(
                      context,
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Check-In',
                      onTap: () => context.push(AppRoutes.checkIn),
                    ),
                    const SizedBox(width: 10),
                    _buildQuickActionSquircle(
                      context,
                      icon: Icons.assignment_outlined,
                      label: 'Shifts',
                      onTap: () => context.push(AppRoutes.shift),
                    ),
                    const SizedBox(width: 10),
                    _buildQuickActionSquircle(
                      context,
                      icon: Icons.warning_amber_rounded,
                      label: 'Report',
                      onTap: () => context.push(AppRoutes.reportIncident),
                    ),
                    const SizedBox(width: 10),
                    _buildQuickActionSquircle(
                      context,
                      icon: Icons.history_rounded,
                      label: 'History',
                      onTap: () => context.push(AppRoutes.attendanceHistory),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                // Today's Operational Status / Assigned Site
                Text(
                  "Today's Shift Assignment",
                  style: AppTextStyles.titleMedium(
                    color: AppColors.textPrimaryLight,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),

                guardShiftsAsync.when(
                  data: (shiftData) {
                    final todayShift = shiftData.todayShift;
                    if (todayShift == null) {
                      return AppCard.pearl(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.calendar_today_outlined,
                                color: AppColors.textSecondaryLight,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No Shift Scheduled Today',
                                    style: AppTextStyles.titleMedium(
                                      color: AppColors.textPrimaryLight,
                                    ).copyWith(fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Check upcoming shifts or contact your supervisor.',
                                    style: AppTextStyles.bodyMedium(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return AppCard.pearl(
                      onTap: () => context.push(AppRoutes.shift),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Scheduled Shift',
                                style: AppTextStyles.caption(
                                  color: AppColors.textSecondaryLight,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                              StatusBadge(
                                label: todayShift.status.name.toUpperCase(),
                                variant: todayShift.status == ShiftStatus.active
                                    ? StatusBadgeVariant.success
                                    : StatusBadgeVariant.wine,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accentRose,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Site: ${todayShift.siteId}',
                                      style: AppTextStyles.titleMedium(
                                        color: AppColors.textPrimaryLight,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${todayShift.startTime} - ${todayShift.endTime} (${DateFormat('MMM d, y').format(todayShift.date)})',
                                      style: AppTextStyles.bodyMedium(
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondaryLight,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Text('Error: $err'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionSquircle(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.borderLight,
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(
                    color: AppColors.textPrimaryLight,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
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


