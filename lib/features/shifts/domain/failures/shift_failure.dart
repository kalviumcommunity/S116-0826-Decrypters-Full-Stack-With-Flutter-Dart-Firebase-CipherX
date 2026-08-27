abstract class ShiftFailure implements Exception {
  final String message;
  const ShiftFailure(this.message);

  @override
  String toString() => message;
}

class ShiftValidationFailure extends ShiftFailure {
  const ShiftValidationFailure(super.message);
}

class ShiftConflictFailure extends ShiftFailure {
  const ShiftConflictFailure(super.message);
}

class ShiftDatabaseFailure extends ShiftFailure {
  const ShiftDatabaseFailure(super.message);
}

class GuardNotFoundFailure extends ShiftFailure {
  const GuardNotFoundFailure([
    super.message = 'The selected guard does not exist.',
  ]);
}

class GuardInactiveFailure extends ShiftFailure {
  const GuardInactiveFailure([
    super.message = 'This guard is currently inactive and cannot be assigned.',
  ]);
}

class SiteNotFoundFailure extends ShiftFailure {
  const SiteNotFoundFailure([
    super.message = 'The selected site does not exist.',
  ]);
}

class SiteInactiveFailure extends ShiftFailure {
  const SiteInactiveFailure([
    super.message =
        'This site is currently inactive and cannot receive a shift.',
  ]);
}

class CrossOrganizationAssignmentFailure extends ShiftFailure {
  const CrossOrganizationAssignmentFailure([
    super.message =
        'Cross-organization shift assignments are strictly prohibited.',
  ]);
}

class DuplicateShiftFailure extends ShiftFailure {
  const DuplicateShiftFailure([
    super.message = 'A shift with the same assignment already exists.',
  ]);
}
