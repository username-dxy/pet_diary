import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pet_diary/config/api_config.dart';
import 'package:pet_diary/data/models/pet.dart';
import 'package:pet_diary/data/models/emotion_record.dart';
import 'package:pet_diary/data/models/scan_result.dart';
import 'package:pet_diary/data/repositories/pet_repository.dart';
import 'package:pet_diary/data/repositories/emotion_repository.dart';
import 'package:pet_diary/domain/services/background_scan_service.dart';
import 'package:pet_diary/domain/services/scan_upload_service.dart';

class HomeViewModel extends ChangeNotifier {
  final PetRepository _petRepository = PetRepository();
  final EmotionRepository _emotionRepository = EmotionRepository();
  final BackgroundScanService _scanService = BackgroundScanService();
  final ScanUploadService _uploadService = ScanUploadService();

  Pet? _currentPet;
  EmotionRecord? _todaySticker;
  bool _hasNewDiary = false;
  bool _isLoading = false;
  bool _isDrawerOpen = false;

  // Scan state
  bool _isScanning = false;
  int _scanProgress = 0;
  int _scanTotal = 0;
  String _scanStatus = '';

  StreamSubscription<Map<String, dynamic>>? _scanEventSubscription;

  // Getters
  Pet? get currentPet => _currentPet;
  EmotionRecord? get todaySticker => _todaySticker;
  bool get hasNewDiary => _hasNewDiary;
  bool get isLoading => _isLoading;
  bool get isDrawerOpen => _isDrawerOpen;
  bool get isScanning => _isScanning;
  int get scanProgress => _scanProgress;
  int get scanTotal => _scanTotal;
  String get scanStatus => _scanStatus;

  /// 切换抽屉状态
  void toggleDrawer() {
    _isDrawerOpen = !_isDrawerOpen;
    notifyListeners();
  }

  /// 关闭抽屉
  void closeDrawer() {
    if (_isDrawerOpen) {
      _isDrawerOpen = false;
      notifyListeners();
    }
  }

  /// 加载数据
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 加载当前宠物
      _currentPet = await _petRepository.getCurrentPet();

      // 确保 token 存在（用 petId 作为 dev token）
      if (_currentPet != null && !(await ApiConfig.hasToken)) {
        await ApiConfig.setToken(_currentPet!.id);
        debugPrint('[Home] Token 已恢复: ${_currentPet!.id}');
      }

      // 加载今日贴纸
      _todaySticker = await _emotionRepository.getTodayRecord();

      // 检查是否有新日记（TODO）
      _hasNewDiary = _checkNewDiary();

      // 触发扫描上传管线
      _triggerScanOnStartup();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _checkNewDiary() {
    // TODO: 实现逻辑
    return false;
  }

  /// 启动时触发扫描 + 上传管线
  Future<void> _triggerScanOnStartup() async {
    if (_currentPet == null) {
      debugPrint('[HomeScan] No pet, skip scan');
      return;
    }

    try {
      // 1. 检查权限
      final permStatus = await _scanService.getPhotoPermissionStatus();
      if (!_scanService.hasEnoughPermission(permStatus)) {
        debugPrint('[HomeScan] No photo permission, skip scan');
        return;
      }

      _isScanning = true;
      _scanStatus = '正在扫描相册...';
      notifyListeners();

      // 2. 收集结果
      final results = <ScanResult>[];
      final completer = Completer<void>();

      _scanEventSubscription =
          _scanService.rawScanEventStream.listen((event) {
        final type = event['type'] as String?;
        if (type == 'scanComplete') {
          _scanTotal = event['totalFound'] as int? ?? 0;
          debugPrint('[HomeScan] Scan complete: $_scanTotal found');
          completer.complete();
        } else if (type == 'scanResult') {
          try {
            results.add(ScanResult.fromMap(event));
          } catch (e) {
            debugPrint('[HomeScan] Failed to parse scan result: $e');
          }
        }
      }, onError: (error) {
        debugPrint('[HomeScan] Event stream error: $error');
        if (!completer.isCompleted) completer.complete();
      });

      // 3. 触发扫描
      final triggered = await _scanService.performManualScan();
      if (!triggered) {
        debugPrint('[HomeScan] Failed to trigger scan');
        _isScanning = false;
        _scanStatus = '';
        notifyListeners();
        return;
      }

      // 4. 等待 scanComplete（with timeout）
      await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          debugPrint('[HomeScan] Scan timed out');
        },
      );

      await _scanEventSubscription?.cancel();
      _scanEventSubscription = null;

      if (results.isEmpty) {
        debugPrint('[HomeScan] No pet photos found');
        _isScanning = false;
        _scanStatus = '';
        notifyListeners();
        return;
      }

      // 5. 按天聚合
      _scanStatus = '正在上传照片...';
      notifyListeners();

      final byDay = _uploadService.aggregateByDay(results);
      debugPrint('[HomeScan] Aggregated into ${byDay.length} days');

      // 6. 逐天压缩上传
      int totalUploaded = 0;
      int dayIndex = 0;
      for (final entry in byDay.entries) {
        dayIndex++;
        _scanStatus = '正在上传 $dayIndex/${byDay.length} 天...';
        _scanProgress = dayIndex;
        _scanTotal = byDay.length;
        notifyListeners();

        final count = await _uploadService.compressAndUpload(
          petId: _currentPet!.id,
          date: entry.key,
          results: entry.value,
        );
        totalUploaded += count;
      }

      debugPrint('[HomeScan] Upload complete: $totalUploaded photos');
      _scanStatus = '上传完成，共 $totalUploaded 张';
      notifyListeners();

      // Brief delay to show the completion message
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[HomeScan] Scan pipeline error: $e');
    } finally {
      _isScanning = false;
      _scanStatus = '';
      _scanProgress = 0;
      _scanTotal = 0;
      notifyListeners();
      await _scanEventSubscription?.cancel();
      _scanEventSubscription = null;
    }
  }

  /// 刷新数据（从日历页返回时调用）
  Future<void> refresh() async {
    await loadData();
  }

  @override
  void dispose() {
    _scanEventSubscription?.cancel();
    super.dispose();
  }
}
