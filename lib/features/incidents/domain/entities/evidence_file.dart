import 'dart:typed_data';
import 'package:meta/meta.dart';

/// In-memory representation of an un-uploaded evidence file candidate.
@immutable
class EvidenceFile {
  final String name;
  final Uint8List bytes;
  final String contentType;

  const EvidenceFile({
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  int get sizeBytes => bytes.length;

  String get extension {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  EvidenceFile copyWith({
    String? name,
    Uint8List? bytes,
    String? contentType,
  }) {
    return EvidenceFile(
      name: name ?? this.name,
      bytes: bytes ?? this.bytes,
      contentType: contentType ?? this.contentType,
    );
  }
}
