import 'package:flutter/foundation.dart';

enum OrganizationStatus {
  active,
  inactive;

  String toMapString() => name;

  static OrganizationStatus fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return OrganizationStatus.active;
      case 'inactive':
        return OrganizationStatus.inactive;
      default:
        return OrganizationStatus.active;
    }
  }
}

@immutable
class Organization {
  final String id;
  final String name;
  final String code;
  final OrganizationStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Organization({
    required this.id,
    required this.name,
    required this.code,
    this.status = OrganizationStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  Organization copyWith({
    String? id,
    String? name,
    String? code,
    OrganizationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'status': status.toMapString(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory Organization.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      try {
        return (val as dynamic).toDate();
      } catch (_) {
        return null;
      }
    }

    return Organization(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      code: map['code'] as String? ?? '',
      status: OrganizationStatus.fromMapString(
        map['status'] as String? ?? 'active',
      ),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Organization &&
        other.id == id &&
        other.name == name &&
        other.code == code &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, code, status);
  }
}
