import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/pet.dart';
import '../../../../data/repositories/pet_repository.dart';
import '../../../../domain/services/photo_storage_service.dart';

/// 编辑档案 ViewModel
class EditProfileViewModel extends ChangeNotifier {
  final Pet initialPet;
  final PetRepository _petRepository;
  final PhotoStorageService _photoStorageService;
  final ImagePicker _imagePicker;

  EditProfileViewModel({
    required this.initialPet,
    PetRepository? petRepository,
    PhotoStorageService? photoStorageService,
    ImagePicker? imagePicker,
  })  : _petRepository = petRepository ?? PetRepository(),
        _photoStorageService = photoStorageService ?? PhotoStorageService(),
        _imagePicker = imagePicker ?? ImagePicker() {
    // 初始化表单值
    _name = initialPet.name;
    _ownerNickname = initialPet.ownerNickname ?? '主人';
    _birthday = initialPet.birthday;
    _gender = initialPet.gender ?? PetGender.unknown;
    _personality = initialPet.personality;

    // 如果有现有照片，加载它
    if (initialPet.profilePhotoPath != null) {
      _profilePhoto = File(initialPet.profilePhotoPath!);
    }
  }

  // 表单状态
  File? _profilePhoto;
  String _name = '';
  String _ownerNickname = '主人';
  DateTime? _birthday;
  PetGender _gender = PetGender.unknown;
  PetPersonality? _personality;

  // UI 状态
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _photoError;

  // Getters
  File? get profilePhoto => _profilePhoto;
  String get name => _name;
  String get ownerNickname => _ownerNickname;
  DateTime? get birthday => _birthday;
  PetGender get gender => _gender;
  PetPersonality? get personality => _personality;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get photoError => _photoError;

  bool get isValid => _name.isNotEmpty && _profilePhoto != null;

  // Setters
  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setOwnerNickname(String value) {
    _ownerNickname = value;
    notifyListeners();
  }

  void setBirthday(DateTime value) {
    _birthday = value;
    notifyListeners();
  }

  void setGender(PetGender value) {
    _gender = value;
    notifyListeners();
  }

  void setPersonality(PetPersonality value) {
    _personality = value;
    notifyListeners();
  }

  /// 选择照片
  Future<void> pickPhoto() async {
    try {
      _photoError = null;
      notifyListeners();

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _profilePhoto = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      _photoError = '照片选择失败，请检查相册权限';
      notifyListeners();
      debugPrint('照片选择失败: $e');
    }
  }

  /// 保存档案
  Future<Pet?> saveProfile() async {
    if (!isValid) {
      _errorMessage = '请填写必填项';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 保存照片（如果是新照片）
      String? savedPhotoPath = initialPet.profilePhotoPath;

      if (_profilePhoto != null) {
        // 检查是否是新照片（路径不同）
        if (_profilePhoto!.path != initialPet.profilePhotoPath) {
          savedPhotoPath = await _photoStorageService.saveProfilePhoto(
            _profilePhoto!,
            initialPet.id,
          );
        }
      }

      // 创建更新后的宠物对象
      final updatedPet = Pet(
        id: initialPet.id,
        name: _name,
        species: initialPet.species,
        breed: initialPet.breed,
        profilePhotoPath: savedPhotoPath,
        birthday: _birthday,
        ownerNickname: _ownerNickname,
        gender: _gender,
        personality: _personality,
        createdAt: initialPet.createdAt,
      );

      // 保存到仓库
      await _petRepository.savePet(updatedPet);

      _isSubmitting = false;
      notifyListeners();

      return updatedPet;
    } catch (e) {
      _errorMessage = '保存失败: $e';
      _isSubmitting = false;
      notifyListeners();
      debugPrint('保存失败: $e');
      return null;
    }
  }
}
