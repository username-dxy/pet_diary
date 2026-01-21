import 'package:flutter/material.dart';
import 'package:pet_diary/data/models/diary_entry.dart';

/// 单页日记展示
class DiaryPageWidget extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryPageWidget({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DC), // 米黄色纸张
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期标题
          Text(
            _formatDate(entry.date),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513), // 棕色
            ),
          ),

          const SizedBox(height: 24),

          // 日记内容
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                entry.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: Color(0xFF333333),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          // 底部装饰线
          const Divider(color: Color(0xFFD2B48C)),

          const SizedBox(height: 8),

          // 页码
          Center(
            child: Text(
              '${entry.date.day}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final weekday = weekdays[date.weekday % 7];

    return '${date.year}年${date.month}月${date.day}日  $weekday';
  }
}