---
name: "MVVM Architecture Checker"
description: "Validates MVVM pattern compliance in Pet Diary project"
trigger: "check-mvvm"
---

# MVVM Architecture Compliance Checker

Validates code against Pet Diary's MVVM + Repository pattern.

## Architecture Rules

### ViewModel Checklist
- [ ] Extends `ChangeNotifier`
- [ ] All state variables are private with `_` prefix
- [ ] Public getters provided for state access
- [ ] Calls `notifyListeners()` after state changes
- [ ] Uses repository for data access (not direct SharedPreferences)
- [ ] Includes `initialize()` method
- [ ] Has proper error handling with try-catch-finally
- [ ] No UI logic (no BuildContext, no Navigator)

### Model Checklist
- [ ] Extends `Equatable`
- [ ] All fields are `final`
- [ ] Has `const` constructor
- [ ] Implements `fromJson(Map<String, dynamic>)`
- [ ] Implements `toJson()` returning `Map<String, dynamic>`
- [ ] Implements `copyWith()` for immutable updates
- [ ] Overrides `props` getter for Equatable

### Repository Checklist
- [ ] Has unique `_storageKey` constant
- [ ] Uses SharedPreferences for persistence
- [ ] Provides CRUD methods: `getAll()`, `getById()`, `save()`, `delete()`
- [ ] Returns Future for all async operations
- [ ] Handles null/empty data gracefully
- [ ] Uses Model's toJson/fromJson for serialization

### Screen Checklist
- [ ] Two-layer structure: Provider wrapper + Content widget
- [ ] Outer layer: `ChangeNotifierProvider` with `create`
- [ ] Inner layer: `_ScreenContent` private class
- [ ] Uses `context.watch<ViewModel>()` to observe state
- [ ] Handles 4 states: loading, error, empty, data
- [ ] No business logic (delegates to ViewModel)
- [ ] Checks `context.mounted` after async operations

### Widget Checklist
- [ ] Prefers `StatelessWidget` over `StatefulWidget`
- [ ] Required parameters use `required` keyword
- [ ] Optional parameters use `?` and have defaults
- [ ] Has documentation comments
- [ ] Located in `screens/{feature}/widgets/` directory

### Service Checklist
- [ ] Located in `domain/services/`
- [ ] Contains business logic, not data access
- [ ] Returns `Future` for async operations
- [ ] Has comprehensive documentation
- [ ] Throws meaningful exceptions
- [ ] No direct UI dependencies

## Data Flow Validation

Correct flow:
```
User Action → Screen → ViewModel → Service/Repository → Model
                ↑           ↓
                └─ notifyListeners()
```

Anti-patterns to avoid:
- ❌ Screen directly accessing Repository
- ❌ Model containing business logic
- ❌ ViewModel importing Flutter UI widgets
- ❌ Repository performing business logic
- ❌ Service accessing SharedPreferences directly

## File Naming Conventions
- Models: `entity_name.dart` (e.g., `pet.dart`)
- Repositories: `entity_repository.dart` (e.g., `pet_repository.dart`)
- ViewModels: `screen_viewmodel.dart` (e.g., `home_viewmodel.dart`)
- Screens: `screen_screen.dart` (e.g., `home_screen.dart`)
- Widgets: `descriptive_widget.dart` (e.g., `calendar_wall_widget.dart`)
- Services: `purpose_service.dart` (e.g., `photo_storage_service.dart`)

## Import Order
1. Dart SDK (dart:xxx)
2. Flutter SDK (package:flutter/xxx)
3. Third-party packages (package:xxx)
4. Project imports (relative paths)

## Current Project Context
- Working directory: {{directory}}
- Date: {{date}}
- Architecture: MVVM + Repository Pattern
- State Management: Provider (ChangeNotifier)
- Persistence: SharedPreferences
