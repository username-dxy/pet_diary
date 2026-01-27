import 'package:pet_diary/data/models/pet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 宠物信息仓库
class PetRepository {
  static const String _key = 'current_pet';

  /// 获取当前宠物
  Future<Pet?> getCurrentPet() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) {
      // 没有宠物信息时返回 null，需要用户设置
      return null;
    }

    return Pet.fromJson(json.decode(jsonString) as Map<String, dynamic>);
  }

  /// 检查 Profile 是否完整
  /// 必填字段：name, profilePhotoPath
  /// 可选但建议填写：ownerNickname, gender, personality, birthday
  Future<bool> isProfileComplete() async {
    final pet = await getCurrentPet();

    if (pet == null) {
      return false;
    }

    // 检查必填字段
    if (pet.name.isEmpty || pet.profilePhotoPath == null) {
      return false;
    }

    return true;
  }

  /// 更新宠物 Profile
  Future<void> updatePetProfile(Pet pet) async {
    await savePet(pet);
  }

  /// 保存宠物
  Future<void> savePet(Pet pet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(pet.toJson()));
  }

}