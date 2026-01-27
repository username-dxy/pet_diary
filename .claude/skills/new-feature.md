---
name: "New Feature Generator"
description: "Scaffolds a complete feature module with MVVM structure"
trigger: "new-feature"
---

# New Feature Module Generator

Creates a complete feature with Screen, ViewModel, and widgets following Pet Diary patterns.

## Usage

When creating a new feature, generate this structure:

```
lib/presentation/screens/{feature_name}/
├── {feature_name}_screen.dart      # Main screen
├── {feature_name}_viewmodel.dart   # ViewModel
└── widgets/                        # Feature-specific widgets
    └── (widgets as needed)
```

## Generation Steps

### Step 1: Create Model (if needed)
**Location**: `lib/data/models/{model_name}.dart`

```dart
import 'package:equatable/equatable.dart';

class {ModelName} extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;

  const {ModelName}({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory {ModelName}.fromJson(Map<String, dynamic> json) {
    return {ModelName}(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  {ModelName} copyWith({String? id, String? name, DateTime? createdAt}) {
    return {ModelName}(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt];
}
```

### Step 2: Create Repository (if needed)
**Location**: `lib/data/repositories/{model_name}_repository.dart`

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/{model_name}.dart';

class {ModelName}Repository {
  static const String _storageKey = '{model_name}_data';

  Future<List<{ModelName}>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = json.decode(jsonString) as List;
    return jsonList
        .map((json) => {ModelName}.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> save({ModelName} item) async {
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

  Future<void> _saveAll(List<{ModelName}> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((item) => item.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }
}
```

### Step 3: Create ViewModel
**Location**: `lib/presentation/screens/{feature_name}/{feature_name}_viewmodel.dart`

```dart
import 'package:flutter/foundation.dart';
import '../../../data/models/{model_name}.dart';
import '../../../data/repositories/{model_name}_repository.dart';

class {FeatureName}ViewModel extends ChangeNotifier {
  final {ModelName}Repository _repository = {ModelName}Repository();

  // State
  List<{ModelName}> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<{ModelName}> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize
  Future<void> initialize() async {
    await loadData();
  }

  // Load data
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _repository.getAll();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add item
  Future<bool> addItem({ModelName} item) async {
    try {
      await _repository.save(item);
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add item: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete item
  Future<bool> deleteItem(String id) async {
    try {
      await _repository.delete(id);
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete item: $e';
      notifyListeners();
      return false;
    }
  }
}
```

### Step 4: Create Screen
**Location**: `lib/presentation/screens/{feature_name}/{feature_name}_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '{feature_name}_viewmodel.dart';

class {FeatureName}Screen extends StatelessWidget {
  const {FeatureName}Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => {FeatureName}ViewModel()..initialize(),
      child: const _{FeatureName}ScreenContent(),
    );
  }
}

class _{FeatureName}ScreenContent extends StatelessWidget {
  const _{FeatureName}ScreenContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<{FeatureName}ViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('{Feature Name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.loadData,
          ),
        ],
      ),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody({FeatureName}ViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(vm.errorMessage!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: vm.loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (vm.items.isEmpty) {
      return const Center(child: Text('No data'));
    }

    return ListView.builder(
      itemCount: vm.items.length,
      itemBuilder: (context, index) {
        final item = vm.items[index];
        return ListTile(
          title: Text(item.name),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => vm.deleteItem(item.id),
          ),
        );
      },
    );
  }
}
```

### Step 5: Register Route
**Location**: `lib/main.dart`

Add to routes:
```dart
routes: {
  // ... existing routes
  '/{feature_name}': (context) => const {FeatureName}Screen(),
}
```

## Checklist After Generation

- [ ] Files created in correct directories
- [ ] Import statements are correct
- [ ] Model extends Equatable with proper methods
- [ ] Repository uses unique storage key
- [ ] ViewModel extends ChangeNotifier
- [ ] Screen uses two-layer Provider structure
- [ ] Route registered in main.dart
- [ ] Run `flutter analyze` to check for errors
- [ ] Run `dart format .` to format code

## Notes

- Replace `{feature_name}` with lowercase_snake_case (e.g., `user_profile`)
- Replace `{FeatureName}` with PascalCase (e.g., `UserProfile`)
- Replace `{ModelName}` with PascalCase (e.g., `User`)
- Replace `{model_name}` with lowercase_snake_case (e.g., `user`)
- Adjust model fields as needed for your feature
- Add widgets to `widgets/` subdirectory as needed

Project: {{directory}}
