import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pet_diary/data/data_sources/remote/image_api_service.dart';
import 'package:pet_diary/data/models/scan_result.dart';
import 'package:pet_diary/domain/services/photo_compression_service.dart';

class ServerHitLimitException implements Exception {
  final String message;

  const ServerHitLimitException(this.message);

  @override
  String toString() => 'ServerHitLimitException: $message';
}

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
        debugPrint('🔧 [ScanUpload] 处理 ${i + 1}/${results.length}: ${result.assetId}');

        // Compress
        debugPrint('   🗜️  压缩中...');
        final compressedPath =
            await _compressionService.compressPhoto(result.tempFilePath);
        if (compressedPath != result.tempFilePath) {
          tempFiles.add(compressedPath);
          debugPrint('   ✅ 已压缩');
        } else {
          debugPrint('   ℹ️  无需压缩');
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
        debugPrint('   📤 上传中...');
        final response = await _imageApiService.uploadImages([item]);
        if (response.success) {
          uploaded++;
          debugPrint('   ✅ 上传成功: ${result.assetId} ($date)');
          if ((response.data?.duplicates ?? 0) > 0) {
            debugPrint('   ⚠️  检测到重复');
          }
        } else {
          if (_isHitLimitError(response.errorMessage)) {
            throw ServerHitLimitException(response.errorMessage);
          }
          debugPrint(
              '   ❌ 上传失败: ${result.assetId} - ${response.errorMessage}');
        }
      } on ServerHitLimitException {
        rethrow;
      } catch (e) {
        debugPrint('   ❌ 处理错误: ${result.assetId} - $e');
      }

      onProgress?.call(i + 1, results.length);
    }

    // Cleanup compressed temp files
    for (final path in tempFiles) {
      await _compressionService.cleanupTempFile(path);
    }

    return uploaded;
  }

  bool _isHitLimitError(String? message) {
    if (message == null || message.isEmpty) return false;
    final normalized = message.toLowerCase();
    return normalized.contains('hit limit') ||
        normalized.contains('quota') ||
        normalized.contains('次数已用完');
  }

  String? _formatLocation(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    return '$lat,$lng';
  }
}
