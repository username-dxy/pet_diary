import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_diary/data/models/diary_entry.dart';
import 'package:pet_diary/data/models/pet.dart';
import 'package:pet_diary/data/models/app_photo.dart';
import 'package:pet_diary/data/repositories/diary_repository.dart';
import 'package:pet_diary/data/repositories/pet_repository.dart';
import 'package:pet_diary/data/repositories/app_photo_repository.dart';
import 'package:pet_diary/domain/services/diary_generation_service.dart';
import 'package:pet_diary/domain/services/photo_exif_service.dart';
import 'dart:io';
import 'package:pet_diary/domain/services/photo_storage_service.dart';
import 'package:pet_diary/domain/services/diary_password_service.dart';

class DiaryViewModel extends ChangeNotifier {
  final DiaryRepository _diaryRepository = DiaryRepository();
  final PetRepository _petRepository = PetRepository();
  final AppPhotoRepository _photoRepository = AppPhotoRepository();
  final DiaryGenerationService _diaryService = DiaryGenerationService();
  final PhotoExifService _exifService = PhotoExifService();
  final DiaryPasswordService _passwordService = DiaryPasswordService();
  final PhotoStorageService _photoStorageService = PhotoStorageService();
  List<DiaryEntry> _entries = [];
  List<AppPhoto> _albumPhotos = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;
  Pet? _currentPet;

  // Getters
  List<DiaryEntry> get entries => _entries;
  List<AppPhoto> get albumPhotos => _albumPhotos;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  Pet? get currentPet => _currentPet;
  bool get hasPhotosInAlbum => _albumPhotos.isNotEmpty;
  int get albumPhotoCount => _albumPhotos.length;

  /// 当前显示的日记
  DiaryEntry? get currentEntry {
    if (_entries.isEmpty || _currentIndex >= _entries.length) {
      return null;
    }
    return _entries[_currentIndex];
  }

  /// 是否有上一页
  bool get hasPrevious => _currentIndex > 0;

  /// 是否有下一页
  bool get hasNext => _currentIndex < _entries.length - 1;

  /// 初始化
  Future<void> init() async {
    await loadData();
    
    // 在加载数据后，检查相册照片信息
    debugPrint('');
    debugPrint('📋 ========== 相册照片检查 ==========');
    debugPrint('相册照片总数: ${_albumPhotos.length}');
    for (var i = 0; i < _albumPhotos.length; i++) {
      final photo = _albumPhotos[i];
      debugPrint('照片 ${i + 1}:');
      debugPrint('  ID: ${photo.id}');
      debugPrint('  路径: ${photo.localPath}');
      debugPrint('  添加时间: ${photo.addedAt}');
      debugPrint('  拍摄时间: ${photo.photoTakenAt ?? "未读取"}');
      debugPrint('  地理位置: ${photo.location ?? "未读取"}');
      debugPrint('  GPS坐标: ${photo.latitude != null ? "(${photo.latitude}, ${photo.longitude})" : "未读取"}');
    }
    debugPrint('=====================================');
    debugPrint('');
    
    // 静默生成今日日记
    await checkAndGenerateDiaryAutomatically();
    
    // 重新加载日记列表（可能有新生成的）
    _entries = await _diaryRepository.getRecentEntries(limit: 30);
    notifyListeners();
  }

  /// 加载所有数据
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 加载宠物信息
      _currentPet = await _petRepository.getCurrentPet();

      // 加载相册照片
      _albumPhotos = await _photoRepository.getAllPhotos();

      // 加载日记列表
      _entries = await _diaryRepository.getRecentEntries(limit: 30);

      debugPrint('✅ 数据加载完成');
      debugPrint('相册照片: ${_albumPhotos.length}');
      debugPrint('日记数量: ${_entries.length}');
    } catch (e) {
      _errorMessage = '加载数据失败：$e';
      debugPrint('❌ 加载错误: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 选择照片添加到相册
  Future<void> pickPhotosToAlbum() async {
    try {
      final picker = ImagePicker();

      // 支持多选
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty) {
        debugPrint('ℹ️ 用户未选择照片');
        return;
      }

      debugPrint('📸 用户选择了 ${images.length} 张照片');

      // 处理每张照片
      final newPhotos = <AppPhoto>[];

      for (final image in images) {
        final file = File(image.path);

        // ⚠️ 关键修复：立即复制到持久化目录
        final persistentPath = await _photoStorageService.savePhoto(file.path);
        debugPrint('✅ 照片已持久化: $persistentPath');

        // 提取EXIF信息
        final metadata = await _exifService.extractMetadata(file);

        // 创建AppPhoto对象（使用持久化路径）
        final photo = AppPhoto(
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              '_${newPhotos.length}',
          petId: _currentPet?.id ?? 'pet_123',
          localPath: persistentPath,  // ← 使用持久化路径，而不是临时路径
          addedAt: DateTime.now(),
          photoTakenAt: metadata.takenAt,
          location: metadata.location,
          latitude: metadata.latitude,
          longitude: metadata.longitude,
        );

        newPhotos.add(photo);
      }

      // 批量保存到相册
      await _photoRepository.addPhotos(newPhotos);

      // 重新加载相册
      _albumPhotos = await _photoRepository.getAllPhotos();
      notifyListeners();

      debugPrint('✅ 已添加 ${newPhotos.length} 张照片到相册（持久化存储）');
    } catch (e) {
      _errorMessage = '添加照片失败：$e';
      notifyListeners();
      debugPrint('❌ 添加照片错误: $e');
    }
  }

  /// 从相册删除照片
  Future<void> deletePhotoFromAlbum(String photoId) async {
    try {
      await _photoRepository.deletePhoto(photoId);
      _albumPhotos = await _photoRepository.getAllPhotos();
      notifyListeners();
      debugPrint('✅ 照片已删除: $photoId');
    } catch (e) {
      _errorMessage = '删除照片失败：$e';
      notifyListeners();
      debugPrint('❌ 删除照片错误: $e');
    }
  }

  /// 检查并静默生成日记
  Future<void> checkAndGenerateDiaryAutomatically() async {
    debugPrint('');
    debugPrint('🤖 ========== 检查是否需要静默生成日记 ==========');
    
    if (_currentPet == null || _albumPhotos.isEmpty) {
      debugPrint('ℹ️ 无法静默生成：宠物=${_currentPet != null} 照片=${_albumPhotos.isNotEmpty}');
      return;
    }

    try {
      // 检查今日是否已有日记
      final today = DateTime.now();
      final todayEntry = await _diaryRepository.getEntryByDate(today);
      
      if (todayEntry != null) {
        debugPrint('ℹ️ 今日日记已存在，无需生成');
        debugPrint('  日记日期: ${todayEntry.date}');
        debugPrint('  日记ID: ${todayEntry.id}');
        return;
      }

      debugPrint('📝 今日无日记，开始静默生成...');

      // 静默生成日记
      final result = await _diaryService.generateFromAlbum(
        photos: _albumPhotos,
        pet: _currentPet!,
      );

      final imagePath = result.selectedPhotoPath;
      debugPrint('📸 使用照片路径: $imagePath');

      // 创建日记条目
      final entry = DiaryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        petId: _currentPet!.id,
        date: result.photoDate ?? DateTime.now(),
        content: result.content,
        imagePath: imagePath,
        isLocked: false,
        emotionRecordId: result.selectedPhotoId,
        createdAt: DateTime.now(),
      );

      // 保存到本地
      await _diaryRepository.saveEntry(entry);
      debugPrint('✅ 静默生成日记成功');
      debugPrint('  日记日期: ${entry.date}');
      
    } catch (e) {
      debugPrint('❌ 静默生成日记失败: $e');
    }
    
    debugPrint('========================================');
    debugPrint('');
  }

  /// 生成日记（基于相册）
  Future<void> generateDiary() async {
    debugPrint('');
    debugPrint('🎬 ========== 开始生成日记流程 ==========');
    
    if (_currentPet == null) {
      _errorMessage = '请先创建宠物信息';
      notifyListeners();
      debugPrint('❌ 生成失败：宠物信息不存在');
      return;
    }

    if (_albumPhotos.isEmpty) {
      _errorMessage = '相册中还没有照片，请先添加照片';
      notifyListeners();
      debugPrint('❌ 生成失败：相册为空');
      return;
    }

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('📊 当前相册照片数: ${_albumPhotos.length}');
      
      // 打印相册中的照片信息
      for (var i = 0; i < _albumPhotos.length; i++) {
        final photo = _albumPhotos[i];
        debugPrint('  照片${i + 1}: ID=${photo.id}');
        debugPrint('    拍摄时间=${photo.photoTakenAt}');
        debugPrint('    添加时间=${photo.addedAt}');
        debugPrint('    路径=${photo.localPath}');
      }

      // 调用后端API生成日记（传入完整照片列表）
      debugPrint('🔄 调用日记生成服务...');
      final result = await _diaryService.generateFromAlbum(
        photos: _albumPhotos,  // ← 传入完整照片对象
        pet: _currentPet!,
      );

      debugPrint('✅ 日记生成服务返回结果:');
      debugPrint('  选中照片ID: ${result.selectedPhotoId}');
      debugPrint('  照片路径: ${result.selectedPhotoPath}');
      debugPrint('  照片日期: ${result.photoDate}');
      debugPrint('  照片地点: ${result.location ?? "未知"}');
      debugPrint('  日记内容: ${result.content.substring(0, 50)}...');

      // 使用返回的照片路径
      final imagePath = result.selectedPhotoPath;
      
      if (imagePath == null || imagePath.isEmpty) {
        debugPrint('⚠️ 警告：未获取到照片路径');
      } else {
        debugPrint('✅ 使用照片路径: $imagePath');
        
        // 验证文件是否存在
        final file = File(imagePath);
        final exists = await file.exists();
        debugPrint('📁 文件存在性检查: ${exists ? "✅ 存在" : "❌ 不存在"}');
        
        if (exists) {
          final fileSize = await file.length();
          debugPrint('📏 文件大小: ${fileSize} bytes');
        }
      }

      // 创建日记条目
      final entry = DiaryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        petId: _currentPet!.id,
        date: result.photoDate ?? DateTime.now(),  // ← 使用照片日期
        content: result.content,
        imagePath: imagePath,
        isLocked: false,
        emotionRecordId: result.selectedPhotoId,
        createdAt: DateTime.now(),
      );

      debugPrint('💾 准备保存日记条目:');
      debugPrint('  日记ID: ${entry.id}');
      debugPrint('  日记日期: ${entry.date}');
      debugPrint('  图片路径: ${entry.imagePath}');

      // 保存到本地
      await _diaryRepository.saveEntry(entry);
      debugPrint('✅ 日记已保存到本地数据库');

      // 重新加载日记列表
      debugPrint('🔄 重新加载日记列表...');
      _entries = await _diaryRepository.getRecentEntries(limit: 30);
      debugPrint('📚 当前日记总数: ${_entries.length}');

      debugPrint('🎉 ========== 日记生成流程完成 ==========');
      debugPrint('');
    } catch (e, stackTrace) {
      _errorMessage = '生成日记失败：$e';
      debugPrint('❌ ========== 生成日记错误 ==========');
      debugPrint('错误信息: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      debugPrint('');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// 翻到上一页
  void previousPage() {
    if (hasPrevious) {
      _currentIndex--;
      notifyListeners();
    }
  }

  /// 翻到下一页
  void nextPage() {
    if (hasNext) {
      _currentIndex++;
      notifyListeners();
    }
  }

  /// 跳转到指定索引
  void jumpToIndex(int index) {
    if (index >= 0 && index < _entries.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// 删除日记
  Future<void> deleteEntry(String id) async {
    try {
      await _diaryRepository.deleteEntry(id);
      _entries = await _diaryRepository.getRecentEntries(limit: 30);
      notifyListeners();
      debugPrint('✅ 日记已删除');
    } catch (e) {
      _errorMessage = '删除失败：$e';
      notifyListeners();
      debugPrint('❌ 删除日记错误: $e');
    }
  }
}
