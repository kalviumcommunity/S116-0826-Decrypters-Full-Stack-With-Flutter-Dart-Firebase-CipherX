import 'dart:convert';
import 'package:meta/meta.dart';

@immutable
class SiteQrPayload {
  static const String expectedType = 'cipher_x_site';
  static const int supportedVersion = 1;

  final String type;
  final String siteId;
  final int version;

  const SiteQrPayload({
    required this.type,
    required this.siteId,
    required this.version,
  });

  /// Factory constructor to create a standard valid SiteQrPayload for a given [siteId].
  factory SiteQrPayload.createForSite(String siteId) {
    return SiteQrPayload(
      type: expectedType,
      siteId: siteId,
      version: supportedVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'siteId': siteId,
      'version': version,
    };
  }

  factory SiteQrPayload.fromMap(Map<String, dynamic> map) {
    final rawType = map['type'];
    final rawSiteId = map['siteId'];
    final rawVersion = map['version'];

    final type = rawType is String ? rawType : '';
    final siteId = rawSiteId is String ? rawSiteId : '';
    final version = rawVersion is int
        ? rawVersion
        : (rawVersion is num ? rawVersion.toInt() : -1);

    return SiteQrPayload(
      type: type,
      siteId: siteId,
      version: version,
    );
  }

  String toJson() => json.encode(toMap());

  factory SiteQrPayload.fromJson(String source) {
    final decoded = json.decode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('QR JSON is not an object.');
    }
    return SiteQrPayload.fromMap(decoded);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteQrPayload &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          siteId == other.siteId &&
          version == other.version;

  @override
  int get hashCode => type.hashCode ^ siteId.hashCode ^ version.hashCode;

  @override
  String toString() =>
      'SiteQrPayload(type: $type, siteId: $siteId, version: $version)';
}
