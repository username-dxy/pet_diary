# Pet Diary 项目开发指南

## 项目概览

**项目名称**: Pet Diary
**描述**: 一个宠物情绪日记应用，集成AI识别功能和游戏化房间场景
**框架**: Flutter + Provider (MVVM架构)
**Dart版本**: >=3.0.0 <4.0.0
**代码行数**: ~4,470 行 (36个文件)

---

## 目录结构

```
pet_diary/
├── lib/
│   ├── main.dart                          # 应用入口
│   │
│   ├── core/                              # 核心工具层
│   │   ├── constants/                     # 常量定义
│   │   ├── extensions/                    # Dart扩展方法
│   │   ├── theme/                         # 主题配置
│   │   └── utils/                         # 工具函数
│   │
│   ├── data/                              # 数据层 (Repository Pattern)
│   │   ├── models/                        # 数据模型 (5个)
│   │   │   ├── pet.dart                   # 宠物模型
│   │   │   ├── emotion_record.dart        # 情绪记录模型
│   │   │   ├── diary_entry.dart           # 日记条目模型
│   │   │   ├── app_photo.dart             # 应用相册照片模型
│   │   │   └── pet_features.dart          # 宠物特征模型
│   │   │
│   │   ├── repositories/                  # 仓库层 (4个仓库)
│   │   │   ├── pet_repository.dart        # 宠物数据仓库
│   │   │   ├── emotion_repository.dart    # 情绪记录仓库
│   │   │   ├── diary_repository.dart      # 日记数据仓库
│   │   │   └── app_photo_repository.dart  # 相册照片仓库
│   │   │
│   │   └── data_sources/
│   │       └── local/                     # 本地数据源
│   │
│   ├── domain/                            # 领域层 (业务逻辑)
│   │   └── services/                      # 业务服务 (8个)
│   │       ├── ai_service/                # AI相关服务 (3个模型)
│   │       │   ├── emotion_recognition_service.dart   # 模型A: 情绪识别
│   │       │   ├── feature_extraction_service.dart    # 模型B: 特征提取
│   │       │   └── sticker_generation_service.dart    # 模型C: 贴纸生成
│   │       ├── asset_manager.dart                     # 资源管理 + 情绪枚举
│   │       ├── diary_generation_service.dart          # 日记生成服务
│   │       ├── diary_password_service.dart            # 日记密码服务
│   │       ├── photo_storage_service.dart             # 照片存储服务
│   │       └── photo_exif_service.dart                # 照片EXIF读取服务
│   │
│   └── presentation/                      # 表示层 (UI)
│       ├── screens/                       # 屏幕/页面 (5个)
│       │   ├── onboarding/                # 引导页
│       │   │   └── onboarding_screen.dart
│       │   │
│       │   ├── home/                      # 首页 (房间场景)
│       │   │   ├── home_screen.dart
│       │   │   ├── home_viewmodel.dart
│       │   │   └── widgets/               # 3个子组件
│       │   │       ├── calendar_wall_widget.dart
│       │   │       ├── drawer_widget.dart
│       │   │       └── photo_frame_widget.dart
│       │   │
│       │   ├── calendar/                  # 日历页面
│       │   │   ├── calendar_screen.dart
│       │   │   ├── calendar_viewmodel.dart
│       │   │   └── widgets/               # 3个子组件
│       │   │       ├── month_grid_widget.dart
│       │   │       ├── emotion_selector_widget.dart
│       │   │       └── processing_dialog.dart
│       │   │
│       │   ├── diary/                     # 日记页面
│       │   │   ├── diary_screen.dart
│       │   │   ├── diary_viewmodel.dart
│       │   │   └── widgets/               # 4个子组件
│       │   │       ├── diary_page_widget.dart
│       │   │       ├── diary_empty_state_widget.dart
│       │   │       ├── diary_password_dialog.dart
│       │   │       └── photo_info_dialog.dart
│       │   │
│       │   └── profile/                   # 我的页面 (开发中)
│       │       └── profile_screen.dart
│       │
│       ├── common/                        # 通用组件
│       │   ├── widgets/                   # 公共小部件
│       │   └── animations/                # 动画资源
│       │
│       └── providers/                     # 状态管理提供者
│
├── assets/                                # 资源文件
│   ├── animations/
│   │   └── onboarding.gif
│   └── images/
│       ├── room/
│       ├── stickers/
│       └── ui/
│
├── pubspec.yaml                           # 项目配置文件
├── analysis_options.yaml                  # 静态分析配置
└── [其他平台配置: android/, ios/, windows/, macos/, linux/, web/]
```

---

## 架构设计

### MVVM + Repository 模式

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Screens + ViewModels + Widgets)       │
│                                         │
│  View (Screen) ←─watches─→ ViewModel   │
│                            (ChangeNotifier)│
└────────────────┬────────────────────────┘
                 │ calls
┌────────────────▼────────────────────────┐
│           Domain Layer                  │
│        (Business Services)              │
│                                         │
│  Services: AI, Diary, Password, etc.   │
└────────────────┬────────────────────────┘
                 │ calls
┌────────────────▼────────────────────────┐
│            Data Layer                   │
│     (Repositories + Models)             │
│                                         │
│  Repository ──▶ SharedPreferences       │
│       │                                 │
│       └──▶ Model (toJson/fromJson)     │
└─────────────────────────────────────────┘
```

### 数据流向

**单向数据流**:
```
User Action → View → ViewModel → Repository → Model
                ↑                     ↓
                └─── notifyListeners ─┘
```

---

## 核心功能模块

### 1. 首页模块 (Home)
**路径**: `lib/presentation/screens/home/`

**功能**:
- 展示游戏化房间场景
- 墙上日历 (显示今日情绪贴纸)
- 桌子上的抽屉 (进入日记页面)
- 墙上的相框 (进入个人资料)

**ViewModel**: `HomeViewModel`
- `loadCurrentPet()`: 加载当前宠物信息
- `loadTodaySticker()`: 加载今日情绪贴纸
- `checkNewDiary()`: 检查是否有新日记

---

### 2. 日历模块 (Calendar)
**路径**: `lib/presentation/screens/calendar/`

**功能**:
- 月度日历网格展示
- 查看每日情绪记录
- AI处理流程（三模型管道）:
  - 模型A: 情绪识别
  - 模型B: 特征提取
  - 模型C: 贴纸生成

**ViewModel**: `CalendarViewModel`
- `pickAndProcessPhoto()`: 选择照片并开始AI处理
- `recognizeEmotion()`: 调用情绪识别服务
- `extractFeatures()`: 调用特征提取服务
- `generateSticker()`: 调用贴纸生成服务
- `saveEmotionRecord()`: 保存情绪记录

---

### 3. 日记模块 (Diary)
**路径**: `lib/presentation/screens/diary/`

**功能**:
- 日记本翻页展示
- 相册管理（添加/删除照片）
- 基于相册自动生成日记
- 日记密码保护
- 照片EXIF信息展示（拍摄时间、GPS、地点）

**ViewModel**: `DiaryViewModel`
- `loadDiaries()`: 加载日记列表
- `loadAlbumPhotos()`: 加载相册照片
- `generateDiary()`: 调用日记生成服务
- `extractPhotoExif()`: 提取照片EXIF信息
- `verifyPassword()`: 验证日记密码

---

### 4. 引导页模块 (Onboarding)
**路径**: `lib/presentation/screens/onboarding/`

**功能**:
- 登录入口（开发中）
- 游客模式入口

---

### 5. 个人资料模块 (Profile)
**路径**: `lib/presentation/screens/profile/`

**状态**: 开发中（仅占位符）

---

## 技术栈

### 状态管理
- `provider: ^6.1.1` - Provider模式 + ChangeNotifier

### 本地存储
- `shared_preferences: ^2.2.2` - 键值对持久化存储
- `path_provider: ^2.1.1` - 获取应用路径
- `path: ^1.8.3` - 路径操作工具

### 图片处理
- `image_picker: ^1.0.5` - 从相册选择图片
- `image: ^4.1.3` - 图片处理库
- `exif: ^3.3.0` - 读取照片EXIF信息

### 权限管理
- `permission_handler: ^11.3.0` - 请求和管理系统权限

### 工具库
- `intl: ^0.18.1` - 国际化和日期格式化
- `uuid: ^4.2.1` - 生成唯一标识符
- `equatable: ^2.0.5` - 简化对象等值性比较

---

## 数据模型

### 情绪枚举
**位置**: `lib/domain/services/asset_manager.dart`

```dart
enum Emotion {
  happy,    // 开心
  calm,     // 平静
  sad,      // 难过
  angry,    // 生气
  sleepy,   // 困倦
  curious,  // 好奇
}
```

### 核心模型

| 模型 | 文件 | 用途 |
|-----|------|-----|
| `Pet` | `pet.dart` | 宠物基本信息 (名称、类型) |
| `EmotionRecord` | `emotion_record.dart` | 每日情绪记录 |
| `DiaryEntry` | `diary_entry.dart` | 日记条目 |
| `AppPhoto` | `app_photo.dart` | 相册照片 |
| `PetFeatures` | `pet_features.dart` | 宠物特征 (品种、颜色、姿态) |

---

## 业务服务

### AI服务 (ai_service/)

| 服务 | 功能 | 输入 | 输出 |
|-----|------|-----|------|
| `EmotionRecognitionService` | 情绪识别 | 宠物照片 | Emotion + confidence |
| `FeatureExtractionService` | 特征提取 | 宠物照片 | PetFeatures (品种/颜色/姿态) |
| `StickerGenerationService` | 贴纸生成 | 照片 + Emotion + Features | 贴纸图片路径 |

### 其他服务

| 服务 | 功能 |
|-----|------|
| `DiaryGenerationService` | 基于相册照片生成日记文本 |
| `PhotoExifService` | 从照片提取EXIF元数据 |
| `PhotoStorageService` | 照片持久化存储 |
| `DiaryPasswordService` | 日记访问密码管理 |
| `AssetManager` | UI资源和常量管理 |

---

## 开发模版

### 模版1: 创建新的 Model

**位置**: `lib/data/models/your_model.dart`

```dart
import 'package:equatable/equatable.dart';

/// [YourModel] 的简短描述
class YourModel extends Equatable {
  /// 字段说明1
  final String id;

  /// 字段说明2
  final String name;

  /// 字段说明3
  final DateTime createdAt;

  const YourModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  /// 从 JSON 创建实例
  factory YourModel.fromJson(Map<String, dynamic> json) {
    return YourModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 创建副本（用于不可变更新）
  YourModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return YourModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 用于 Equatable 比较
  @override
  List<Object?> get props => [id, name, createdAt];
}
```

**关键点**:
- 继承 `Equatable` 实现等值性比较
- 所有字段使用 `final` 确保不可变性
- 提供 `fromJson`、`toJson`、`copyWith` 方法
- 添加必要的文档注释

---

### 模版2: 创建新的 Repository

**位置**: `lib/data/repositories/your_repository.dart`

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/your_model.dart';

/// [YourModel] 数据仓库
///
/// 负责 [YourModel] 的持久化存储和读取
class YourRepository {
  static const String _storageKey = 'your_data_key';

  /// 获取所有数据
  Future<List<YourModel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = json.decode(jsonString) as List;
    return jsonList
        .map((json) => YourModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 根据ID获取单个数据
  Future<YourModel?> getById(String id) async {
    final items = await getAll();
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 保存单个数据
  Future<void> save(YourModel item) async {
    final items = await getAll();

    // 如果已存在，则更新；否则添加
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
    } else {
      items.add(item);
    }

    await _saveAll(items);
  }

  /// 保存多个数据
  Future<void> saveAll(List<YourModel> items) async {
    await _saveAll(items);
  }

  /// 删除数据
  Future<void> delete(String id) async {
    final items = await getAll();
    items.removeWhere((item) => item.id == id);
    await _saveAll(items);
  }

  /// 清空所有数据
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// 内部方法：保存列表到 SharedPreferences
  Future<void> _saveAll(List<YourModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((item) => item.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }
}
```

**关键点**:
- 使用 SharedPreferences 作为本地存储
- 提供 CRUD 操作方法（增删改查）
- 使用唯一的 `_storageKey` 避免冲突
- 处理空数据情况

---

### 模版3: 创建新的 ViewModel

**位置**: `lib/presentation/screens/your_screen/your_viewmodel.dart`

```dart
import 'package:flutter/foundation.dart';
import '../../../data/models/your_model.dart';
import '../../../data/repositories/your_repository.dart';
import '../../../domain/services/your_service.dart';

/// [YourScreen] 的视图模型
///
/// 管理页面的状态和业务逻辑
class YourViewModel extends ChangeNotifier {
  final YourRepository _repository = YourRepository();
  final YourService _service = YourService();

  // ==================== 状态变量 ====================

  /// 数据列表
  List<YourModel> _items = [];
  List<YourModel> get items => _items;

  /// 是否正在加载
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 错误信息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 选中的项目
  YourModel? _selectedItem;
  YourModel? get selectedItem => _selectedItem;

  // ==================== 生命周期方法 ====================

  /// 初始化
  Future<void> initialize() async {
    await loadData();
  }

  /// 清理资源
  @override
  void dispose() {
    // 清理资源（如果需要）
    super.dispose();
  }

  // ==================== 数据加载 ====================

  /// 加载数据
  Future<void> loadData() async {
    _setLoading(true);
    _clearError();

    try {
      _items = await _repository.getAll();
      notifyListeners();
    } catch (e) {
      _setError('加载数据失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadData();
  }

  // ==================== 业务操作 ====================

  /// 添加项目
  Future<bool> addItem(YourModel item) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.save(item);
      await loadData(); // 重新加载数据
      return true;
    } catch (e) {
      _setError('添加失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新项目
  Future<bool> updateItem(YourModel item) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.save(item);
      await loadData();
      return true;
    } catch (e) {
      _setError('更新失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除项目
  Future<bool> deleteItem(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.delete(id);
      await loadData();
      return true;
    } catch (e) {
      _setError('删除失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 选择项目
  void selectItem(YourModel? item) {
    _selectedItem = item;
    notifyListeners();
  }

  /// 使用服务处理业务逻辑
  Future<void> performServiceAction() async {
    _setLoading(true);
    _clearError();

    try {
      // 调用业务服务
      final result = await _service.doSomething();
      // 处理结果...
      notifyListeners();
    } catch (e) {
      _setError('操作失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== 辅助方法 ====================

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// 清除错误信息
  void _clearError() {
    _errorMessage = null;
  }
}
```

**关键点**:
- 继承 `ChangeNotifier` 实现响应式更新
- 状态变量使用 `_` 私有，通过 getter 公开
- 提供 `initialize()` 初始化方法
- 所有异步操作使用 `try-catch-finally`
- 修改状态后调用 `notifyListeners()`

---

### 模版4: 创建新的 Screen

**位置**: `lib/presentation/screens/your_screen/your_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'your_viewmodel.dart';

/// [YourScreen] 主页面
///
/// 功能描述：...
class YourScreen extends StatelessWidget {
  const YourScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => YourViewModel()..initialize(),
      child: const _YourScreenContent(),
    );
  }
}

/// [YourScreen] 内容组件
class _YourScreenContent extends StatelessWidget {
  const _YourScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<YourViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('页面标题'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: viewModel.refresh,
          ),
        ],
      ),
      body: _buildBody(context, viewModel),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, viewModel),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建主体内容
  Widget _buildBody(BuildContext context, YourViewModel viewModel) {
    // 显示加载指示器
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 显示错误信息
    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              viewModel.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: viewModel.refresh,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 显示空状态
    if (viewModel.items.isEmpty) {
      return const Center(
        child: Text('暂无数据'),
      );
    }

    // 显示列表
    return ListView.builder(
      itemCount: viewModel.items.length,
      itemBuilder: (context, index) {
        final item = viewModel.items[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text(item.id),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, viewModel, item.id),
          ),
          onTap: () => viewModel.selectItem(item),
        );
      },
    );
  }

  /// 显示添加对话框
  Future<void> _showAddDialog(
    BuildContext context,
    YourViewModel viewModel,
  ) async {
    // 实现添加对话框...
  }

  /// 确认删除
  Future<void> _confirmDelete(
    BuildContext context,
    YourViewModel viewModel,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这项吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await viewModel.deleteItem(id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      }
    }
  }
}
```

**关键点**:
- 两层结构：外层 `ChangeNotifierProvider`，内层 `_Content`
- 使用 `context.watch<T>()` 监听 ViewModel
- 处理加载、错误、空状态、正常数据四种状态
- 异步操作后检查 `context.mounted`

---

### 模版5: 创建新的 Widget (子组件)

**位置**: `lib/presentation/screens/your_screen/widgets/your_widget.dart`

```dart
import 'package:flutter/material.dart';

/// [YourWidget] 组件说明
///
/// 功能描述：...
class YourWidget extends StatelessWidget {
  /// 必需参数1
  final String title;

  /// 必需参数2
  final VoidCallback onTap;

  /// 可选参数
  final String? subtitle;

  /// 样式参数
  final Color? backgroundColor;

  const YourWidget({
    Key? key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

**关键点**:
- 优先使用 `StatelessWidget`（除非需要状态）
- 使用 `required` 标记必需参数
- 可选参数使用 `?` 并提供默认值
- 添加清晰的文档注释

---

### 模版6: 创建新的 Service

**位置**: `lib/domain/services/your_service.dart`

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../data/models/your_model.dart';

/// [YourService] 业务服务
///
/// 负责处理 XXX 相关的业务逻辑
class YourService {
  /// 执行某项业务操作
  ///
  /// 参数:
  /// - [input]: 输入参数
  ///
  /// 返回: 操作结果
  ///
  /// 异常:
  /// - 如果操作失败，抛出异常
  Future<String> doSomething(String input) async {
    try {
      // 1. 验证输入
      if (input.isEmpty) {
        throw ArgumentError('输入不能为空');
      }

      // 2. 执行业务逻辑
      final result = await _processInput(input);

      // 3. 返回结果
      return result;
    } catch (e) {
      throw Exception('业务操作失败: $e');
    }
  }

  /// 异步批处理
  Future<List<YourModel>> batchProcess(
    List<String> inputs,
  ) async {
    final results = <YourModel>[];

    for (final input in inputs) {
      try {
        final result = await _processInput(input);
        // 处理结果...
      } catch (e) {
        // 记录错误，但继续处理其他项
        print('处理失败: $input, 错误: $e');
      }
    }

    return results;
  }

  /// 保存文件到应用目录
  Future<String> saveFile(File file, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';

    final savedFile = await file.copy(path);
    return savedFile.path;
  }

  /// 私有辅助方法
  Future<String> _processInput(String input) async {
    // 模拟异步处理
    await Future.delayed(const Duration(milliseconds: 500));
    return 'Processed: $input';
  }
}
```

**关键点**:
- 独立的业务逻辑类
- 使用 `Future` 处理异步操作
- 详细的文档注释（参数、返回值、异常）
- 使用私有方法封装内部逻辑

---

## 代码规范

### 1. 命名规范

| 类型 | 规范 | 示例 |
|-----|------|------|
| 类名 | 大驼峰 (PascalCase) | `UserProfile`, `DiaryEntry` |
| 变量/方法 | 小驼峰 (camelCase) | `userName`, `loadData()` |
| 常量 | 小驼峰 | `maxLength`, `defaultTimeout` |
| 私有成员 | 前缀 `_` | `_repository`, `_loadData()` |
| 文件名 | 蛇形 (snake_case) | `user_profile.dart`, `diary_entry.dart` |

### 2. 文件组织

**Screen 目录结构**:
```
feature_name/
├── feature_screen.dart          # 主页面
├── feature_viewmodel.dart       # 视图模型
└── widgets/                     # 子组件
    ├── component_a_widget.dart
    ├── component_b_widget.dart
    └── dialog_c.dart
```

### 3. 导入顺序

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:io';

// 2. Flutter SDK
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. 第三方包
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 4. 项目内导入
import '../../../data/models/pet.dart';
import '../../../domain/services/ai_service.dart';
```

### 4. 注释规范

```dart
/// 类级别文档注释（三斜杠）
///
/// 详细描述...
class MyClass {
  /// 公共方法文档注释
  ///
  /// 参数:
  /// - [param1]: 参数1的说明
  ///
  /// 返回: 返回值说明
  void myMethod(String param1) {
    // 行内注释（双斜杠）
    // 解释复杂逻辑
  }
}
```

---

## 常用命令

```bash
# 获取依赖
flutter pub get

# 运行应用（调试模式）
flutter run

# 运行应用（发布模式）
flutter run --release

# 代码分析
flutter analyze

# 代码格式化
dart format .

# 清理构建缓存
flutter clean

# 查看设备列表
flutter devices

# 生成图标和启动屏幕
flutter pub run flutter_launcher_icons
```

---

## 调试技巧

### 1. 使用 debugPrint
```dart
import 'package:flutter/foundation.dart';

debugPrint('调试信息: $variable');
```

### 2. 断言检查
```dart
assert(value != null, 'Value cannot be null');
```

### 3. ViewModel 调试
```dart
@override
void notifyListeners() {
  debugPrint('[YourViewModel] State changed');
  super.notifyListeners();
}
```

### 4. Widget 重建检测
```dart
@override
Widget build(BuildContext context) {
  debugPrint('[YourWidget] Rebuilding');
  return Container(...);
}
```

---

## 常见问题

### Q1: SharedPreferences 数据丢失？
**A**: 检查是否在异步操作中正确等待 `await`。

### Q2: ViewModel 不更新 UI？
**A**: 确保在修改状态后调用 `notifyListeners()`。

### Q3: JSON 解析失败？
**A**: 检查 Model 的 `fromJson` 和 `toJson` 方法，确保字段名匹配。

### Q4: 路由跳转失败？
**A**: 确保在 `main.dart` 的 `routes` 中注册了路由。

### Q5: 图片选择权限被拒绝？
**A**: 检查 `AndroidManifest.xml` 和 `Info.plist` 中的权限配置。

---

## 性能优化建议

1. **使用 const 构造函数**
   ```dart
   const Text('Hello')  // 优先使用
   Text('Hello')        // 避免
   ```

2. **列表优化**
   ```dart
   ListView.builder(...)  // 大列表使用 builder
   ListView(children: [...])  // 小列表直接使用
   ```

3. **避免不必要的重建**
   ```dart
   // 使用 context.watch 仅监听需要的状态
   final items = context.watch<ViewModel>().items;  // 好
   final viewModel = context.watch<ViewModel>();    // 监听所有变化
   ```

4. **图片缓存**
   - 使用 `CachedNetworkImage` 代替 `Image.network`
   - 限制图片尺寸和质量

---

## 项目路线图

### 当前版本 (v1.0)
- ✅ 引导页
- ✅ 首页房间场景
- ✅ 日历页面 + AI处理
- ✅ 日记页面 + 相册管理
- ✅ 日记密码保护

### 待开发功能
- 🔲 个人资料页面
- 🔲 用户登录/注册
- 🔲 云端数据同步
- 🔲 社交分享功能
- 🔲 主题切换
- 🔲 多语言支持

---

## 贡献指南

1. 创建新分支: `git checkout -b feature/your-feature`
2. 遵循上述代码规范
3. 添加必要的注释和文档
4. 提交前运行 `flutter analyze` 确保无错误
5. 创建 Pull Request

---

## 联系方式

如有问题，请联系项目维护者。

---

**最后更新**: 2026-01-26
