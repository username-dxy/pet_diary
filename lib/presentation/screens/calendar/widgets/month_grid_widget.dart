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
    // 计算这个月的总格子数（包括前面的空白）
    final totalCells = _getFirstDayOffset() + _getDaysInMonth();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // 一周7天
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        // 计算这个格子对应的日期
        final dayNumber = index - _getFirstDayOffset() + 1;

        // 如果是空白格子（1号之前）
        if (dayNumber < 1) {
          return _buildEmptyCell();
        }

        // 如果超出了这个月的天数
        if (dayNumber > _getDaysInMonth()) {
          return _buildEmptyCell();
        }

        // 正常的日期格子
        final date = DateTime(year, month, dayNumber);
        final record = records[date];

        return _buildDayCell(date, dayNumber, record);
      },
    );
  }

  /// 空白格子
  Widget _buildEmptyCell() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// 日期格子
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

  /// 获取这个月1号是星期几的偏移量
  /// 返回值：0-6（周日=0, 周一=1, ..., 周六=6）
  int _getFirstDayOffset() {
    final firstDay = DateTime(year, month, 1);
    // weekday: 周一=1, 周二=2, ..., 周日=7
    // 我们需要：周日=0, 周一=1, ..., 周六=6
    return firstDay.weekday % 7;
  }

  /// 获取当月天数
  int _getDaysInMonth() {
    // 下个月的第0天 = 这个月的最后一天
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