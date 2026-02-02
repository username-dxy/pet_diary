import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pet_diary/data/data_sources/remote/image_api_service.dart';
import 'package:pet_diary/data/models/scan_result.dart';
import 'package:pet_diary/domain/services/photo_compression_service.dart';

/// Orchestrates scan result aggregation, compression, and upload
class ScanUploadService {
  final PhotoCompressionService _compressionService;
  final ImageApiService _imageApiService;

  ScanUploadService({
    PhotoCompressionService? compressionService,
    ImageApiService? imageApiService,
  })  : _compressionService =
            compressionService ?? PhotoCompressionService(),
        _imageApiService = imageApiService ?? ImageApiService();

  /// Aggregate scan results by date (YYYY-MM-DD)
  Map<String, List<ScanResult>> aggregateByDay(List<ScanResult> results) {
    final map = <String, List<ScanResult>>{};
    final formatter = DateFormat('yyyy-MM-dd');

    for (final result in results) {
      final dateKey = result.creationDate != null
          ? formatter.format(result.creationDate!)
          : formatter.format(DateTime.now());
      map.putIfAbsent(dateKey, () => []).add(result);
    }

    return map;
  }

  /// Compress and upload one day's photos.
  /// Returns the number of successfully uploaded photos.
  Future<int> compressAndUpload({
    required String petId,
    required String date,
    required List<ScanResult> results,
    void Function(int completed, int total)? onProgress,
  }) async {
    int uploaded = 0;
    final tempFiles = <String>[];

    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      try {
        // Compress
        final compressedPath =
            await _compressionService.compressPhoto(result.tempFilePath);
        if (compressedPath != result.tempFilePath) {
          tempFiles.add(compressedPath);
        }

        // Build upload item
        final item = ImageUploadItem(
          filePath: compressedPath,
          assetId: result.assetId,
          petId: petId,
          date: date,
          time: result.creationDate?.millisecondsSinceEpoch,
          location: _formatLocation(result.latitude, result.longitude),
        );

        // Upload single photo
        final response = await _imageApiService.uploadImages([item]);
        if (response.success) {
          uploaded++;
          debugPrint('[ScanUpload] Uploaded ${result.assetId} for $date');
        } else {
          debugPrint(
              '[ScanUpload] Upload failed for ${result.assetId}: ${response.errorMessage}');
        }
      } catch (e) {
        debugPrint('[ScanUpload] Error processing ${result.assetId}: $e');
      }

      onProgress?.call(i + 1, results.length);
    }

    // Cleanup compressed temp files
    for (final path in tempFiles) {
      await _compressionService.cleanupTempFile(path);
    }

    return uploaded;
  }

  String? _formatLocation(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    return '$lat,$lng';
  }
}
