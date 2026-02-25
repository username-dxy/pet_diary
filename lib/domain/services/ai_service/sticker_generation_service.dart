import 'dart:io';
import 'package:pet_diary/data/models/pet_features.dart';
import 'package:pet_diary/domain/services/asset_manager.dart';
import 'package:pet_diary/core/network/api_client.dart';
import 'package:pet_diary/core/network/api_response.dart';

/// 贴纸生成服务（模型C）
class StickerGenerationService {
  final ApiClient _client;

  StickerGenerationService({ApiClient? client})
      : _client = client ?? ApiClient();
  
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

  /// 通过服务端 AI 管线生成贴纸（情绪+特征+贴纸）
  Future<ApiResponse<AiStickerResult>> generateStickerFromServer({
    required File photo,
  }) {
    return _client.uploadFiles<AiStickerResult>(
      '/api/chongyu/ai/sticker/generate',
      files: {'image': [photo.path]},
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return AiStickerResult.fromJson(json);
        }
        throw Exception('Invalid AI response');
      },
    );
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

class AiStickerResult {
  final Emotion emotion;
  final double confidence;
  final PetFeatures features;
  final String stickerUrl;
  final String? prompt;

  const AiStickerResult({
    required this.emotion,
    required this.confidence,
    required this.features,
    required this.stickerUrl,
    this.prompt,
  });

  factory AiStickerResult.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] as Map<String, dynamic>? ?? const {};
    final petFeatures = json['pet_features'] as Map<String, dynamic>? ?? const {};
    final sticker = json['sticker'] as Map<String, dynamic>? ?? const {};

    return AiStickerResult(
      emotion: _parseEmotion(analysis['emotion']),
      confidence: (analysis['confidence'] as num?)?.toDouble() ?? 0.0,
      features: PetFeatures(
        species: (petFeatures['species'] as String?) ?? 'other',
        breed: (petFeatures['breed'] as String?) ?? '宠物',
        color: (petFeatures['primary_color'] as String?) ??
            (petFeatures['color'] as String?) ??
            '未知',
        pose: (petFeatures['pose'] as String?) ?? 'unknown',
      ),
      stickerUrl: (sticker['imageUrl'] as String?) ?? '',
      prompt: sticker['prompt'] as String?,
    );
  }

  static Emotion _parseEmotion(dynamic value) {
    if (value is num) {
      switch (value.toInt()) {
        case 1:
          return Emotion.happy;
        case 2:
          return Emotion.calm;
        case 3:
          return Emotion.sad;
        case 4:
          return Emotion.angry;
        case 5:
          return Emotion.sleepy;
        case 6:
          return Emotion.curious;
        default:
          return Emotion.calm;
      }
    }

    switch ((value ?? '').toString().toLowerCase()) {
      case 'happy':
        return Emotion.happy;
      case 'calm':
        return Emotion.calm;
      case 'sad':
        return Emotion.sad;
      case 'angry':
        return Emotion.angry;
      case 'sleepy':
        return Emotion.sleepy;
      case 'curious':
        return Emotion.curious;
      default:
        return Emotion.calm;
    }
  }
}
