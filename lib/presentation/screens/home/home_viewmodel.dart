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
      // 🔧 调试日志：检查 API 配置
      final token = await ApiConfig.getToken();
      final baseUrl = ApiConfig.baseUrl;
      debugPrint('🔧 [HomeLoad] ==================');
      debugPrint('🔧 [HomeLoad] Token: ${token ?? "(未设置)"}');
      debugPrint('🔧 [HomeLoad] Base URL: $baseUrl');
      debugPrint('🔧 [HomeLoad] ==================');

      // 加载当前宠物
      _currentPet = await _petRepository.getCurrentPet();

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
      debugPrint('📷 [HomeScan] No pet, skip scan');
      return;
    }

    debugPrint('📷 [HomeScan] ==================');
    debugPrint('📷 [HomeScan] 开始扫描流程');
    debugPrint('📷 [HomeScan] Pet ID: ${_currentPet!.id}');
    debugPrint('📷 [HomeScan] ==================');

    try {
      // 1. 检查权限
      final permStatus = await _scanService.getPhotoPermissionStatus();
      debugPrint('📷 [HomeScan] 权限状态: $permStatus');
      if (!_scanService.hasEnoughPermission(permStatus)) {
        debugPrint('❌ [HomeScan] 权限不足，跳过扫描');
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
          debugPrint('✅ [HomeScan] 扫描完成: 发现 $_scanTotal 张照片');
          completer.complete();
        } else if (type == 'scanResult') {
          try {
            final result = ScanResult.fromMap(event);
            results.add(result);
            debugPrint('📷 [HomeScan] 扫描到: ${result.assetId} (Pet: ${_currentPet!.id})');
          } catch (e) {
            debugPrint('❌ [HomeScan] 解析扫描结果失败: $e');
          }
        }
      }, onError: (error) {
        debugPrint('❌ [HomeScan] 事件流错误: $error');
        if (!completer.isCompleted) completer.complete();
      });

      // 3. 触发扫描
      debugPrint('📷 [HomeScan] 触发扫描...');
      final triggered = await _scanService.performManualScan();
      if (!triggered) {
        debugPrint('❌ [HomeScan] 扫描触发失败');
        _isScanning = false;
        _scanStatus = '';
        notifyListeners();
        return;
      }
      debugPrint('✅ [HomeScan] 扫描已触发，等待结果...');

      // 4. 等待 scanComplete（with timeout）
      await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          debugPrint('⚠️ [HomeScan] 扫描超时（5 分钟）');
        },
      );

      await _scanEventSubscription?.cancel();
      _scanEventSubscription = null;

      if (results.isEmpty) {
        debugPrint('ℹ️ [HomeScan] 未发现宠物照片');
        _isScanning = false;
        _scanStatus = '';
        notifyListeners();
        return;
      }

      // 5. 按天聚合
      debugPrint('📊 [HomeScan] ==================');
      debugPrint('📊 [HomeScan] 开始上传流程');
      debugPrint('📊 [HomeScan] 收集到 ${results.length} 张照片');
      _scanStatus = '正在上传照片...';
      notifyListeners();

      final byDay = _uploadService.aggregateByDay(results);
      debugPrint('📊 [HomeScan] 按天聚合: ${byDay.length} 天');
      for (final entry in byDay.entries) {
        debugPrint('   ${entry.key}: ${entry.value.length} 张');
      }

      // 6. 逐天压缩上传
      debugPrint('📤 [HomeScan] ==================');
      int totalUploaded = 0;
      int dayIndex = 0;
      for (final entry in byDay.entries) {
        dayIndex++;
        debugPrint('📤 [HomeScan] 上传第 $dayIndex/${byDay.length} 天');
        debugPrint('   日期: ${entry.key}');
        debugPrint('   照片数: ${entry.value.length}');

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
        debugPrint('✅ [HomeScan] ${entry.key} 上传完成: $count/${entry.value.length} 张');
      }

      debugPrint('🎉 [HomeScan] ==================');
      debugPrint('🎉 [HomeScan] 上传完成!');
      debugPrint('🎉 [HomeScan] 总计: $totalUploaded 张照片');
      debugPrint('🎉 [HomeScan] ==================');
      _scanStatus = '上传完成，共 $totalUploaded 张';
      notifyListeners();

      // Brief delay to show the completion message
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('❌ [HomeScan] 扫描管线错误: $e');
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
