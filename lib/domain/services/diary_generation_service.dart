import 'package:flutter/foundation.dart';
import 'package:pet_diary/data/models/pet.dart';

/// 日记生成服务
class DiaryGenerationService {
  /// 基于App相册生成日记（真实API接口）
  /// 
  /// 后端逻辑：
  /// 1. 从photoIds中随机选择一张照片
  /// 2. 读取照片的EXIF信息（日期、地点）
  /// 3. 调用AI模型生成日记
  /// 
  /// @param photoIds - App相册中的照片ID列表
  /// @param pet - 宠物信息
  /// @return 生成的日记内容（100-200字）
  Future<DiaryGenerationResult> generateFromAlbum({
    required List<String> photoIds,
    required Pet pet,
  }) async {
    // TODO: 调用真实后端API
    // POST /api/v1/diary/generate
    // Body: { "photo_ids": [...], "pet_id": "..." }
    // Response: { "content": "...", "selected_photo_id": "...", "photo_date": "...", "location": "..." }

    debugPrint('🔄 调用后端生成日记API');
    debugPrint('照片数量: ${photoIds.length}');
    debugPrint('宠物: ${pet.name}');

    // Mock延迟
    await Future.delayed(const Duration(seconds: 2));

    // Mock返回
    return DiaryGenerationResult(
      content: _mockGenerate(pet),
      selectedPhotoId: photoIds.isNotEmpty ? photoIds[0] : null,
      photoDate: DateTime.now(),
      location: '示例地点',
    );
  }

  /// Mock生成（临时使用）
  String _mockGenerate(Pet pet) {
    final templates = [
      '''2026年1月21日  天气：☀️晴

今天主人带我出去玩啦！看到了好多新鲜的东西，我的尾巴都快摇断了！主人还给我买了好吃的小零食，简直太幸福了~我们去了公园，那里有好多小朋友，他们都想摸摸我，虽然有点害羞，但是被这么多人喜欢的感觉真好！回家的路上，我趴在主人怀里，听着主人的心跳声，慢慢睡着了。这真是美好的一天呀，希望每天都能这么开心！喵呜~''',
      
      '''2026年1月21日  天气：⛅️多云

今天是安静的一天。我趴在窗台上晒太阳，看着外面的世界慢慢流动。偶尔有几只小鸟飞过，我也只是懒懒地看着，并不想去追。阳光照在身上暖暖的，整个世界都变得柔软起来。主人在客厅看书，我就安静地陪在旁边，听着主人翻书的声音。有时候，什么都不做，就这样安静地待着，也是一种幸福呢。下午的时候，我在最喜欢的小垫子上睡了个长长的午觉，梦里梦到自己在云朵上飘啊飘。醒来的时候，发现主人给我盖上了小毯子，心里暖暖的。喵呜~''',
      
      '''2026年1月21日  天气：🌧️小雨

今天下雨了，不能出门玩。我趴在窗边看着外面的雨滴，一滴一滴地落下来，形成小水洼。雨声滴滴答答的，听起来好舒服。主人在家陪我，给我讲了好多故事。中午的时候，主人给我准备了热乎乎的食物，吃完后我就窝在主人怀里打盹。虽然不能出去玩，但和主人待在温暖的家里，听着外面的雨声，感觉也很幸福呢。希望明天是个好天气，可以出去撒欢儿~喵呜~''',
    ];

    final index = DateTime.now().millisecond % templates.length;
    return templates[index];
  }

  /// 构建真实API的请求参数（示例）
  Map<String, dynamic> buildApiRequest({
    required List<String> photoIds,
    required Pet pet,
  }) {
    return {
      'photo_ids': photoIds,
      'pet_id': pet.id,
      'pet_name': pet.name,
      'pet_species': pet.species,
      'pet_breed': pet.breed,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// 日记生成结果
class DiaryGenerationResult {
  final String content;           // 生成的日记内容
  final String? selectedPhotoId;  // 后端选择的照片ID
  final DateTime? photoDate;      // 照片拍摄日期
  final String? location;         // 照片拍摄地点

  DiaryGenerationResult({
    required this.content,
    this.selectedPhotoId,
    this.photoDate,
    this.location,
  });

  factory DiaryGenerationResult.fromJson(Map<String, dynamic> json) {
    return DiaryGenerationResult(
      content: json['content'] as String,
      selectedPhotoId: json['selected_photo_id'] as String?,
      photoDate: json['photo_date'] != null
          ? DateTime.parse(json['photo_date'] as String)
          : null,
      location: json['location'] as String?,
    );
  }
}
