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

class DiaryViewModel extends ChangeNotifier {
  final DiaryRepository _diaryRepository = DiaryRepository();
  final PetRepository _petRepository = PetRepository();
  final AppPhotoRepository _photoRepository = AppPhotoRepository();
  final DiaryGenerationService _diaryService = DiaryGenerationService();
  final PhotoExifService _exifService = PhotoExifService();

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

        // 提取EXIF信息
        final metadata = await _exifService.extractMetadata(file);

        // 创建AppPhoto对象
        final photo = AppPhoto(
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              '_${newPhotos.length}',
          petId: _currentPet?.id ?? 'pet_123',
          localPath: file.path,
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

      debugPrint('✅ 已添加 ${newPhotos.length} 张照片到相册');
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

  /// 生成日记（基于相册）
  Future<void> generateDiary() async {
    if (_currentPet == null) {
      _errorMessage = '请先创建宠物信息';
      notifyListeners();
      return;
    }

    if (_albumPhotos.isEmpty) {
      _errorMessage = '相册中还没有照片，请先添加照片';
      notifyListeners();
      return;
    }

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 开始生成日记...');
      debugPrint('相册照片数: ${_albumPhotos.length}');

      // 提取照片ID列表
      final photoIds = _albumPhotos.map((p) => p.id).toList();

      // 调用后端API生成日记
      final result = await _diaryService.generateFromAlbum(
        photoIds: photoIds,
        pet: _currentPet!,
      );

      // 创建日记条目
      final entry = DiaryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        petId: _currentPet!.id,
        date: result.photoDate ?? DateTime.now(),
        content: result.content,
        isLocked: false,
        emotionRecordId: result.selectedPhotoId,
        createdAt: DateTime.now(),
      );

      // 保存到本地
      await _diaryRepository.saveEntry(entry);

      // 重新加载日记列表
      _entries = await _diaryRepository.getRecentEntries(limit: 30);

      debugPrint('✅ 日记生成成功');
      debugPrint('使用的照片ID: ${result.selectedPhotoId}');
    } catch (e) {
      _errorMessage = '生成日记失败：$e';
      debugPrint('❌ 生成日记错误: $e');
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
