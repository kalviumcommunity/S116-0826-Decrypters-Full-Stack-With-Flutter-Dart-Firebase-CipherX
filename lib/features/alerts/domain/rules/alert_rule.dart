import '../entities/alert.dart';

/// Single-responsibility contract for an individual alert condition rule.
abstract interface class AlertRule<TInput> {
  String get ruleName;
  Future<Alert?> evaluate(TInput input, {required DateTime evaluationTime});
}
