import 'dart:io';
import 'package:pet_diary/data/models/pet_features.dart';

/// 特征提取服务（模型B）
class FeatureExtractionService {
  
  /// 提取宠物特征
  /// TODO: 后期接入真实API
  Future<PetFeatures> extractFeatures(File image) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    // Mock数据
    return const PetFeatures(
      species: 'cat',
      breed: '橘猫',
      color: '橙色',
      pose: 'sitting',
    );
  }
}