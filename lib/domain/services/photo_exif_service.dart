import 'dart:io';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';

/// 照片EXIF信息提取服务
class PhotoExifService {
  /// 提取照片元数据
  Future<PhotoMetadata> extractMetadata(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      // 提取拍摄时间
      DateTime? takenAt;
      if (data.containsKey('EXIF DateTimeOriginal')) {
        takenAt = _parseExifDateTime(data['EXIF DateTimeOriginal'].toString());
      } else if (data.containsKey('Image DateTime')) {
        takenAt = _parseExifDateTime(data['Image DateTime'].toString());
      }

      // 提取GPS信息
      double? latitude;
      double? longitude;
      String? location;

      if (data.containsKey('GPS GPSLatitude') &&
          data.containsKey('GPS GPSLongitude')) {
        latitude = _parseGPSCoordinate(
          data['GPS GPSLatitude'].toString(),
          data['GPS GPSLatitudeRef']?.toString() ?? 'N',
        );
        longitude = _parseGPSCoordinate(
          data['GPS GPSLongitude'].toString(),
          data['GPS GPSLongitudeRef']?.toString() ?? 'E',
        );

        location = '${latitude?.toStringAsFixed(4)}, ${longitude?.toStringAsFixed(4)}';
      }

      debugPrint('📸 EXIF提取成功: 时间=$takenAt, 地点=$location');

      return PhotoMetadata(
        takenAt: takenAt,
        location: location,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      debugPrint('❌ EXIF提取失败: $e');
      return PhotoMetadata();
    }
  }

  DateTime? _parseExifDateTime(String exifDate) {
    try {
      final parts = exifDate.split(' ');
      if (parts.length != 2) return null;

      final dateParts = parts[0].split(':');
      final timeParts = parts[1].split(':');

      if (dateParts.length != 3 || timeParts.length != 3) return null;

      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (e) {
      return null;
    }
  }

  double? _parseGPSCoordinate(String coordinate, String ref) {
    try {
      final cleaned = coordinate.replaceAll('[', '').replaceAll(']', '');
      final parts = cleaned.split(',').map((e) => e.trim()).toList();

      if (parts.length != 3) return null;

      final degrees = double.parse(parts[0]);
      final minutes = double.parse(parts[1]);
      final seconds = double.parse(parts[2]);

      double decimal = degrees + (minutes / 60) + (seconds / 3600);

      if (ref == 'S' || ref == 'W') {
        decimal = -decimal;
      }

      return decimal;
    } catch (e) {
      return null;
    }
  }
}

class PhotoMetadata {
  final DateTime? takenAt;
  final String? location;
  final double? latitude;
  final double? longitude;

  PhotoMetadata({
    this.takenAt,
    this.location,
    this.latitude,
    this.longitude,
  });
}