import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pet_diary/data/models/emotion_record.dart';
import 'package:pet_diary/data/models/pet_features.dart';
import 'package:pet_diary/data/repositories/emotion_repository.dart';
import 'package:pet_diary/domain/services/ai_service/emotion_recognition_service.dart';
import 'package:pet_diary/domain/services/ai_service/feature_extraction_service.dart';
import 'package:pet_diary/domain/services/ai_service/sticker_generation_service.dart';
import 'package:pet_diary/domain/services/asset_manager.dart';
import 'dart:io';

class CalendarViewModel extends ChangeNotifier {
  final EmotionRepository _repository = EmotionRepository();
  final EmotionRecognitionService _emotionService = EmotionRecognitionService();
  final FeatureExtractionService _featureService = FeatureExtractionService();
  final StickerGenerationService _stickerService = StickerGenerationService();

  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;
  Map<DateTime, EmotionRecord> _monthRecords = {};

  // 添加情绪流程状态
  File? _selectedImage;
  double _progress = 0.0;
  String _currentStep = '';
  Emotion? _recognizedEmotion;
  PetFeatures? _extractedFeatures;
  String? _generatedStickerPath;
  bool _isProcessing = false;
  bool _usedFallback = false;
  
  // 权限状态
  String? _permissionError;

  // Getters
  int get currentYear => _currentYear;
  int get currentMonth => _currentMonth;
  Map<DateTime, EmotionRecord> get monthRecords => _monthRecords;
  File? get selectedImage => _selectedImage;
  double get progress => _progress;
  String get currentStep => _currentStep;
  Emotion? get recognizedEmotion => _recognizedEmotion;
  String? get generatedStickerPath => _generatedStickerPath;
  bool get usedFallback => _usedFallback;
  bool get isProcessing => _isProcessing;
  bool get isComplete => _progress >= 1.0 && !_isProcessing;
  String? get permissionError => _permissionError;

  /// 加载月度记录
  Future<void> loadMonth() async {
    _monthRecords = await _repository.getMonthRecords(_currentYear, _currentMonth);
    notifyListeners();
  }

  /// 切换月份
  void changeMonth(int delta) {
    _currentMonth += delta;
    if (_currentMonth > 12) {
      _currentMonth = 1;
      _currentYear++;
    } else if (_currentMonth < 1) {
      _currentMonth = 12;
      _currentYear--;
    }
    loadMonth();
  }

  /// 检查并请求照片权限
  Future<bool> _checkPhotoPermission() async {
    _permissionError = null;
    
    // 请求照片库权限
    PermissionStatus status = await Permission.photos.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      _permissionError = '需要相册权限才能选择照片';
      notifyListeners();
      return false;
    } else if (status.isPermanentlyDenied) {
      _permissionError = '相册权限已被永久拒绝，请在设置中开启';
      notifyListeners();
      return false;
    }
    
    return false;
  }

  /// 打开系统设置
  Future<void> openSystemSettings() async {
    await openAppSettings(); // 这里调用的是permission_handler包的全局函数
  }

  //// 选择照片
  Future<void> pickImage() async {
    _permissionError = null;
    
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedImage = File(image.path);
        
        // ⚠️ 关键：不要调用 _resetProcessState()
        // 只重置处理相关的状态，保留 _selectedImage
        _progress = 0.0;
        _currentStep = '';
        _recognizedEmotion = null;
        _extractedFeatures = null;
        _generatedStickerPath = null;
        _isProcessing = false;
        _usedFallback = false;
        
        notifyListeners();
        
        debugPrint('✅ 照片已赋值: _selectedImage = ${_selectedImage?.path}');
      } else {
        debugPrint('ℹ️ 用户取消了照片选择');
      }
    } on Exception catch (e) {
      _permissionError = '选择照片失败，请确保已授予相册权限';
      notifyListeners();
      debugPrint('❌ 选择照片出错: $e');
    }
  }

  /// 处理照片（兜底流程：直接使用照片）
  Future<void> processImageSimple() async {
    if (_selectedImage == null) return;

    _isProcessing = true;
    _progress = 0.0;
    _currentStep = '① 识别情绪并生成贴纸...';
    notifyListeners();

    try {
      _progress = 0.3;
      notifyListeners();

      final response = await _stickerService.generateStickerFromServer(
        photo: _selectedImage!,
      );

      if (!response.success || response.data == null) {
        throw Exception(response.errorMessage);
      }

      final result = response.data!;
      _recognizedEmotion = result.emotion;
      _extractedFeatures = result.features;
      _generatedStickerPath =
          result.stickerUrl.isNotEmpty ? result.stickerUrl : _selectedImage!.path;
      _usedFallback = false;

      _currentStep = '完成！';
      _progress = 1.0;

      debugPrint('AI流程完成: 情绪=${_recognizedEmotion?.name}');
    } catch (e) {
      debugPrint('AI流程失败，使用兜底方案: $e');
      await _fallbackProcess();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> _fallbackProcess() async {
    _currentStep = '正在处理...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    _usedFallback = true;

    _recognizedEmotion = Emotion.values[
      DateTime.now().millisecondsSinceEpoch % Emotion.values.length
    ];

    _extractedFeatures = const PetFeatures(
      species: 'cat',
      breed: '宠物',
      color: '可爱',
      pose: 'sitting',
    );

    _generatedStickerPath = _selectedImage!.path;

    _currentStep = '完成！';
    _progress = 1.0;

    debugPrint('兜底流程完成: 情绪=${_recognizedEmotion?.name}');
  }

  /// 处理照片（完整的三模型流程）
  Future<void> processImage() async {
    if (_selectedImage == null) return;

    _isProcessing = true;
    _progress = 0.0;
    notifyListeners();

    try {
      // 步骤1：识别情绪（模型A）
      _currentStep = '① 识别情绪...';
      _progress = 0.3;
      notifyListeners();

      final emotionResult = await _emotionService.recognizeEmotion(_selectedImage!);
      _recognizedEmotion = emotionResult.emotion;

      // 步骤2：提取特征（模型B）
      _currentStep = '② 分析特征...';
      _progress = 0.6;
      notifyListeners();

      _extractedFeatures = await _featureService.extractFeatures(_selectedImage!);

      // 步骤3：生成贴纸（模型C）
      _currentStep = '③ 生成贴纸...';
      _progress = 0.9;
      notifyListeners();

      _generatedStickerPath = await _stickerService.generateSticker(
        photo: _selectedImage!,
        emotion: _recognizedEmotion!,
        features: _extractedFeatures!,
      );

      // 完成
      _currentStep = '完成！';
      _progress = 1.0;
      
      debugPrint('AI流程完成: 情绪=${_recognizedEmotion?.name}');
    } catch (e) {
      _currentStep = '生成失败：$e';
      debugPrint('Error processing image: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// 切换情绪（重新生成贴纸）
  Future<void> switchEmotion(Emotion newEmotion) async {
    if (_selectedImage == null || _extractedFeatures == null) return;

    _isProcessing = true;
    _currentStep = '重新生成...';
    _progress = 0.5;
    notifyListeners();

    try {
      _generatedStickerPath = await _stickerService.generateSticker(
        photo: _selectedImage!,
        emotion: newEmotion,
        features: _extractedFeatures!,
      );
      _recognizedEmotion = newEmotion;
      _currentStep = '完成！';
      _progress = 1.0;
      
      debugPrint('切换情绪完成: ${newEmotion.name}');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// 保存记录
  Future<void> saveRecord() async {
    if (_recognizedEmotion == null || _extractedFeatures == null) return;

    final record = EmotionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      petId: 'pet_123', // TODO: 从全局状态获取
      date: DateTime.now(),
      originalPhotoPath: _selectedImage?.path,
      aiEmotion: _recognizedEmotion!,
      aiConfidence: 0.85, // TODO: 从模型A获取真实值
      aiFeatures: _extractedFeatures!,
      selectedEmotion: _recognizedEmotion!,
      stickerUrl: _generatedStickerPath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.saveRecord(record);
    await loadMonth(); // 重新加载月度数据
    _resetProcessState();
    
    debugPrint('记录保存成功: ${record.id}');
  }

  /// 删除记录
  Future<void> deleteRecord(String recordId) async {
    await _repository.deleteRecord(recordId);
    await loadMonth();
    debugPrint('记录删除成功: $recordId');
  }

  /// 重置处理状态
  void _resetProcessState() {
    _selectedImage = null;
    _progress = 0.0;
    _currentStep = '';
    _recognizedEmotion = null;
    _extractedFeatures = null;
    _generatedStickerPath = null;
    _isProcessing = false;
    _permissionError = null;
  }
}
