import 'dart:io';
import 'package:flutter/material.dart';

/// 照片上传 Section - Figma 木质相框风格
class PhotoUploadSection extends StatelessWidget {
  final File? photo;
  final VoidCallback onTap;
  final String? errorMessage;
  final double frameSize;

  const PhotoUploadSection({
    Key? key,
    required this.photo,
    required this.onTap,
    this.errorMessage,
    this.frameSize = 195.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 内部热区按相框比例计算: 145/195 ≈ 0.7436
    final innerSize = frameSize * (145.0 / 195.0);
    final innerOffset = (frameSize - innerSize) / 2;

    return Column(
      children: [
        const Text(
          '上传宠物照片',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5C3D1A),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: frameSize,
            height: frameSize,
            child: Stack(
              children: [
                // 木质相框
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/profile_setup/photo_frame.jpg',
                    fit: BoxFit.contain,
                  ),
                ),

                // 中心区域：显示用户照片或占位 +
                Positioned(
                  left: innerOffset,
                  top: innerOffset,
                  width: innerSize,
                  height: innerSize,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: photo != null
                        ? Image.file(
                            photo!,
                            fit: BoxFit.cover,
                            width: innerSize,
                            height: innerSize,
                          )
                        : Center(
                            child: Icon(
                              Icons.add,
                              size: frameSize * 0.18,
                              color: Colors.brown.withValues(alpha: 0.4),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
