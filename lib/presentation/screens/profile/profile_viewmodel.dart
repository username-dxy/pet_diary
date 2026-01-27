import 'package:flutter/material.dart';
import '../../../data/models/pet.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../domain/services/profile_service.dart';

/// Profile 页面 ViewModel
class ProfileViewModel extends ChangeNotifier {
  final PetRepository _petRepository;
  final ProfileService _profileService;

  ProfileViewModel({
    PetRepository? petRepository,
    ProfileService? profileService,
  })  : _petRepository = petRepository ?? PetRepository(),
        // 使用API服务连接Mock Server
        // 如需切换回Mock: ProfileService.mock()
        _profileService = profileService ?? ProfileService.api() {
    _loadProfile();
  }

  // 状态
  Pet? _pet;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  // Getters
  Pet? get pet => _pet;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// 加载档案
  Future<void> _loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pet = await _petRepository.getCurrentPet();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新档案
  Future<void> refresh() async {
    await _loadProfile();
  }

  /// 更新档案
  Future<bool> updateProfile(Pet updatedPet) async {
    _errorMessage = null;
    notifyListeners();

    try {
      // 保存到本地
      await _petRepository.savePet(updatedPet);
      _pet = updatedPet;
      notifyListeners();

      // 后台异步同步
      _syncToServer(updatedPet);

      return true;
    } catch (e) {
      _errorMessage = '更新失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 同步到服务器
  Future<void> _syncToServer(Pet pet) async {
    _isSyncing = true;
    notifyListeners();

    try {
      final result = await _profileService.syncProfile(pet);
      if (result.success) {
        _lastSyncTime = DateTime.now();
        debugPrint('档案同步成功');
      } else {
        debugPrint('档案同步失败: ${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('档案同步异常: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 手动触发同步
  Future<void> manualSync() async {
    if (_pet == null || _isSyncing) return;
    await _syncToServer(_pet!);
  }

  /// 获取年龄文本
  String getAgeText() {
    if (_pet?.birthday == null) return '未知';

    final now = DateTime.now();
    final birthday = _pet!.birthday!;
    final years = now.year - birthday.year;
    final months = now.month - birthday.month;

    if (years == 0) {
      if (months == 0) {
        final days = now.day - birthday.day;
        return '$days天';
      }
      return '$months个月';
    }

    if (months < 0) {
      return '${years - 1}岁${12 + months}个月';
    }

    if (months == 0) {
      return '$years岁';
    }

    return '$years岁$months个月';
  }

  /// 获取同步状态文本
  String getSyncStatusText() {
    if (_isSyncing) return '同步中...';
    if (_lastSyncTime == null) return '未同步';

    final now = DateTime.now();
    final diff = now.difference(_lastSyncTime!);

    if (diff.inMinutes < 1) return '刚刚同步';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前同步';
    if (diff.inDays < 1) return '${diff.inHours}小时前同步';
    return '${diff.inDays}天前同步';
  }
}
