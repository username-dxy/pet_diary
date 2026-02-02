# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pet Diary is a Flutter app for tracking pet emotions with AI-powered image recognition and a gamified room scene interface. Chinese-localized (zh_CN primary). Uses MVVM architecture with Provider for state management, SharedPreferences for local persistence, and a remote API layer backed by a local Express mock server.

**Dart SDK**: >=3.0.0 <4.0.0

## Development Commands

```bash
# Dependencies
flutter pub get

# Run app
flutter run                          # debug mode
flutter run -d <device-id>          # specific device

# Quality
flutter analyze                      # static analysis (must pass with 0 errors)
dart format .                        # format all Dart files

# Tests
flutter test                         # all tests
flutter test test/widget_test.dart   # single test file

# Mock server
cd mock-server && npm start          # start on port 3000
cd mock-server && npm run dev        # start with nodemon (auto-reload)
```

## Architecture

### MVVM + Repository + Remote API

```
View (Screen) ←watches→ ViewModel (ChangeNotifier)
                              │
                    ┌─────────┴──────────┐
                    ▼                    ▼
              Repository          ApiService (remote)
           (SharedPreferences)    (ApiClient → HTTP)
                    │                    │
                    ▼                    ▼
               Model (local)      ApiModel (api.md format)
```

**Data flow is unidirectional**: User Action → View → ViewModel → Repository/ApiService → Model → notifyListeners() → View.

### Key Patterns

**Screen structure** — every screen uses a two-layer pattern: outer `ChangeNotifierProvider` creates the ViewModel, inner `_ScreenContent` widget watches it:
```dart
class FeatureScreen extends StatelessWidget {
  Widget build(context) => ChangeNotifierProvider(
    create: (_) => FeatureViewModel()..initialize(),
    child: const _FeatureScreenContent(),
  );
}
class _FeatureScreenContent extends StatelessWidget {
  Widget build(context) {
    final vm = context.watch<FeatureViewModel>();
    // ...
  }
}
```

**ViewModel state** — private fields with public getters, `notifyListeners()` after mutations. Always includes `_isLoading` and `_errorMessage`.

**Models** — extend `Equatable`, implement `fromJson`/`toJson`/`copyWith`, use `const` constructors.

**Repositories** — CRUD via SharedPreferences with a unique `_storageKey` per repository.

### Navigation Routes (main.dart)

| Route | Screen | Purpose |
|-------|--------|---------|
| `/onboarding` (initial) | OnboardingScreen | Login/guest entry |
| `/profile-setup` | ProfileSetupScreen | Pet profile creation |
| `/home` | HomeScreen | Room scene (calendar wall → Calendar, drawer → Diary, photo frame → Profile) |
| `/settings` | SettingsScreen | App settings |

Calendar and Diary screens are navigated to programmatically from the home room scene, not via named routes.

### Network Layer

- **`lib/config/api_config.dart`** — environment switching (dev/staging/prod), base URL, token management (get/set/clear via SharedPreferences with memory cache)
- **`lib/core/network/api_client.dart`** — HTTP wrapper with `get<T>()`, `post<T>()`, `uploadFiles<T>()`; auto-attaches `token` header; timeout/error handling
- **`lib/core/network/api_response.dart`** — `ApiResponse<T>` matching server format `{ success, data, error: { message, code } }`
- **`lib/data/data_sources/remote/`** — `PetApiService`, `DiaryApiService`, `ImageApiService` calling `/api/chongyu/` endpoints; `ImageUploadItem` includes `assetId`/`petId`/`date` for server-side dedup

### iOS Native Bridge

- **MethodChannel `com.petdiary/background_scan`** — `performManualScan` (fire-and-forget, returns `true`), permission requests, enable/disable background scan
- **EventChannel `com.petdiary/photo_scan_events`** — streams `{type:"scanResult", assetId, tempFilePath, ...}` per detected pet photo, then `{type:"scanComplete", totalFound:N}` sentinel
- **`PhotoScanEventStreamHandler`** (in `BackgroundTaskManager.swift`) — implements `FlutterStreamHandler`, holds `FlutterEventSink`
- **`PhotoScannerService.scanForPets(onResultFound:)`** — optional per-result callback for streaming

### API Field Mapping

The remote API (api.md spec) uses different field names than local models:
- Pet: `id`↔`petId`, `species`↔`type` (cat=2, dog=1), `gender` (male=1, female=2), `name`↔`nickName`, `ownerNickname`↔`ownerTitle`, `profilePhotoPath`↔`avatar`, `personality`↔`character`
- Diary: `id`↔`diaryId`, emotion as int

### Photo Scan & Upload Pipeline

App startup triggers an automatic scan → compress → upload pipeline:

```
iOS PhotoScannerService (Vision framework)
    │ onResultFound callback per photo
    ▼
BackgroundTaskManager → EventChannel("com.petdiary/photo_scan_events")
    │ streams {type:"scanResult", ...} + {type:"scanComplete", totalFound:N}
    ▼
Flutter BackgroundScanService
    │ rawScanEventStream / scanResultStream
    ▼
HomeViewModel._triggerScanOnStartup()
    │ collects results, waits for scanComplete
    ▼
ScanUploadService.aggregateByDay() → Map<date, List<ScanResult>>
    │ per day:
    ▼
PhotoCompressionService.compressPhoto() → 1080p/JPEG 80%
    ▼
ImageApiService.uploadImages() → POST /api/chongyu/image/list/upload
    │ fields: assetId_N, petId_N, date_N (server dedup by assetId+petId)
    ▼
Server: pet_photos collection, auto-update diary imageList
```

Key services:
- **`lib/domain/services/photo_compression_service.dart`** — resizes to max 1080px long edge, JPEG 80%, runs in isolate
- **`lib/domain/services/scan_upload_service.dart`** — aggregates by day, compresses, uploads, cleans temp files
- **`lib/domain/services/background_scan_service.dart`** — EventChannel + MethodChannel bridge to iOS; `performManualScan()` is fire-and-forget (returns `bool`), results arrive via `scanResultStream`

### Diary Data Flow

Diary loads from server first, falls back to local:
1. `DiaryViewModel.loadData()` → `DiaryApiService.getDiaryList(petId)` → per entry `getDiaryDetail()`
2. Server returns `imageList` (dynamically merged from `pet_photos` + stored `diary.imageList`)
3. `DiaryEntry.imageUrls` populated from server `imageList`
4. `DiaryPageWidget` renders: `imageUrls` (network, horizontal scroll) → fallback `imagePath` (local file)
5. If server unreachable → loads from local `DiaryRepository` (SharedPreferences)

### AI Processing Pipeline

Three-step flow in calendar screen:
1. **EmotionRecognitionService** — photo → `Emotion` + confidence
2. **FeatureExtractionService** — photo → `PetFeatures` (species, breed, color, pose)
3. **StickerGenerationService** — photo + emotion + features → sticker image

### Emotion System

`Emotion` enum in `asset_manager.dart`: `happy`, `calm`, `sad`, `angry`, `sleepy`, `curious`. Each has emoji, localized name, sticker. `AssetManager` is a singleton (`AssetManager.instance`).

### Data Persistence Keys

| Repository | SharedPreferences Key |
|-----------|----------------------|
| PetRepository | `'current_pet'` |
| EmotionRepository | `'emotion_records'` |
| DiaryRepository | `'diary_entries'` |
| AppPhotoRepository | `'app_photos'` |

## Mock Server

Express.js server in `mock-server/` with two API versions:
- **`/api/v1/`** — legacy routes (no auth required)
- **`/api/chongyu/`** — current routes matching api.md spec (requires `token` header)

Server reads/writes `mock-server/db.json` for persistence. File uploads go to `mock-server/uploads/`.

Database collections: `pets`, `photos`, `pet_photos`, `diaries`, `users`.

**`pet_photos` collection** — stores uploaded pet photos with dedup by `assetId + petId`. Upload endpoint auto-creates/updates diary `imageList` and creates placeholder diaries for new dates. Diary detail endpoint dynamically merges `pet_photos` into `imageList`.

Key endpoints:
- `POST /api/chongyu/image/list/upload` — batch upload with `petId_N`, `date_N`, `assetId_N` fields; returns `{ uploaded, duplicates }`
- `GET /api/chongyu/pet/photos?petId=&date=` — query pet photos by petId and optional date
- `GET /api/chongyu/pet/detail?petId=&diaryId=` — diary detail with dynamically built `imageList`

Test with: `curl -H "token: test123" http://localhost:3000/api/chongyu/pet/list`

## File Organization

Each screen module follows: `feature_screen.dart` + `feature_viewmodel.dart` + `widgets/` subdirectory.

Import order: Dart SDK → Flutter SDK → third-party packages → project imports.

## Skills

Custom skills in `.claude/skills/`:
- **`mvvm-checker`** — trigger with "check-mvvm [component]" to validate MVVM compliance
- **`new-feature`** — trigger with "new-feature [name]" to scaffold a complete feature module (model, repository, viewmodel, screen, widgets)

## Common Pitfalls

- Always `await` SharedPreferences methods to avoid data loss
- Call `notifyListeners()` after every ViewModel state change
- Model `fromJson`/`toJson` field names must match JSON keys exactly
- New routes must be registered in `main.dart`'s `routes` map
- Check `context.mounted` before using context after async operations
- The `widget_test.dart` placeholder test is pre-existing broken — not a regression signal
