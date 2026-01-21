import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pet_diary/data/models/app_photo.dart';

/// 照片详细信息对话框
class PhotoInfoDialog extends StatelessWidget {
  final AppPhoto photo;

  const PhotoInfoDialog({
    super.key,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF8B4513),
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: const Text(
                '📸 照片详细信息',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // 照片预览
            Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[200],
              child: Image.file(
                File(photo.localPath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        const Text('照片加载失败'),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 详细信息
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('照片ID', photo.id),
                    _buildInfoRow('宠物ID', photo.petId),
                    const Divider(),
                    
                    _buildInfoRow(
                      '📅 添加时间',
                      _formatDateTime(photo.addedAt),
                      highlight: true,
                    ),
                    
                    _buildInfoRow(
                      '📸 拍摄时间 (EXIF)',
                      photo.photoTakenAt != null
                          ? _formatDateTime(photo.photoTakenAt!)
                          : '❌ 未读取到EXIF信息',
                      highlight: true,
                      isError: photo.photoTakenAt == null,
                    ),
                    
                    const Divider(),
                    
                    _buildInfoRow(
                      '📍 地理位置',
                      photo.location ?? '❌ 未读取到位置信息',
                      highlight: true,
                      isError: photo.location == null,
                    ),
                    
                    if (photo.latitude != null && photo.longitude != null) ...[
                      _buildInfoRow(
                        '🌐 GPS坐标',
                        'N ${photo.latitude!.toStringAsFixed(6)}, E ${photo.longitude!.toStringAsFixed(6)}',
                      ),
                    ] else
                      _buildInfoRow(
                        '🌐 GPS坐标',
                        '❌ 未读取到GPS信息',
                        isError: true,
                      ),
                    
                    const Divider(),
                    
                    _buildInfoRow('💾 存储路径', photo.localPath, isPath: true),
                    
                    const SizedBox(height: 16),
                    
                    // EXIF说明
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'EXIF信息说明',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            photo.photoTakenAt == null
                                ? '• 此照片不包含拍摄时间信息\n• 将使用添加时间作为日记日期\n• 建议使用相机拍摄的原图'
                                : '• 成功读取到拍摄时间\n• 日记将使用此时间作为日期',
                            style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 关闭按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                  ),
                  child: const Text('关闭'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool highlight = false,
    bool isError = false,
    bool isPath = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: highlight
                  ? (isError ? Colors.red[50] : Colors.green[50])
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: highlight
                    ? (isError ? Colors.red[200]! : Colors.green[200]!)
                    : Colors.grey[300]!,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: isPath ? 11 : 13,
                color: isError ? Colors.red[700] : Colors.black87,
                fontFamily: isPath ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}