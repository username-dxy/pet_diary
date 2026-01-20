import 'package:flutter/material.dart';
import 'package:pet_diary/data/models/emotion_record.dart';
import 'package:pet_diary/domain/services/asset_manager.dart';

/// 墙上的日历
class CalendarWallWidget extends StatelessWidget {
  final EmotionRecord? todaySticker;

  const CalendarWallWidget({
    super.key,
    this.todaySticker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: todaySticker != null
            ? AssetManager.instance.getEmotionSticker(
                todaySticker!.selectedEmotion,
                size: 60,
              )
            : const Text(
                '?',
                style: TextStyle(fontSize: 60, color: Colors.grey),
              ),
      ),
    );
  }
}