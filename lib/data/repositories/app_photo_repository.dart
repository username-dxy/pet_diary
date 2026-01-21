import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/app_photo.dart';

/// App相册仓库
class AppPhotoRepository {
  static const String _key = 'app_photos';

  /// 获取所有照片
  Future<List<AppPhoto>> getAllPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map((json) => AppPhoto.fromJson(json as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt)); // 按添加时间倒序
  }

  /// 添加照片到相册
  Future<void> addPhoto(AppPhoto photo) async {
    final prefs = await SharedPreferences.getInstance();
    final photos = await getAllPhotos();

    photos.add(photo);

    final jsonList = photos.map((p) => p.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }

  /// 批量添加照片
  Future<void> addPhotos(List<AppPhoto> newPhotos) async {
    final prefs = await SharedPreferences.getInstance();
    final photos = await getAllPhotos();

    photos.addAll(newPhotos);

    final jsonList = photos.map((p) => p.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }

  /// 删除照片
  Future<void> deletePhoto(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final photos = await getAllPhotos();

    photos.removeWhere((p) => p.id == id);

    final jsonList = photos.map((p) => p.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }

  /// 获取照片总数
  Future<int> getPhotoCount() async {
    final photos = await getAllPhotos();
    return photos.length;
  }

  /// 检查是否有照片
  Future<bool> hasPhotos() async {
    final count = await getPhotoCount();
    return count > 0;
  }
}