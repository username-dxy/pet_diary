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
      // 返回一个默认宠物（Demo用）
      return _createDefaultPet();
    }

    return Pet.fromJson(json.decode(jsonString) as Map<String, dynamic>);
  }

  /// 保存宠物
  Future<void> savePet(Pet pet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(pet.toJson()));
  }

  /// 创建默认宠物（Demo用）
  Pet _createDefaultPet() {
    return Pet(
      id: 'default_pet',
      name: '我的宠物',
      species: 'cat',
      breed: '橘猫',
      createdAt: DateTime.now(),
    );
  }
}