/// Pure interval overlap validation logic for shift assignments.
///
/// Uses the half-open interval model `[start, end)`.
///
/// Invariants:
/// - Two shifts `[startA, endA)` and `[startB, endB)` overlap if and only if:
///   `startA < endB` AND `startB < endA`.
/// - Adjacency (e.g. 09:00–12:00 and 12:00–17:00) is ALLOWED (does not overlap).
/// - Overlap (e.g. 09:00–12:00 and 11:59–17:00) is CONFLICT (overlaps).
class ShiftOverlapValidator {
  const ShiftOverlapValidator._();

  /// Determines whether two shift time intervals `[startA, endA)` and `[startB, endB)` overlap.
  static bool hasShiftOverlap({
    required DateTime startA,
    required DateTime endA,
    required DateTime startB,
    required DateTime endB,
  }) {
    return startA.isBefore(endB) && startB.isBefore(endA);
  }
}
