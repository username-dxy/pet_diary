import 'dart:async';

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

  static const EventChannel _eventChannel =
      EventChannel('com.petdiary/photo_scan_events');

  /// Raw event stream from the EventChannel (includes scanComplete sentinels)
  late final Stream<Map<String, dynamic>> rawScanEventStream;

  /// Filtered stream of scan results only (no sentinels)
  late final Stream<ScanResult> scanResultStream;

  BackgroundScanService() {
    // Setup EventChannel broadcast stream
    final broadcastStream = _eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map))
        .asBroadcastStream();

    rawScanEventStream = broadcastStream;

    scanResultStream = broadcastStream
        .where((event) => event['type'] != 'scanComplete')
        .map((event) => ScanResult.fromMap(event));
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

  /// Perform a manual scan (fire-and-forget)
  /// Returns true if scan was triggered successfully.
  /// Results arrive via [scanResultStream] / [rawScanEventStream].
  Future<bool> performManualScan() async {
    try {
      debugPrint('[BackgroundScan] Triggering manual scan...');
      final result =
          await _channel.invokeMethod<bool>('performManualScan') ?? false;
      debugPrint('[BackgroundScan] Manual scan triggered: $result');
      return result;
    } catch (e) {
      debugPrint('[BackgroundScan] Manual scan trigger failed: $e');
      return false;
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
