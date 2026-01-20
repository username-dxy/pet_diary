import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pet_diary/data/models/emotion_record.dart';
import 'package:pet_diary/domain/services/asset_manager.dart';

/// 月度日历网格
class MonthGridWidget extends StatelessWidget {
  final int year;
  final int month;
  final Map<DateTime, EmotionRecord> records;
  final Function(DateTime)? onDayTap;

  const MonthGridWidget({
    super.key,
    required this.year,
    required this.month,
    required this.records,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // 一周7天
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _getDaysInMonth(),
      itemBuilder: (context, index) {
        final day = index + 1;
        final date = DateTime(year, month, day);
        final record = records[date];

        return _buildDayCell(date, day, record);
      },
    );
  }

  Widget _buildDayCell(DateTime date, int day, EmotionRecord? record) {
    final isToday = _isToday(date);

    return GestureDetector(
      onTap: () => onDayTap?.call(date),
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: Colors.blue, width: 2)
              : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Stack(
          children: [
            // 日期数字
            Positioned(
              top: 4,
              left: 6,
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  color: isToday ? Colors.blue : Colors.grey,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),

            // 显示照片或emoji
            if (record != null)
              Center(
                child: _buildRecordPreview(record),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建记录预览（照片或emoji）
  Widget _buildRecordPreview(EmotionRecord record) {
    // 如果有照片路径，显示照片
    if (record.originalPhotoPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(record.originalPhotoPath!),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // 照片加载失败，显示emoji
            return AssetManager.instance.getEmotionSticker(
              record.selectedEmotion,
              size: 32,
            );
          },
        ),
      );
    }

    // 没有照片，显示emoji
    return AssetManager.instance.getEmotionSticker(
      record.selectedEmotion,
      size: 32,
    );
  }

  /// 获取当月天数
  int _getDaysInMonth() {
    return DateTime(year, month + 1, 0).day;
  }

  /// 判断是否是今天
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}