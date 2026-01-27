# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pet Diary is a Flutter app (~4,470 lines, 36 files) for tracking pet emotions with AI-powered image recognition and a gamified room scene interface. Uses MVVM architecture with Provider for state management and SharedPreferences for local persistence.

**Dart Version**: >=3.0.0 <4.0.0

## Development Commands

```bash
# Get dependencies
flutter pub get

# Run app (debug mode)
flutter run

# Run app (release mode)
flutter run --release

# Run on specific device
flutter devices  # List available devices
flutter run -d <device-id>

# Code analysis
flutter analyze

# Format code
dart format .

# Clean build artifacts
flutter clean

# Run tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart
```

## Architecture

### MVVM + Repository Pattern

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Screens + ViewModels + Widgets)       │
│                                         │
│  View (Screen) ←─watches─→ ViewModel   │
│                         (ChangeNotifier)│
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

**Data Flow (Unidirectional)**:
```
User Action → View → ViewModel → Repository → Model
                ↑                     ↓
                └─── notifyListeners ─┘
```

**Key Points:**
- ViewModels extend `ChangeNotifier` and use `notifyListeners()` for UI updates
- Screens use two-layer structure: outer `ChangeNotifierProvider`, inner `_Content` widget
- All models extend `Equatable` and implement `fromJson`/`toJson`/`copyWith`
- Repositories handle CRUD operations with SharedPreferences using unique storage keys
- State variables in ViewModels are private (`_name`) with public getters

### Directory Structure

```
lib/
├── main.dart                          # App entry, routes: /onboarding, /home
│
├── core/                              # Core utilities layer
│   ├── constants/                     # App constants
│   ├── extensions/                    # Dart extensions
│   ├── theme/                         # Theme config
│   └── utils/                         # Utility functions
│
├── data/                              # Data layer
│   ├── models/                        # 5 models: Pet, EmotionRecord, DiaryEntry, AppPhoto, PetFeatures
│   ├── repositories/                  # 4 repositories with SharedPreferences
│   └── data_sources/local/            # Local data sources
│
├── domain/services/                   # Business logic services
│   ├── ai_service/                    # 3-model AI pipeline: emotion → features → sticker
│   │   ├── emotion_recognition_service.dart
│   │   ├── feature_extraction_service.dart
│   │   └── sticker_generation_service.dart
│   ├── asset_manager.dart             # Emotion enum + UI resource paths (singleton)
│   ├── diary_generation_service.dart  # Generate diary from album photos
│   ├── photo_storage_service.dart     # Persistent photo storage
│   ├── photo_exif_service.dart        # Extract EXIF metadata (timestamp, GPS)
│   └── diary_password_service.dart    # Password protection for diaries
│
└── presentation/                      # UI layer
    ├── screens/
    │   ├── onboarding/                # Login/guest entry
    │   ├── home/                      # Room scene with calendar wall, drawer, photo frame
    │   │   ├── home_screen.dart
    │   │   ├── home_viewmodel.dart
    │   │   └── widgets/               # 3 widgets: calendar_wall, drawer, photo_frame
    │   ├── calendar/                  # Month grid + AI processing flow
    │   │   ├── calendar_screen.dart
    │   │   ├── calendar_viewmodel.dart
    │   │   └── widgets/               # 3 widgets: month_grid, emotion_selector, processing_dialog
    │   ├── diary/                     # Diary pages + album management
    │   │   ├── diary_screen.dart
    │   │   ├── diary_viewmodel.dart
    │   │   └── widgets/               # 4 widgets: diary_page, empty_state, password_dialog, photo_info_dialog
    │   └── profile/                   # Placeholder (not implemented)
    ├── common/widgets/                # Shared widgets
    └── providers/                     # State management providers
```

### Emotion System

The `Emotion` enum (in `asset_manager.dart`) defines 6 emotions: `happy`, `calm`, `sad`, `angry`, `sleepy`, `curious`. Each has emoji, localized name, and sticker representation.

### AI Processing Pipeline

Calendar screen implements 3-step AI flow:
1. **EmotionRecognitionService** - Analyzes photo, returns `Emotion` + confidence
2. **FeatureExtractionService** - Extracts `PetFeatures` (species, breed, color, pose)
3. **StickerGenerationService** - Generates sticker image from photo + emotion + features

Each service is a separate class in `domain/services/ai_service/`.

### State Management Pattern

**ViewModel Structure:**
```dart
class FeatureViewModel extends ChangeNotifier {
  final FeatureRepository _repository = FeatureRepository();

  // Private state
  List<Item> _items = [];
  bool _isLoading = false;

  // Public getters
  List<Item> get items => _items;
  bool get isLoading => _isLoading;

  // Async methods call repository, then notifyListeners()
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    _items = await _repository.getAll();
    _isLoading = false;
    notifyListeners();
  }
}
```

**Screen Structure:**
```dart
class FeatureScreen extends StatelessWidget {
  Widget build(context) {
    return ChangeNotifierProvider(
      create: (_) => FeatureViewModel()..initialize(),
      child: const _FeatureScreenContent(),
    );
  }
}

class _FeatureScreenContent extends StatelessWidget {
  Widget build(context) {
    final vm = context.watch<FeatureViewModel>();
    return Scaffold(...);
  }
}
```

### Data Persistence

All repositories use SharedPreferences with unique keys:
- `PetRepository`: `'current_pet'`
- `EmotionRepository`: `'emotion_records'`
- `DiaryRepository`: `'diary_entries'`
- `AppPhotoRepository`: `'app_photos'`

**Repository Pattern:**
```dart
class ExampleRepository {
  static const String _key = 'unique_key';

  Future<List<Model>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    // Decode JSON list, map to Model objects
  }

  Future<void> save(Model item) async {
    // Get all, update/add item, encode to JSON, save
  }
}
```

## Important Conventions

### File Naming
- Models, ViewModels, Screens: `feature_name.dart` (snake_case)
- Widget subdirectory: `screens/feature/widgets/`
- Each screen has: `feature_screen.dart`, `feature_viewmodel.dart`, `widgets/`

### Model Requirements
- Extend `Equatable` with `props` getter
- Implement `fromJson(Map<String, dynamic>)`, `toJson()`, `copyWith()`
- Use `const` constructors where possible

### Asset Management
`AssetManager` is a singleton (`AssetManager.instance`) providing:
- Emotion helper methods: `getEmotionEmoji()`, `getEmotionName()`, `getEmotionSticker()`
- UI color constants: `primaryColor`, `backgroundColor`, `accentColor`
- Resource paths for room scene assets (placeholders, need replacement)

## Key Features

### Photo Album & Diary Generation
- `DiaryViewModel` manages album photos via `AppPhotoRepository`
- `DiaryGenerationService` generates diary text from album photos
- `PhotoExifService` extracts EXIF data (timestamp, GPS, location) from photos

### Diary Password Protection
- `DiaryPasswordService` manages password verification
- Password stored separately from diary content

### Room Scene Navigation
- Home screen shows gamified room
- Calendar wall → Calendar screen
- Drawer → Diary screen
- Photo frame → Profile screen (not implemented)

## Code Templates

When creating new components, follow these patterns:

### Model Template
```dart
class YourModel extends Equatable {
  final String id;
  final String name;

  const YourModel({required this.id, required this.name});

  factory YourModel.fromJson(Map<String, dynamic> json) => YourModel(
    id: json['id'] as String,
    name: json['name'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  YourModel copyWith({String? id, String? name}) => YourModel(
    id: id ?? this.id,
    name: name ?? this.name,
  );

  @override
  List<Object?> get props => [id, name];
}
```

### Repository Template
```dart
class YourRepository {
  static const String _storageKey = 'unique_key';

  Future<List<YourModel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => YourModel.fromJson(json)).toList();
  }

  Future<void> save(YourModel item) async {
    final items = await getAll();
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
    } else {
      items.add(item);
    }
    await _saveAll(items);
  }

  Future<void> delete(String id) async {
    final items = await getAll();
    items.removeWhere((item) => item.id == id);
    await _saveAll(items);
  }

  Future<void> _saveAll(List<YourModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((item) => item.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }
}
```

### ViewModel Template
```dart
class YourViewModel extends ChangeNotifier {
  final YourRepository _repository = YourRepository();

  // Private state
  List<YourModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Public getters
  List<YourModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    await loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _repository.getAll();
    } catch (e) {
      _errorMessage = 'Load failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem(YourModel item) async {
    try {
      await _repository.save(item);
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Add failed: $e';
      notifyListeners();
      return false;
    }
  }
}
```

### Screen Template
```dart
class YourScreen extends StatelessWidget {
  const YourScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => YourViewModel()..initialize(),
      child: const _YourScreenContent(),
    );
  }
}

class _YourScreenContent extends StatelessWidget {
  const _YourScreenContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<YourViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Title')),
      body: vm.isLoading
        ? const Center(child: CircularProgressIndicator())
        : vm.errorMessage != null
          ? Center(child: Text(vm.errorMessage!))
          : vm.items.isEmpty
            ? const Center(child: Text('No data'))
            : ListView.builder(
                itemCount: vm.items.length,
                itemBuilder: (context, index) {
                  final item = vm.items[index];
                  return ListTile(title: Text(item.name));
                },
              ),
    );
  }
}
```

### Widget Template
```dart
class YourWidget extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final String? subtitle;

  const YourWidget({
    Key? key,
    required this.title,
    required this.onTap,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          if (subtitle != null) Text(subtitle!),
        ],
      ),
    );
  }
}
```

### Service Template
```dart
class YourService {
  /// Performs business operation
  ///
  /// Parameters:
  /// - [input]: Input parameter
  ///
  /// Returns: Operation result
  ///
  /// Throws: Exception if operation fails
  Future<String> doSomething(String input) async {
    if (input.isEmpty) {
      throw ArgumentError('Input cannot be empty');
    }

    try {
      final result = await _processInput(input);
      return result;
    } catch (e) {
      throw Exception('Operation failed: $e');
    }
  }

  Future<String> _processInput(String input) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'Processed: $input';
  }
}
```

## Coding Conventions

### Naming
- Classes: PascalCase (`UserProfile`, `DiaryEntry`)
- Variables/methods: camelCase (`userName`, `loadData()`)
- Private members: prefix `_` (`_repository`, `_loadData()`)
- Files: snake_case (`user_profile.dart`, `diary_entry.dart`)

### File Organization
Each screen module follows:
```
feature_name/
├── feature_screen.dart
├── feature_viewmodel.dart
└── widgets/
    ├── component_a_widget.dart
    └── component_b_widget.dart
```

### Import Order
```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. Third-party packages
import 'package:provider/provider.dart';

// 4. Project imports
import '../../../data/models/pet.dart';
```

### Documentation
```dart
/// Class-level documentation (triple slash)
///
/// Detailed description...
class MyClass {
  /// Public method documentation
  ///
  /// Parameters:
  /// - [param1]: Description
  ///
  /// Returns: Description
  void myMethod(String param1) {
    // Inline comment (double slash)
  }
}
```

## Testing Notes

Currently has placeholder `widget_test.dart`. When adding tests:
- Use `flutter test` to run all tests
- ViewModels should be unit tested separately
- Widget tests should use `pumpWidget` with `ChangeNotifierProvider`

## Common Pitfalls

### SharedPreferences data loss
Check that async operations properly `await` SharedPreferences methods.

### ViewModel not updating UI
Ensure `notifyListeners()` is called after state changes.

### JSON parsing failures
Verify Model's `fromJson`/`toJson` field names match exactly.

### Route navigation failures
Ensure routes are registered in `main.dart`'s `routes` map.

### Image picker permission denied
Check `AndroidManifest.xml` and `Info.plist` permission configurations.

## Performance Tips

- Use `const` constructors wherever possible
- Use `ListView.builder` for large lists (not `ListView(children:)`)
- Minimize `context.watch<T>()` scope - only watch specific properties when possible
- Prefer `StatelessWidget` over `StatefulWidget`
- Check `context.mounted` before using context after async operations

## Skills

This project includes custom skills in `.claude/skills/`:

### Available Skills

1. **mvvm-checker** (`mvvm-checker.md`)
   - Validates MVVM architecture compliance
   - Usage: "check-mvvm [file/component]"
   - Checks: ViewModel, Model, Repository, Screen, Widget patterns

2. **new-feature** (`new-feature.md`)
   - Scaffolds complete feature modules
   - Usage: "new-feature [feature_name]"
   - Generates: Model, Repository, ViewModel, Screen with proper structure

### How to Use Skills

**Method 1: Trigger Keywords**
```
"check-mvvm HomeViewModel"
"new-feature UserSettings"
```

**Method 2: Natural Language**
```
"Check if my MVVM architecture is correct"
"Create a new feature for user profile"
```

**Method 3: Explicit Call**
```
"Use mvvm-checker skill to validate this code"
"Use new-feature skill to scaffold a notifications module"
```

## MCP (Model Context Protocol)

This project uses MCP servers to integrate external tools and services. Configuration in `.claude/mcp.json`.

### Configured MCP Servers

1. **filesystem** - Safe file system access
2. **git** - Git operations support
3. **flutter-tools** (custom) - Flutter development tools
   - `flutter_test` - Run tests
   - `flutter_analyze` - Analyze code quality
   - `pub_get` - Get dependencies
   - `dart_format` - Format code
   - `check_mvvm` - Verify MVVM architecture

### Using MCP Tools

MCP tools are automatically invoked by Claude when needed:

```
"Run all tests"                    → flutter_test
"Analyze code quality"             → flutter_analyze
"Check home module architecture"   → check_mvvm
"Format all code"                  → dart_format
```

### MCP vs Skills

- **Skills**: Project-level instructions (lightweight, Markdown-based)
- **MCP**: System-level tool integration (powerful, external processes)

See `.claude/mcp-servers/README.md` for detailed MCP configuration and usage.

## Reference Documentation

See `PROJECT_GUIDE.md` for:
- Complete code templates with detailed examples
- Full architecture diagrams and data flow
- Debugging techniques
- Additional performance optimization strategies
- Project roadmap and contribution guidelines
