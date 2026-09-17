import 'package:meta/meta.dart';

@immutable
abstract class DashboardFailure implements Exception {
  final String message;
  const DashboardFailure(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardFailure &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => '$runtimeType: $message';
}

class DashboardDataFetchFailure extends DashboardFailure {
  const DashboardDataFetchFailure(
      [super.message = 'Failed to load dashboard metrics.']);
}
