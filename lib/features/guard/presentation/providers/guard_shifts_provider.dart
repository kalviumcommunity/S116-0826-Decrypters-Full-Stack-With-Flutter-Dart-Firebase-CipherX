import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../identity/presentation/providers/identity_providers.dart';
import '../../../shifts/domain/entities/shift.dart';
import '../../../shifts/presentation/providers/shift_providers.dart';
import '../../../sites/domain/entities/site.dart';
import '../../../sites/presentation/providers/site_providers.dart';

class GuardShiftsData {
  final Shift? todayShift;
  final List<Shift> upcomingShifts;

  const GuardShiftsData({
    required this.todayShift,
    required this.upcomingShifts,
  });
}

final guardShiftsProvider = StreamProvider.autoDispose<GuardShiftsData>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value(
      const GuardShiftsData(todayShift: null, upcomingShifts: []),
    );
  }

  final repository = ref.watch(shiftRepositoryProvider);
  return repository
      .watchShiftsByGuard(profile.organizationId, profile.uid)
      .map((shifts) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);

    Shift? todayShift;
    final upcomingShifts = <Shift>[];

    for (final shift in shifts) {
      final shiftDate =
          DateTime.utc(shift.date.year, shift.date.month, shift.date.day);
      if (shiftDate.isAtSameMomentAs(today) &&
          shift.status != ShiftStatus.cancelled) {
        if (todayShift == null || shift.status == ShiftStatus.active) {
          todayShift = shift;
        }
      } else if (shiftDate.isAfter(today) &&
          shift.status != ShiftStatus.cancelled) {
        upcomingShifts.add(shift);
      }
    }

    upcomingShifts.sort((a, b) => a.date.compareTo(b.date));

    return GuardShiftsData(
      todayShift: todayShift,
      upcomingShifts: upcomingShifts,
    );
  });
});

final siteProvider =
    FutureProvider.family.autoDispose<Site?, String>((ref, siteId) async {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return null;
  }

  final repository = ref.watch(siteRepositoryProvider);
  return await repository.getSite(
    organizationId: profile.organizationId,
    siteId: siteId,
  );
});
