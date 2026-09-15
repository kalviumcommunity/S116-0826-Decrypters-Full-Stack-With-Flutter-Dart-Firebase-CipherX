import 'dart:typed_data';

/// Pure domain abstraction for evidence image compression.
abstract class ImageCompressor {
  /// Determines if a MIME type is a compressible image format.
  bool isCompressible(String contentType);

  /// Compresses raw image [bytes].
  ///
  /// Returns compressed bytes, or throws [CompressionFailure] if compression fails.
  Future<Uint8List> compress({
    required Uint8List bytes,
    required String contentType,
    int quality = 80,
    int maxWidth = 1920,
    int maxHeight = 1080,
  });
}
