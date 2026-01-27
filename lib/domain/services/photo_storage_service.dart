import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 照片存储服务
class PhotoStorageService {
  /// 复制照片到App Documents目录（持久化）
  Future<String> savePhoto(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/diary_photos');
      
      // 创建目录（如果不存在）
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      // 生成唯一文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(sourcePath);
      final fileName = 'diary_$timestamp$extension';
      final targetPath = '${photosDir.path}/$fileName';

      // 复制文件
      final sourceFile = File(sourcePath);
      await sourceFile.copy(targetPath);

      debugPrint('✅ 照片已保存: $targetPath');
      return targetPath;
    } catch (e) {
      debugPrint('❌ 保存照片失败: $e');
      rethrow;
    }
  }

  /// 保存宠物头像照片
  Future<String> saveProfilePhoto(File photoFile, String petId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final profilePhotosDir = Directory('${appDir.path}/profile_photos');

      // 创建目录（如果不存在）
      if (!await profilePhotosDir.exists()) {
        await profilePhotosDir.create(recursive: true);
      }

      // 使用petId作为文件名
      final extension = path.extension(photoFile.path);
      final fileName = 'profile_$petId$extension';
      final targetPath = '${profilePhotosDir.path}/$fileName';

      // 复制文件
      await photoFile.copy(targetPath);

      debugPrint('✅ 头像照片已保存: $targetPath');
      return targetPath;
    } catch (e) {
      debugPrint('❌ 保存头像照片失败: $e');
      rethrow;
    }
  }

  /// 删除照片
  Future<void> deletePhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('✅ 照片已删除: $photoPath');
      }
    } catch (e) {
      debugPrint('❌ 删除照片失败: $e');
    }
  }
}