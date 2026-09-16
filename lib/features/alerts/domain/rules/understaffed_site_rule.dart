import '../entities/alert.dart';
import '../entities/alert_type.dart';
import '../policies/site_coverage_provider.dart';
import '../services/alert_id_generator.dart';
import 'alert_rule.dart';

class UnderstaffedSiteInput {
  final String organizationId;
  final String siteId;

  const UnderstaffedSiteInput({
    required this.organizationId,
    required this.siteId,
  });
}

class UnderstaffedSiteRule implements AlertRule<UnderstaffedSiteInput> {
  final SiteCoverageProvider coverageProvider;

  const UnderstaffedSiteRule({
    required this.coverageProvider,
  });

  @override
  String get ruleName => 'UNDERSTAFFED_SITE';

  @override
  Future<Alert?> evaluate(
    UnderstaffedSiteInput input, {
    required DateTime evaluationTime,
  }) async {
    final coverage = await coverageProvider.getCoverage(
      organizationId: input.organizationId,
      siteId: input.siteId,
      evaluationTime: evaluationTime,
    );

    if (!coverage.isUnderstaffed) {
      return null;
    }

    final dateKey =
        '${evaluationTime.year}-${evaluationTime.month.toString().padLeft(2, '0')}-${evaluationTime.day.toString().padLeft(2, '0')}_${evaluationTime.hour}';
    final alertId = AlertIdGenerator.understaffedSite(
      input.organizationId,
      input.siteId,
      dateKey,
    );

    return Alert(
      alertId: alertId,
      organizationId: input.organizationId,
      type: AlertType.understaffedSite,
      sourceEntityId: input.siteId,
      sourceEntityType: 'site',
      createdAt: evaluationTime,
      metadata: {
        'siteId': input.siteId,
        'requiredStaff': coverage.requiredStaff,
        'actualStaff': coverage.actualStaff,
        'deficit': coverage.requiredStaff - coverage.actualStaff,
      },
    );
  }
}
