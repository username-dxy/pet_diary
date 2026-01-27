import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/pet.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../domain/services/photo_storage_service.dart';
import '../../../domain/services/profile_service.dart';

/// Profile 设置 ViewModel
class ProfileSetupViewModel extends ChangeNotifier {
  final PetRepository _petRepository = PetRepository();
  final PhotoStorageService _photoService = PhotoStorageService();
  // 使用API服务连接Mock Server
  // 如需切换回Mock: ProfileServiceFactory.create(useMock: true)
  final ProfileService _profileService = ProfileService.api();

  // ==================== 表单字段状态 ====================

  /// 宠物照片
  File? _profilePhoto;

  /// 宠物名称
  String _name = '';

  /// 主人称呼
  String _ownerNickname = '主人';

  /// 生日
  DateTime? _birthday;

  /// 性别
  PetGender _gender = PetGender.unknown;

  /// 性格
  PetPersonality? _personality;

  /// 物种（默认猫）
  String _species = 'cat';

  // ==================== UI 状态 ====================

  /// 是否正在提交
  bool _isSubmitting = false;

  /// 错误信息
  String? _errorMessage;

  /// 照片选择错误
  String? _photoError;

  // ==================== Getters ====================

  File? get profilePhoto => _profilePhoto;
  String get name => _name;
  String get ownerNickname => _ownerNickname;
  DateTime? get birthday => _birthday;
  PetGender get gender => _gender;
  PetPersonality? get personality => _personality;
  String get species => _species;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get photoError => _photoError;

  /// 表单是否有效（名称和照片必填）
  bool get isValid => _name.isNotEmpty && _profilePhoto != null;

  /// 进度百分比（用于显示）
  double get progressPercentage {
    int filledFields = 0;
    const int totalFields = 6;

    if (_profilePhoto != null) filledFields++;
    if (_name.isNotEmpty) filledFields++;
    if (_ownerNickname.isNotEmpty) filledFields++;
    if (_birthday != null) filledFields++;
    if (_gender != PetGender.unknown) filledFields++;
    if (_personality != null) filledFields++;

    return filledFields / totalFields;
  }

  // ==================== 表单操作方法 ====================

  /// 选择照片
  Future<void> pickPhoto() async {
    _photoError = null;
    _errorMessage = null;

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _profilePhoto = File(image.path);
        notifyListeners();
        debugPrint('✅ 照片已选择: ${_profilePhoto?.path}');
      } else {
        debugPrint('ℹ️ 用户取消了照片选择');
      }
    } on Exception catch (e) {
      _photoError = '选择照片失败，请确保已授予相册权限';
      notifyListeners();
      debugPrint('❌ 选择照片出错: $e');
    }
  }

  /// 设置名称
  void setName(String value) {
    _name = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  /// 设置主人称呼
  void setOwnerNickname(String value) {
    _ownerNickname = value.trim();
    notifyListeners();
  }

  /// 设置生日
  void setBirthday(DateTime? value) {
    _birthday = value;
    notifyListeners();
  }

  /// 设置性别
  void setGender(PetGender value) {
    _gender = value;
    notifyListeners();
  }

  /// 设置性格
  void setPersonality(PetPersonality value) {
    _personality = value;
    notifyListeners();
  }

  /// 设置物种
  void setSpecies(String value) {
    _species = value;
    notifyListeners();
  }

  // ==================== 提交逻辑 ====================

  /// 提交 Profile
  Future<bool> submitProfile() async {
    if (!isValid) {
      _errorMessage = '请填写必填信息（宠物照片和名称）';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[ProfileSetup] 开始保存 Profile...');

      // 1. 保存照片到本地持久化目录
      final photoPath = await _photoService.savePhoto(_profilePhoto!.path);
      debugPrint('[ProfileSetup] 照片已保存: $photoPath');

      // 2. 创建 Pet 对象
      final uuid = const Uuid();
      final pet = Pet(
        id: uuid.v4(),
        name: _name,
        species: _species,
        profilePhotoPath: photoPath,
        birthday: _birthday,
        ownerNickname: _ownerNickname,
        gender: _gender,
        personality: _personality,
        createdAt: DateTime.now(),
      );

      // 3. 保存到本地
      await _petRepository.savePet(pet);
      debugPrint('[ProfileSetup] Profile 已保存到本地');

      // 4. 异步同步到服务端（不阻塞用户）
      _syncToServer(pet);

      return true;
    } catch (e) {
      _errorMessage = '保存失败: $e';
      debugPrint('❌ [ProfileSetup] 保存失败: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// 异步同步到服务端
  void _syncToServer(Pet pet) {
    _profileService.syncProfile(pet).then((result) {
      debugPrint('✅ [ProfileSetup] 同步成功: ${result.message}');
    }).catchError((e) {
      // 同步失败不影响用户使用
      debugPrint('⚠️ [ProfileSetup] 同步失败（不影响使用）: $e');
    });
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    _photoError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('[ProfileSetupViewModel] Disposed');
    super.dispose();
  }
}
