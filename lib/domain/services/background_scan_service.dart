import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pet_diary/data/models/scan_result.dart';

/// Photo permission status from iOS
enum PhotoPermissionStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
  limited,
  unknown,
}

/// Service for communicating with iOS background photo scanning
class BackgroundScanService {
  static const MethodChannel _channel =
      MethodChannel('com.petdiary/background_scan');

  /// Callback for when pet photos are found in background
  Function(List<ScanResult>)? onPetPhotosFound;

  BackgroundScanService() {
    _setupMethodCallHandler();
  }

  /// Setup handler for callbacks from iOS
  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPetPhotosFound') {
        final List<dynamic> results = call.arguments as List<dynamic>;
        final scanResults = results
            .map((e) => ScanResult.fromMap(e as Map<dynamic, dynamic>))
            .toList();

        debugPrint(
            '[BackgroundScan] Received ${scanResults.length} pet photos from background');
        onPetPhotosFound?.call(scanResults);
      }
    });
  }

  /// Enable background scanning
  /// Returns true if successfully enabled, false if permission denied
  Future<bool> enableBackgroundScan() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('enableBackgroundScan') ?? false;
      debugPrint('[BackgroundScan] Enable result: $result');
      return result;
    } catch (e) {
      debugPrint('[BackgroundScan] Failed to enable: $e');
      return false;
    }
  }

  /// Disable background scanning
  Future<bool> disableBackgroundScan() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('disableBackgroundScan') ?? false;
      debugPrint('[BackgroundScan] Disable result: $result');
      return result;
    } catch (e) {
      debugPrint('[BackgroundScan] Failed to disable: $e');
      return false;
    }
  }

  /// Check if background scanning is enabled
  Future<bool> isBackgroundScanEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isBackgroundScanEnabled') ??
          false;
    } catch (e) {
      debugPrint('[BackgroundScan] Failed to check enabled status: $e');
      return false;
    }
  }

  /// Perform a manual scan
  /// Returns list of detected pet photos
  Future<List<ScanResult>> performManualScan() async {
    try {
      debugPrint('[BackgroundScan] Starting manual scan...');
      final List<dynamic>? results =
          await _channel.invokeMethod<List<dynamic>>('performManualScan');

      if (results == null || results.isEmpty) {
        debugPrint('[BackgroundScan] Manual scan: no pets found');
        return [];
      }

      final scanResults = results
          .map((e) => ScanResult.fromMap(e as Map<dynamic, dynamic>))
          .toList();
      debugPrint(
          '[BackgroundScan] Manual scan found ${scanResults.length} pets');
      return scanResults;
    } catch (e) {
      debugPrint('[BackgroundScan] Manual scan failed: $e');
      return [];
    }
  }

  /// Request photo library permission
  Future<PhotoPermissionStatus> requestPhotoPermission() async {
    try {
      final String? status =
          await _channel.invokeMethod<String>('requestPhotoPermission');
      return _parsePermissionStatus(status);
    } catch (e) {
      debugPrint('[BackgroundScan] Failed to request permission: $e');
      return PhotoPermissionStatus.unknown;
    }
  }

  /// Get current photo permission status
  Future<PhotoPermissionStatus> getPhotoPermissionStatus() async {
    try {
      final String? status =
          await _channel.invokeMethod<String>('getPhotoPermissionStatus');
      return _parsePermissionStatus(status);
    } catch (e) {
      debugPrint('[BackgroundScan] Failed to get permission status: $e');
      return PhotoPermissionStatus.unknown;
    }
  }

  /// Get last scan time
  Future<DateTime?> getLastScanTime() async {
    try {
      final String? timeString =
          await _channel.invokeMethod<String>('getLastScanTime');
      if (timeString == null) return null;
      return DateTime.parse(timeString);
    } catch (e) {
      debugPrint('[BackgroundScan] Failed to get last scan time: $e');
      return null;
    }
  }

  /// Reset processed photos (for debugging/testing)
  Future<bool> resetProcessedPhotos() async {
    try {
      return await _channel.invokeMethod<bool>('resetProcessedPhotos') ?? false;
    } catch (e) {
      debugPrint('[BackgroundScan] Failed to reset: $e');
      return false;
    }
  }

  /// Parse permission status string from iOS
  PhotoPermissionStatus _parsePermissionStatus(String? status) {
    switch (status) {
      case 'notDetermined':
        return PhotoPermissionStatus.notDetermined;
      case 'restricted':
        return PhotoPermissionStatus.restricted;
      case 'denied':
        return PhotoPermissionStatus.denied;
      case 'authorized':
        return PhotoPermissionStatus.authorized;
      case 'limited':
        return PhotoPermissionStatus.limited;
      default:
        return PhotoPermissionStatus.unknown;
    }
  }

  /// Check if permission is sufficient for background scanning
  bool hasEnoughPermission(PhotoPermissionStatus status) {
    return status == PhotoPermissionStatus.authorized ||
        status == PhotoPermissionStatus.limited;
  }
}
