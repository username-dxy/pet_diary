import 'package:flutter/foundation.dart';
import 'package:pet_diary/data/models/diary_entry.dart';
import 'package:pet_diary/data/models/pet.dart';
import 'package:pet_diary/data/data_sources/remote/diary_api_service.dart';
import 'package:pet_diary/data/repositories/diary_repository.dart';
import 'package:pet_diary/data/repositories/pet_repository.dart';
class DiaryViewModel extends ChangeNotifier {
  final DiaryRepository _diaryRepository = DiaryRepository();
  final PetRepository _petRepository = PetRepository();
  final DiaryApiService _diaryApiService = DiaryApiService();

  List<DiaryEntry> _entries = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  Pet? _currentPet;

  // Getters
  List<DiaryEntry> get entries => _entries;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Pet? get currentPet => _currentPet;

  /// 当前显示的日记
  DiaryEntry? get currentEntry {
    if (_entries.isEmpty || _currentIndex >= _entries.length) {
      return null;
    }
    return _entries[_currentIndex];
  }

  /// 是否有上一页
  bool get hasPrevious => _currentIndex > 0;

  /// 是否有下一页
  bool get hasNext => _currentIndex < _entries.length - 1;

  /// 初始化
  Future<void> init() async {
    await loadData();
  }

  /// 加载所有数据 — 优先从服务端，fallback 到本地
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 加载宠物信息
      _currentPet = await _petRepository.getCurrentPet();

      if (_currentPet != null) {
        // 尝试从服务端加载日记
        final loaded = await _loadFromServer(_currentPet!.id);
        if (!loaded) {
          // Fallback 到本地
          debugPrint('[Diary] Server unavailable, loading from local');
          _entries = await _diaryRepository.getRecentEntries(limit: 30);
        }
      } else {
        _entries = await _diaryRepository.getRecentEntries(limit: 30);
      }

      debugPrint('✅ 数据加载完成');
      debugPrint('日记数量: ${_entries.length}');
    } catch (e) {
      _errorMessage = '加载数据失败：$e';
      debugPrint('❌ 加载错误: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 从服务端加载日记列表 + 详情（含 imageList）
  Future<bool> _loadFromServer(String petId) async {
    try {
      // 1. 获取日记列表
      final listResponse = await _diaryApiService.getDiaryList(petId);
      if (!listResponse.success || listResponse.data == null) {
        debugPrint('[Diary] Failed to load diary list from server');
        return false;
      }

      final diaryList = listResponse.data!.diaryList;
      if (diaryList.isEmpty) {
        _entries = [];
        return true;
      }

      // 2. 获取每条日记的详情（含 imageList）
      final entries = <DiaryEntry>[];
      for (final item in diaryList) {
        final detailResponse = await _diaryApiService.getDiaryDetail(
          petId: petId,
          diaryId: item.diaryId,
        );

        if (detailResponse.success && detailResponse.data != null) {
          final detail = detailResponse.data!;
          entries.add(DiaryEntry(
            id: item.diaryId,
            petId: petId,
            date: DateTime.tryParse(detail.date) ?? DateTime.now(),
            content: detail.content,
            imagePath: detail.avatar.isNotEmpty ? detail.avatar : null,
            imageUrls: detail.imageList,
            isLocked: false,
            createdAt: DateTime.tryParse(detail.date) ?? DateTime.now(),
          ));
        }
      }

      _entries = entries;
      debugPrint('[Diary] Loaded ${entries.length} entries from server');
      return true;
    } catch (e) {
      debugPrint('[Diary] Server load error: $e');
      return false;
    }
  }

  /// 翻到上一页
  void previousPage() {
    if (hasPrevious) {
      _currentIndex--;
      notifyListeners();
    }
  }

  /// 翻到下一页
  void nextPage() {
    if (hasNext) {
      _currentIndex++;
      notifyListeners();
    }
  }

  /// 跳转到指定索引
  void jumpToIndex(int index) {
    if (index >= 0 && index < _entries.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// 删除日记
  Future<void> deleteEntry(String id) async {
    try {
      await _diaryRepository.deleteEntry(id);
      _entries = _entries.where((e) => e.id != id).toList();
      if (_currentIndex >= _entries.length && _currentIndex > 0) {
        _currentIndex = _entries.length - 1;
      }
      notifyListeners();
      debugPrint('✅ 日记已删除');
    } catch (e) {
      _errorMessage = '删除失败：$e';
      notifyListeners();
      debugPrint('❌ 删除日记错误: $e');
    }
  }
}
