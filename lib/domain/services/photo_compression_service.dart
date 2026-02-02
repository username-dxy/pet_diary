import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Compresses photos to max 1080p long edge, JPEG quality 80%
class PhotoCompressionService {
  static const int _maxDimension = 1080;
  static const int _jpegQuality = 80;

  /// Compress a photo from [sourcePath] to max 1080p, JPEG 80%.
  /// Returns the path of the compressed temporary file.
  Future<String> compressPhoto(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    final decoded = await compute(_decodeAndResize, bytes);

    if (decoded == null) {
      debugPrint('[Compression] Failed to decode image: $sourcePath');
      // Return original if decode fails
      return sourcePath;
    }

    final tempDir = await getTemporaryDirectory();
    final fileName =
        'compressed_${DateTime.now().millisecondsSinceEpoch}_${p.basenameWithoutExtension(sourcePath)}.jpg';
    final outPath = p.join(tempDir.path, fileName);
    await File(outPath).writeAsBytes(decoded);

    debugPrint('[Compression] $sourcePath → $outPath');
    return outPath;
  }

  /// Decode, resize if needed, and encode to JPEG.
  /// Runs in an isolate via [compute].
  static Uint8List? _decodeAndResize(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    img.Image resized;
    if (image.width > _maxDimension || image.height > _maxDimension) {
      if (image.width >= image.height) {
        resized = img.copyResize(image, width: _maxDimension);
      } else {
        resized = img.copyResize(image, height: _maxDimension);
      }
    } else {
      resized = image;
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: _jpegQuality));
  }

  /// Delete a compressed temporary file
  Future<void> cleanupTempFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[Compression] Failed to cleanup $path: $e');
    }
  }
}
