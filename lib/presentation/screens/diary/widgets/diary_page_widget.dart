import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pet_diary/data/models/diary_entry.dart';

/// 单页日记展示（图文格式）
class DiaryPageWidget extends StatelessWidget {
  final DiaryEntry entry;
  final String petName;
  final VoidCallback? onUpgradeTap;

  const DiaryPageWidget({
    super.key,
    required this.entry,
    required this.petName,
    this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
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
                _formatDate(entry.date),
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
                child: entry.isLocked ? _buildLockedState() : _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 配图（多照片或单照片）
        _buildDiaryImages(),
        const SizedBox(height: 20),
        if (entry.content.isNotEmpty)
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
    );
  }

  Widget _buildLockedState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 56, color: Colors.brown[300]),
            const SizedBox(height: 14),
            Text(
              '升级至会员可“偷看”更多$petName的日记',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6D4C41),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onUpgradeTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.white,
              ),
              child: const Text('升级会员'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建日记配图 — 优先使用 imageUrls（网络），fallback 到 imagePath（本地）
  Widget _buildDiaryImages() {
    // 优先使用服务端返回的 imageUrls
    if (entry.imageUrls.isNotEmpty) {
      return _buildNetworkImageList(entry.imageUrls);
    }

    // Fallback 到本地 imagePath
    if (entry.imagePath != null && entry.imagePath!.isNotEmpty) {
      return _buildLocalImage(entry.imagePath!);
    }

    return _buildPlaceholder();
  }

  /// 构建网络图片列表（水平滚动）
  Widget _buildNetworkImageList(List<String> urls) {
    if (urls.length == 1) {
      // 单张图片全宽展示
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              urls.first,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              loadingBuilder: _networkImageLoadingBuilder,
              errorBuilder: _networkImageErrorBuilder,
            ),
          ),
          const SizedBox(height: 6),
          _buildPhotoCount(1),
        ],
      );
    }

    // 多张图片水平滚动
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  urls[index],
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                  loadingBuilder: _networkImageLoadingBuilder,
                  errorBuilder: _networkImageErrorBuilder,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        _buildPhotoCount(urls.length),
      ],
    );
  }

  /// 构建本地文件图片（单张，兼容旧数据）
  Widget _buildLocalImage(String path) {
    // Check if it's a network URL (http/https)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              path,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              loadingBuilder: _networkImageLoadingBuilder,
              errorBuilder: _networkImageErrorBuilder,
            ),
          ),
          const SizedBox(height: 6),
          _buildPhotoCount(1),
        ],
      );
    }

    final file = File(path);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          ),
        ),
        const SizedBox(height: 6),
        _buildPhotoCount(1),
      ],
    );
  }

  /// 网络图片加载中
  Widget _networkImageLoadingBuilder(
    BuildContext context,
    Widget child,
    ImageChunkEvent? loadingProgress,
  ) {
    if (loadingProgress == null) return child;
    return Container(
      width: 250,
      height: 250,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
          valueColor:
              const AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// 网络图片加载错误
  Widget _networkImageErrorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFFF0E6D2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 40, color: Colors.brown[300]),
          const SizedBox(height: 8),
          Text(
            '加载失败',
            style: TextStyle(fontSize: 12, color: Colors.brown[400]),
          ),
        ],
      ),
    );
  }

  /// 照片计数标签
  Widget _buildPhotoCount(int count) {
    return Text(
      '$count 张照片',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[500],
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
            '暂无照片',
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
