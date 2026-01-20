import 'dart:io';
import 'dart:math';
import 'package:pet_diary/domain/services/asset_manager.dart';

/// 情绪识别服务（模型A）
class EmotionRecognitionService {
  
  /// 识别情绪
  /// TODO: 后期接入真实API
  Future<EmotionResult> recognizeEmotion(File image) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 2));

    // 随机返回情绪（Demo用）
    final random = Random();
    final emotion = Emotion.values[random.nextInt(Emotion.values.length)];
    final confidence = 0.7 + random.nextDouble() * 0.25; // 0.7-0.95

    return EmotionResult(emotion: emotion, confidence: confidence);
  }
}

class EmotionResult {
  final Emotion emotion;
  final double confidence;

  EmotionResult({required this.emotion, required this.confidence});
}