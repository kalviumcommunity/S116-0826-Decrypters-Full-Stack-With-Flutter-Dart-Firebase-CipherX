/// Configurable policy determining when a shift check-in is considered late.
///
/// Keeps threshold logic replaceable and avoids hard-coded business assumptions.
abstract interface class LateCheckInPolicy {
  Duration get lateThreshold;

  bool isLate({
    required DateTime scheduledStartTime,
    required DateTime evaluationTime,
    DateTime? actualCheckInTime,
  });
}

class DefaultLateCheckInPolicy implements LateCheckInPolicy {
  @override
  final Duration lateThreshold;

  const DefaultLateCheckInPolicy({
    this.lateThreshold = const Duration(minutes: 15),
  });

  @override
  bool isLate({
    required DateTime scheduledStartTime,
    required DateTime evaluationTime,
    DateTime? actualCheckInTime,
  }) {
    final thresholdBoundary = scheduledStartTime.add(lateThreshold);

    if (actualCheckInTime != null) {
      return actualCheckInTime.isAfter(thresholdBoundary);
    }

    return evaluationTime.isAfter(thresholdBoundary);
  }
}
