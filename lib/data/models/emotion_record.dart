import 'package:equatable/equatable.dart';
import 'package:pet_diary/domain/services/asset_manager.dart';
import 'package:pet_diary/data/models/pet_features.dart';

/// 情绪记录
class EmotionRecord extends Equatable {
  final String id;
  final String petId;
  final DateTime date;
  
  // AI分析结果
  final String? originalPhotoPath;
  final Emotion aiEmotion;
  final double aiConfidence;
  final PetFeatures aiFeatures;
  
  // 用户选择
  final Emotion selectedEmotion;
  final String? stickerUrl;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmotionRecord({
    required this.id,
    required this.petId,
    required this.date,
    this.originalPhotoPath,
    required this.aiEmotion,
    required this.aiConfidence,
    required this.aiFeatures,
    required this.selectedEmotion,
    this.stickerUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmotionRecord.fromJson(Map<String, dynamic> json) {
    return EmotionRecord(
      id: json['id'] as String,
      petId: json['petId'] as String,
      date: DateTime.parse(json['date'] as String),
      originalPhotoPath: json['originalPhotoPath'] as String?,
      aiEmotion: _emotionFromApi(json['aiEmotion']),
      aiConfidence: (json['aiConfidence'] as num).toDouble(),
      aiFeatures: PetFeatures.fromJson(json['aiFeatures'] as Map<String, dynamic>),
      selectedEmotion: _emotionFromApi(json['selectedEmotion']),
      stickerUrl: json['stickerUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'date': date.toIso8601String(),
      'originalPhotoPath': originalPhotoPath,
      'aiEmotion': _emotionToApi(aiEmotion),
      'aiConfidence': aiConfidence,
      'aiFeatures': aiFeatures.toJson(),
      'selectedEmotion': _emotionToApi(selectedEmotion),
      'stickerUrl': stickerUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  EmotionRecord copyWith({
    Emotion? selectedEmotion,
    String? stickerUrl,
  }) {
    return EmotionRecord(
      id: id,
      petId: petId,
      date: date,
      originalPhotoPath: originalPhotoPath,
      aiEmotion: aiEmotion,
      aiConfidence: aiConfidence,
      aiFeatures: aiFeatures,
      selectedEmotion: selectedEmotion ?? this.selectedEmotion,
      stickerUrl: stickerUrl ?? this.stickerUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, selectedEmotion, updatedAt];

  static Emotion _emotionFromApi(dynamic value) {
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

    final name = (value ?? '').toString();
    try {
      return Emotion.values.byName(name);
    } catch (_) {
      return Emotion.calm;
    }
  }

  static int _emotionToApi(Emotion emotion) {
    switch (emotion) {
      case Emotion.happy:
        return 1;
      case Emotion.calm:
        return 2;
      case Emotion.sad:
        return 3;
      case Emotion.angry:
        return 4;
      case Emotion.sleepy:
        return 5;
      case Emotion.curious:
        return 6;
    }
  }
}
