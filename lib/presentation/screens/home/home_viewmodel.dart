import 'package:flutter/foundation.dart';
import 'package:pet_diary/data/models/pet.dart';
import 'package:pet_diary/data/models/emotion_record.dart';
import 'package:pet_diary/data/repositories/pet_repository.dart';
import 'package:pet_diary/data/repositories/emotion_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final PetRepository _petRepository = PetRepository();
  final EmotionRepository _emotionRepository = EmotionRepository();

  Pet? _currentPet;
  EmotionRecord? _todaySticker;
  bool _hasNewDiary = false;
  bool _isLoading = false;
  bool _isDrawerOpen = false;

  // Getters
  Pet? get currentPet => _currentPet;
  EmotionRecord? get todaySticker => _todaySticker;
  bool get hasNewDiary => _hasNewDiary;
  bool get isLoading => _isLoading;
  bool get isDrawerOpen => _isDrawerOpen;

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

      // 加载今日贴纸
      _todaySticker = await _emotionRepository.getTodayRecord();

      // 检查是否有新日记（TODO）
      _hasNewDiary = _checkNewDiary();
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

  /// 刷新数据（从日历页返回时调用）
  Future<void> refresh() async {
    await loadData();
  }
}