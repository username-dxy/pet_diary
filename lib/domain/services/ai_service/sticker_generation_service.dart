import 'dart:io';
import 'package:pet_diary/data/models/pet_features.dart';
import 'package:pet_diary/domain/services/asset_manager.dart';

/// 贴纸生成服务（模型C）
class StickerGenerationService {
  
  /// 生成贴纸
  /// TODO: 后期接入真实API
  Future<String> generateSticker({
    required File photo,
    required Emotion emotion,
    required PetFeatures features,
  }) async {
    await Future.delayed(const Duration(seconds: 3));

    // Mock: 返回原图路径（后期替换为AI生成的贴纸URL）
    return photo.path;
  }

  /// 构建Prompt（预留接口）
  String buildPrompt(Emotion emotion, PetFeatures features) {
    final emotionDetail = _getEmotionDetail(emotion);

    return '''
A cute cartoon sticker of a ${features.breed} ${features.species},
showing ${emotion.name} emotion through $emotionDetail,
with ${features.color} fur, in a ${features.pose} posture.
Style: kawaii, simple lines, bright colors, white background.
Focus on the head and upper body.
''';
  }

  String _getEmotionDetail(Emotion emotion) {
    switch (emotion) {
      case Emotion.happy:
        return 'smiling with curved eyes, mouth slightly open, cheerful and lively';
      case Emotion.calm:
        return 'gentle half-closed eyes, calm facial expression, serene and peaceful';
      case Emotion.sad:
        return 'droopy eyes, downturned mouth, sad and vulnerable look';
      case Emotion.angry:
        return 'furrowed eyebrows, bared teeth, intense and alert';
      case Emotion.sleepy:
        return 'sleepy eyes, yawning pose, relaxed and cozy';
      case Emotion.curious:
        return 'wide open eyes, head tilted, ears perked up, attentive';
    }
  }
}