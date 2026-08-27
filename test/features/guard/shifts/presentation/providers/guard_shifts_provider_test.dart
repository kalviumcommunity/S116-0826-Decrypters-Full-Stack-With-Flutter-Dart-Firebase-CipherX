import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/repositories/shift_repository.dart';
import 'package:cipher_x/features/guard/shifts/presentation/providers/guard_shifts_provider.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';

class MockShiftRepository implements ShiftRepository {
  final List<Shift> shifts;

  MockShiftRepository(this.shifts);

  @override
  Future<List<Shift>> getShiftsByGuard(String organizationId, String guardId) async {
    return shifts;
  }

  @override
  Future<Shift?> getShiftById(String organizationId, String shiftId) async {
    return shifts.firstWhere((s) => s.shiftId == shiftId);
  }
}

void main() {
  group('guardShiftsProvider Tests', () {
    test('categorizes shifts into today and upcoming correctly', () async {
      final now = DateTime.now();
      
      final todayShift = Shift(
        shiftId: '1',
        organizationId: 'org1',
        guardId: 'guard1',
        siteId: 'site1',
        date: now,
        startTime: now,
        endTime: now.add(const Duration(hours: 8)),
        status: ShiftStatus.scheduled,
      );

      final tomorrowShift = Shift(
        shiftId: '2',
        organizationId: 'org1',
        guardId: 'guard1',
        siteId: 'site1',
        date: now.add(const Duration(days: 1)),
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 1, hours: 8)),
        status: ShiftStatus.scheduled,
      );

      final mockRepo = MockShiftRepository([todayShift, tomorrowShift]);
      
      final container = ProviderContainer(
        overrides: [
          currentUserProfileProvider.overrideWithValue(
            AsyncValue.data(
              UserProfile(
                uid: 'guard1',
                email: 'guard@example.com',
                displayName: 'Guard One',
                phone: '1234567890',
                organizationId: 'org1',
                status: UserStatus.active,
                role: UserRole.guard,
              ),
            ),
          ),
          shiftRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final shiftsData = await container.read(guardShiftsProvider.future);

      expect(shiftsData.todayShift?.shiftId, '1');
      expect(shiftsData.upcomingShifts.length, 1);
      expect(shiftsData.upcomingShifts.first.shiftId, '2');
    });
  });
}
