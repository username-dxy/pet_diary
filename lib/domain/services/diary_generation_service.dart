import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pet_diary/data/models/pet.dart';
import 'package:pet_diary/data/models/app_photo.dart';
import 'package:pet_diary/core/network/api_client.dart';
import 'package:pet_diary/core/network/api_response.dart';
import 'package:pet_diary/domain/services/quota_service.dart';

/// 配额不足错误码
const int quotaExhaustedErrorCode = 403;

/// 日记生成服务
class DiaryGenerationService {
  final ApiClient _client;
  final QuotaService _quotaService;

  DiaryGenerationService({
    ApiClient? client,
    QuotaService? quotaService,
  })  : _client = client ?? ApiClient(),
        _quotaService = quotaService ?? QuotaService();

  /// 通过 AI 服务生成日记（推荐）
  /// [photos] - 某一天的所有宠物照片
  /// [pet] - 当前宠物信息
  /// [date] - 日期
  /// [otherPets] - 同主人的其他宠物（用于区分照片中的不同宠物）
  Future<ApiResponse<DiaryGenerationResult>> generateFromAI({
    required List<AppPhoto> photos,
    required Pet pet,
    required DateTime date,
    List<Pet>? otherPets,
  }) async {
    debugPrint('📖 ========== AI 日记生成开始 ==========');
    debugPrint('🐱 宠物: ${pet.name} (${pet.id})');
    debugPrint('📅 日期: ${date.toIso8601String().split('T')[0]}');
    debugPrint('📷 照片数量: ${photos.length}');
    debugPrint('👥 其他宠物: ${otherPets?.map((p) => p.name).join(', ') ?? '无'}');

    // 检查配额
    if (!await _quotaService.canGenerateAI()) {
      debugPrint('❌ AI 配额已用完');
      return ApiResponse.failure('AI 配额已用完，请升级会员解锁无限生成', quotaExhaustedErrorCode);
    }

    if (photos.isEmpty) {
      debugPrint('❌ 没有照片，无法生成日记');
      return ApiResponse.failure('没有照片可用于生成日记', 400);
    }

    // 构建宠物信息 JSON
    final petJson = jsonEncode({
      'id': pet.id,
      'name': pet.name,
      'species': pet.species,
      'breed': pet.breed,
      'gender': pet.gender,
      'personality': pet.personality,
      'ownerNickname': pet.ownerNickname,
    });

    // 构建其他宠物列表 JSON
    final otherPetsJson = otherPets != null && otherPets.isNotEmpty
        ? jsonEncode(otherPets
            .map((p) => {
                  'id': p.id,
                  'name': p.name,
                  'species': p.species,
                })
            .toList())
        : null;

    final dateStr = date.toIso8601String().split('T')[0];

    // 收集照片路径
    final imagePaths = photos
        .where((p) => p.localPath.isNotEmpty && File(p.localPath).existsSync())
        .map((p) => p.localPath)
        .toList();

    if (imagePaths.isEmpty) {
      debugPrint('❌ 没有有效的本地照片路径');
      return ApiResponse.failure('没有有效的照片文件', 400);
    }

    debugPrint('📤 上传 ${imagePaths.length} 张照片到 AI 服务');

    try {
      final response = await _client.uploadFiles<DiaryGenerationResult>(
        '/api/chongyu/ai/diary/generate',
        files: {'images': imagePaths},
        fields: {
          'pet': petJson,
          'date': dateStr,
          if (otherPetsJson != null) 'otherPets': otherPetsJson,
        },
        fromJson: (json) {
          if (json is Map<String, dynamic>) {
            return DiaryGenerationResult.fromServerJson(json);
          }
          throw Exception('Invalid AI response format');
        },
      );

      if (response.success && response.data != null) {
        debugPrint('✅ AI 日记生成成功');
        debugPrint('📝 内容长度: ${response.data!.content.length} 字符');

        // 记录配额使用
        await _quotaService.recordAIUsage();
      } else {
        debugPrint('❌ AI 日记生成失败: ${response.errorMessage}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ AI 日记生成异常: $e');
      return ApiResponse.failure(e.toString(), 500);
    }
  }

  /// 基于App相册生成日记（本地模板降级方案）
  Future<DiaryGenerationResult> generateFromAlbum({
    required List<AppPhoto> photos,
    required Pet pet,
  }) async {
    debugPrint('🔄 ========== 开始生成日记（本地模板）==========');
    debugPrint('📊 相册照片数量: ${photos.length}');
    debugPrint('🐱 宠物名称: ${pet.name}');

    if (photos.isEmpty) {
      debugPrint('❌ 相册为空，无法生成日记');
      throw Exception('相册中没有照片');
    }

    // Mock延迟（模拟API调用）
    await Future.delayed(const Duration(seconds: 1));

    // 随机选择一张照片
    final selectedPhoto = photos[DateTime.now().millisecond % photos.length];
    debugPrint('📸 随机选择照片: ${selectedPhoto.id}');
    debugPrint('📅 照片拍摄日期: ${selectedPhoto.photoTakenAt}');
    debugPrint('📍 照片地点: ${selectedPhoto.location ?? "未知"}');
    debugPrint('💾 照片路径: ${selectedPhoto.localPath}');

    // 使用照片的实际日期
    final photoDate = selectedPhoto.photoTakenAt ?? selectedPhoto.addedAt;
    debugPrint(
        '✅ 使用日期: $photoDate (${selectedPhoto.photoTakenAt != null ? "拍摄日期" : "添加日期"})');

    // 生成日记内容
    final content = _generateContent(pet.name, pet.species, photoDate);
    debugPrint('📝 日记内容长度: ${content.length} 字符');

    final result = DiaryGenerationResult(
      content: content,
      selectedPhotoId: selectedPhoto.id,
      selectedPhotoPath: selectedPhoto.localPath,
      photoDate: photoDate,
      location: selectedPhoto.location,
      isAiGenerated: false,
    );

    debugPrint('✅ ========== 日记生成完成 ==========');
    return result;
  }

  /// 智能生成日记（优先 AI，降级本地模板）
  ///
  /// 注意：配额不足时不会降级，而是返回 null 并设置错误信息
  Future<SmartGenerationResult> generateSmart({
    required List<AppPhoto> photos,
    required Pet pet,
    required DateTime date,
    List<Pet>? otherPets,
  }) async {
    // 尝试 AI 生成
    final aiResponse = await generateFromAI(
      photos: photos,
      pet: pet,
      date: date,
      otherPets: otherPets,
    );

    if (aiResponse.success && aiResponse.data != null) {
      return SmartGenerationResult(
        diary: aiResponse.data!,
        isQuotaExhausted: false,
      );
    }

    // 配额不足时不降级，返回错误信息让 UI 处理
    if (aiResponse.error?.code == quotaExhaustedErrorCode) {
      debugPrint('⚠️ AI 配额不足，不降级到本地模板');
      return SmartGenerationResult(
        diary: null,
        isQuotaExhausted: true,
        errorMessage: aiResponse.errorMessage,
      );
    }

    // 其他错误降级到本地模板
    debugPrint('⚠️ AI 生成失败，降级到本地模板');
    final fallbackDiary = await generateFromAlbum(photos: photos, pet: pet);
    return SmartGenerationResult(
      diary: fallbackDiary,
      isQuotaExhausted: false,
    );
  }

  /// 生成日记内容（本地模板）
  String _generateContent(String petName, String species, DateTime date) {
    final isCat = species.toLowerCase() == 'cat';
    final sound = isCat ? '喵呜~' : '汪汪~';

    final templates = [
      '''今天主人带我出去玩啦！

看到了好多新鲜的东西，我的尾巴都快摇断了！

公园里有好多小朋友，他们都想摸摸我，虽然有点害羞，但是被这么多人喜欢的感觉真好！

主人还给我买了好吃的小零食，简直太幸福了~

回家的路上，我趴在主人怀里，听着主人的心跳声，慢慢睡着了。

这真是美好的一天呀，希望每天都能这么开心！

$sound''',
      '''今天是安静的一天。

我趴在窗台上晒太阳，看着外面的世界慢慢流动。

偶尔有几只小鸟飞过，我也只是懒懒地看着，并不想去追。

阳光照在身上暖暖的，整个世界都变得柔软起来。

主人在客厅看书，我就安静地陪在旁边，听着主人翻书的声音。

有时候，什么都不做，就这样安静地待着，也是一种幸福呢。

下午的时候，我睡了个长长的午觉，梦里梦到自己在云朵上飘啊飘。

醒来的时候，发现主人给我盖上了小毯子，心里暖暖的。

$sound''',
      '''今天下雨了，不能出门玩。

我趴在窗边看着外面的雨滴，一滴一滴地落下来，形成小水洼。

雨声滴滴答答的，听起来好舒服。

主人在家陪我，给我讲了好多故事。

中午的时候，主人给我准备了热乎乎的食物，吃完后我就窝在主人怀里打盹。

虽然不能出去玩，但和主人待在温暖的家里，听着外面的雨声，感觉也很幸福呢。

希望明天是个好天气，可以出去撒欢儿~

$sound''',
    ];

    final index = date.day % templates.length;
    return templates[index];
  }

  /// 构建真实API的请求参数（预留）
  Map<String, dynamic> buildApiRequest({
    required List<AppPhoto> photos,
    required Pet pet,
  }) {
    return {
      'photo_ids': photos.map((p) => p.id).toList(),
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
  final String content;
  final String? selectedPhotoId;
  final String? selectedPhotoPath;
  final DateTime? photoDate;
  final String? location;
  final bool isAiGenerated;
  final List<MentionedAnimal>? mentionedAnimals;

  DiaryGenerationResult({
    required this.content,
    this.selectedPhotoId,
    this.selectedPhotoPath,
    this.photoDate,
    this.location,
    this.isAiGenerated = false,
    this.mentionedAnimals,
  });

  factory DiaryGenerationResult.fromJson(Map<String, dynamic> json) {
    return DiaryGenerationResult(
      content: json['content'] as String,
      selectedPhotoId: json['selected_photo_id'] as String?,
      selectedPhotoPath: json['selected_photo_path'] as String?,
      photoDate: json['photo_date'] != null
          ? DateTime.parse(json['photo_date'] as String)
          : null,
      location: json['location'] as String?,
      isAiGenerated: json['is_ai_generated'] as bool? ?? false,
    );
  }

  /// 从服务端 AI 响应解析
  factory DiaryGenerationResult.fromServerJson(Map<String, dynamic> json) {
    List<MentionedAnimal>? animals;
    final animalsJson = json['mentionedAnimals'] as List?;
    if (animalsJson != null) {
      animals = animalsJson
          .map((a) => MentionedAnimal.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return DiaryGenerationResult(
      content: json['content'] as String? ?? '',
      isAiGenerated: true,
      mentionedAnimals: animals,
    );
  }
}

/// 照片中提及的动物
class MentionedAnimal {
  final String species;
  final String description;
  final bool isMain;

  MentionedAnimal({
    required this.species,
    required this.description,
    this.isMain = false,
  });

  factory MentionedAnimal.fromJson(Map<String, dynamic> json) {
    return MentionedAnimal(
      species: json['species'] as String? ?? 'other',
      description: json['description'] as String? ?? '',
      isMain: json['is_main'] as bool? ?? false,
    );
  }
}

/// 智能生成结果
///
/// 包含生成的日记（可能为 null）和配额状态
class SmartGenerationResult {
  /// 生成的日记（配额不足时为 null）
  final DiaryGenerationResult? diary;

  /// 是否因配额不足而无法生成
  final bool isQuotaExhausted;

  /// 错误信息（配额不足时有值）
  final String? errorMessage;

  const SmartGenerationResult({
    this.diary,
    this.isQuotaExhausted = false,
    this.errorMessage,
  });

  /// 是否成功生成
  bool get isSuccess => diary != null;
}
