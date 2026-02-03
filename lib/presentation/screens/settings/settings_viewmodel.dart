import 'package:flutter/foundation.dart';
import 'package:pet_diary/data/models/scan_result.dart';
import 'package:pet_diary/data/repositories/background_scan_settings_repository.dart';
import 'package:pet_diary/data/repositories/pet_repository.dart';
import 'package:pet_diary/domain/services/background_scan_service.dart';
import 'package:pet_diary/domain/services/scan_upload_service.dart';

/// ViewModel for the Settings screen
class SettingsViewModel extends ChangeNotifier {
  final BackgroundScanService _scanService = BackgroundScanService();
  final ScanUploadService _uploadService = ScanUploadService();
  final PetRepository _petRepository = PetRepository();
  final BackgroundScanSettingsRepository _settingsRepository =
      BackgroundScanSettingsRepository();

  // Private state
  bool _isBackgroundScanEnabled = false;
  PhotoPermissionStatus _permissionStatus = PhotoPermissionStatus.unknown;
  DateTime? _lastScanTime;
  bool _isLoading = false;
  bool _isScanning = false;
  String? _errorMessage;
  List<ScanResult> _lastScanResults = [];

  // Public getters
  bool get isBackgroundScanEnabled => _isBackgroundScanEnabled;
  PhotoPermissionStatus get permissionStatus => _permissionStatus;
  DateTime? get lastScanTime => _lastScanTime;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  String? get errorMessage => _errorMessage;
  List<ScanResult> get lastScanResults => _lastScanResults;

  /// Check if we have enough permission for background scanning
  bool get hasPermission => _scanService.hasEnoughPermission(_permissionStatus);

  /// Get permission status text
  String get permissionStatusText {
    switch (_permissionStatus) {
      case PhotoPermissionStatus.notDetermined:
        return '未请求';
      case PhotoPermissionStatus.restricted:
        return '受限制';
      case PhotoPermissionStatus.denied:
        return '已拒绝';
      case PhotoPermissionStatus.authorized:
        return '已授权';
      case PhotoPermissionStatus.limited:
        return '部分授权';
      case PhotoPermissionStatus.unknown:
        return '未知';
    }
  }

  /// Initialize the ViewModel
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load settings
      _isBackgroundScanEnabled = await _scanService.isBackgroundScanEnabled();
      _permissionStatus = await _scanService.getPhotoPermissionStatus();
      _lastScanTime = await _scanService.getLastScanTime();
    } catch (e) {
      _errorMessage = '加载设置失败：$e';
      debugPrint('[Settings] Initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Request photo permission
  Future<void> requestPermission() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _permissionStatus = await _scanService.requestPhotoPermission();
      debugPrint('[Settings] Permission status: $_permissionStatus');
    } catch (e) {
      _errorMessage = '请求权限失败：$e';
      debugPrint('[Settings] Request permission error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle background scan
  Future<void> toggleBackgroundScan(bool enabled) async {
    if (enabled && !hasPermission) {
      _errorMessage = '请先授权相册访问权限';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool success;
      if (enabled) {
        success = await _scanService.enableBackgroundScan();
      } else {
        success = await _scanService.disableBackgroundScan();
      }

      if (success) {
        _isBackgroundScanEnabled = enabled;
        await _settingsRepository.setEnabled(enabled);
        debugPrint('[Settings] Background scan ${enabled ? "enabled" : "disabled"}');
      } else {
        _errorMessage = '操作失败，请检查权限';
      }
    } catch (e) {
      _errorMessage = '切换后台扫描失败：$e';
      debugPrint('[Settings] Toggle error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Perform manual scan (fire-and-forget, results stream via EventChannel)
  /// Returns true if scan was triggered successfully.
  Future<bool> performManualScan() async {
    if (!hasPermission) {
      _errorMessage = '请先授权相册访问权限';
      notifyListeners();
      return false;
    }

    _isScanning = true;
    _errorMessage = null;
    _lastScanResults = [];
    notifyListeners();

    try {
      final triggered = await _scanService.performManualScan();
      if (!triggered) {
        _errorMessage = '触发扫描失败';
        _isScanning = false;
        notifyListeners();
        return false;
      }

      // Listen for results via EventChannel
      await for (final event in _scanService.rawScanEventStream) {
        final type = event['type'] as String?;
        if (type == 'scanComplete') {
          final total = event['totalFound'] as int? ?? 0;
          debugPrint('[Settings] Manual scan complete: $total found');
          break;
        } else if (type == 'scanResult') {
          try {
            _lastScanResults.add(ScanResult.fromMap(event));
            notifyListeners();
          } catch (e) {
            debugPrint('[Settings] Failed to parse scan result: $e');
          }
        }
      }

      _lastScanTime = DateTime.now();
      await _settingsRepository.setLastScanTime(_lastScanTime!);
      await _settingsRepository.incrementScanCount();

      debugPrint('[Settings] Manual scan found ${_lastScanResults.length} pets');

      // 扫描完成后自动压缩上传
      if (_lastScanResults.isNotEmpty) {
        final pet = await _petRepository.getCurrentPet();
        if (pet != null) {
          debugPrint('[Settings] Starting upload for ${_lastScanResults.length} photos...');
          final byDay = _uploadService.aggregateByDay(_lastScanResults);
          for (final entry in byDay.entries) {
            await _uploadService.compressAndUpload(
              petId: pet.id,
              date: entry.key,
              results: entry.value,
            );
          }
          debugPrint('[Settings] Upload complete');
        }
      }

      return true;
    } catch (e) {
      _errorMessage = '扫描失败：$e';
      debugPrint('[Settings] Manual scan error: $e');
      return false;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Reset processed photos (for testing)
  Future<void> resetProcessedPhotos() async {
    try {
      await _scanService.resetProcessedPhotos();
      _lastScanResults = [];
      debugPrint('[Settings] Reset processed photos');
    } catch (e) {
      _errorMessage = '重置失败：$e';
      debugPrint('[Settings] Reset error: $e');
    }
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
