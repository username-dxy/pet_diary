import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pet_diary/data/models/diary_entry.dart';

/// 单页日记展示（图文格式）
class DiaryPageWidget extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryPageWidget({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    // 打印日志
    debugPrint('');
    debugPrint('📖 渲染日记卡片:');
    debugPrint('日记ID: ${entry.id}');
    debugPrint('日记日期: ${entry.date}');
    debugPrint('图片路径: ${entry.imagePath}');
    debugPrint('');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DC), // 米黄色纸张
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // 顶部：照片日期标题
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF8B4513),
              ),
              child: Text(
                _formatDate(entry.date),  // ← 显示照片的日期
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // 内容区域（图片+文字）
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 配图（用户上传的照片）
                    _buildDiaryImage(),

                    const SizedBox(height: 20),

                    // 日记正文
                    Text(
                      entry.content,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: Color(0xFF333333),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 底部装饰
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFD2B48C).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  '第 ${entry.date.day} 页',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建日记配图（必须使用用户上传的照片）
  Widget _buildDiaryImage() {
    if (entry.imagePath == null || entry.imagePath!.isEmpty) {
      debugPrint('⚠️ 警告：日记没有配图路径');
      return _buildPlaceholder();
    }

    debugPrint('🖼️ 加载照片: ${entry.imagePath}');
    
    // 检查文件是否存在
    final file = File(entry.imagePath!);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        file,
        width: double.infinity,
        height: 250,  // 增大图片高度
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            debugPrint('✅ 照片加载成功（同步）');
            return child;
          }
          
          if (frame == null) {
            debugPrint('⏳ 照片加载中...');
            return Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                ),
              ),
            );
          }
          
          debugPrint('✅ 照片加载成功（异步）');
          return child;
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ 照片加载失败: $error');
          debugPrint('路径: ${entry.imagePath}');
          return _buildPlaceholder();
        },
      ),
    );
  }

  /// 构建占位图
  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFFF0E6D2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD2B48C),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 60,
            color: Colors.brown[300],
          ),
          const SizedBox(height: 12),
          Text(
            '照片加载失败',
            style: TextStyle(
              fontSize: 16,
              color: Colors.brown[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化日期（显示照片的拍摄日期）
  String _formatDate(DateTime date) {
    final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final weekday = weekdays[date.weekday % 7];

    return '${date.year}年${date.month}月${date.day}日  $weekday';
  }
}