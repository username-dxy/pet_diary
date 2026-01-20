import 'package:flutter/material.dart';

/// 资源管理器：统一管理所有视觉资源
/// 这是实现"留好设计图替换口子"的核心
class AssetManager {
  AssetManager._();
  static final AssetManager instance = AssetManager._();

  // ==================== Colors ====================
  
  Color get primaryColor => const Color(0xFF6B9BD1);
  Color get backgroundColor => const Color(0xFFF5F5F5);
  Color get accentColor => const Color(0xFFFFD93D);

  // ==================== Room Scene Paths ====================
  // 注意：这些路径指向还不存在的图片，需要后期替换
  
  String get roomBackground => 'assets/images/room/room_background.png';
  String get drawerClosed => 'assets/images/room/drawer_closed.png';
  String get drawerOpen => 'assets/images/room/drawer_open.png';
  String get calendarWall => 'assets/images/room/calendar_wall.png';
  String get photoFrame => 'assets/images/room/photo_frame.png';

  // ==================== Emotion Helpers ====================
  
  /// 获取情绪对应的emoji
  String getEmotionEmoji(Emotion emotion) {
    switch (emotion) {
      case Emotion.happy:
        return '😊';
      case Emotion.calm:
        return '😌';
      case Emotion.sad:
        return '😢';
      case Emotion.angry:
        return '😠';
      case Emotion.sleepy:
        return '😴';
      case Emotion.curious:
        return '🤔';
    }
  }

  /// 获取情绪显示名称
  String getEmotionName(Emotion emotion) {
    switch (emotion) {
      case Emotion.happy:
        return '开心';
      case Emotion.calm:
        return '平静';
      case Emotion.sad:
        return '难过';
      case Emotion.angry:
        return '生气';
      case Emotion.sleepy:
        return '困倦';
      case Emotion.curious:
        return '好奇';
    }
  }

  /// 获取情绪贴纸Widget
  Widget getEmotionSticker(Emotion emotion, {double size = 60}) {
    return Text(
      getEmotionEmoji(emotion),
      style: TextStyle(fontSize: size),
    );
  }
}

/// 情绪枚举
enum Emotion {
  happy,
  calm,
  sad,
  angry,
  sleepy,
  curious,
}