import 'package:meta/meta.dart';
import 'coverage_status.dart';

/// Pure domain entity representing staffing coverage for a specific security site.
@immutable
class SiteCoverageItem {
  final String siteId;
  final String siteName;
  final String organizationId;
  final int actualStaff;
  final int requiredStaff;
  final CoverageStatus status;

  const SiteCoverageItem({
    required this.siteId,
    required this.siteName,
    required this.organizationId,
    required this.actualStaff,
    required this.requiredStaff,
    required this.status,
  });

  bool get isFullyStaffed => status == CoverageStatus.fullyStaffed;
  bool get isUnderstaffed => status == CoverageStatus.understaffed;

  int get deficit => (requiredStaff - actualStaff).clamp(0, requiredStaff);

  SiteCoverageItem copyWith({
    String? siteId,
    String? siteName,
    String? organizationId,
    int? actualStaff,
    int? requiredStaff,
    CoverageStatus? status,
  }) {
    return SiteCoverageItem(
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      organizationId: organizationId ?? this.organizationId,
      actualStaff: actualStaff ?? this.actualStaff,
      requiredStaff: requiredStaff ?? this.requiredStaff,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'siteId': siteId,
      'siteName': siteName,
      'organizationId': organizationId,
      'actualStaff': actualStaff,
      'requiredStaff': requiredStaff,
      'status': status.toMapString(),
    };
  }

  factory SiteCoverageItem.fromMap(Map<String, dynamic> map) {
    return SiteCoverageItem(
      siteId: map['siteId'] as String? ?? '',
      siteName: map['siteName'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      actualStaff: (map['actualStaff'] as num?)?.toInt() ?? 0,
      requiredStaff: (map['requiredStaff'] as num?)?.toInt() ?? 0,
      status: CoverageStatus.fromMapString(map['status'] as String? ?? ''),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SiteCoverageItem &&
        other.siteId == siteId &&
        other.siteName == siteName &&
        other.organizationId == organizationId &&
        other.actualStaff == actualStaff &&
        other.requiredStaff == requiredStaff &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(
        siteId,
        siteName,
        organizationId,
        actualStaff,
        requiredStaff,
        status,
      );
}
