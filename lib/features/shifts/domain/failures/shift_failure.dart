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
