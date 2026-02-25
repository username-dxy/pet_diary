# Pet Diary App 功能梳理文档

> 整理日期：2026-02-25
> 目标：App 上架前的功能盘点，覆盖所有交互点与数据流转
> 受众：服务端、客户端、UI 团队

---

## 一、导航体系

```
启动判断 (main.dart)
├─ 有宠物档案 → /home (HomeScreen)
└─ 无档案    → /onboarding (OnboardingScreen)

/onboarding  → /profile-setup → /home
/home        → CalendarScreen  (push, 非命名路由)
/home        → DiaryScreen     (push, 非命名路由)
/home        → ProfileScreen   (push, 非命名路由)
/home        → /settings       (pushNamed)
```

| 路由 | Screen | 用途 |
|-----|--------|------|
| `/onboarding` | OnboardingScreen | 欢迎介绍 + 进入入口 |
| `/profile-setup` | ProfileSetupScreen | 宠物档案创建 |
| `/home` | HomeScreen | 房间场景主页 |
| `/settings` | SettingsScreen | 应用设置 |

---

## 二、各页面交互与数据流

### 1. OnboardingScreen（欢迎页）

无 ViewModel，纯展示页面。

| 交互元素 | 操作 | 数据流 |
|---------|------|--------|
| "开始使用"按钮 | 点击 | `pushReplacementNamed('/profile-setup')` |

展示内容：GIF 动画 + "记录 Ta 的每一天" 标题 + 副标题 + 隐私提示

---

### 2. ProfileSetupScreen（档案创建）

**ViewModel**: `ProfileSetupViewModel`

| 交互元素 | 操作 | 数据流 |
|---------|------|--------|
| 头像区域 | 点击 | `vm.pickPhoto()` → ImagePicker(gallery, 1024×1024, quality 85) → `_profilePhoto` |
| 宠物名输入框 | 文本输入 | `vm.setName(value)` |
| 主人称呼选项 | 点击预设选项 | `vm.setOwnerNickname(value)` |
| 生日选择 | 点击 | DatePicker → `vm.setBirthday(value)` |
| 性别按钮组 | 点击（男孩/女孩/保密） | `vm.setGender(value)` |
| 性格按钮组 | 点击（活泼/安静/粘人/独立/爱玩/慵懒） | `vm.setPersonality(value)` |
| "完成设置"按钮 | 点击（name 非空 && photo 非 null 时启用） | 见下方完整流程 |

**完成设置数据流**：

```
submitProfile()
  ├─ PhotoStorageService.savePhoto(file) → 应用私有目录（持久化）
  ├─ DeviceIdService.getId() → 生成/读取设备 ID（用作 petId）
  ├─ 创建 Pet 对象 (id = deviceId)
  ├─ PetRepository.savePet() → SharedPreferences('current_pet')
  ├─ ApiConfig.setToken(pet.id)
  ├─ (async 非阻塞) ProfileService.api().syncProfile(pet)
  │   └─ POST /api/mengyu/pet/create
  └─ pushReplacementNamed('/home')
```

---

### 3. HomeScreen（房间主页）

**ViewModel**: `HomeViewModel`
**背景图**：抽屉关闭 `room_drawer_closed.jpg` / 打开 `room_drawer_open.jpg`（根据 `vm.isDrawerOpen` 切换）

**热区交互（响应式缩放，Figma 设计稿 393×852）**：

| 热区 | 位置（设计稿坐标） | 可见状态 | 操作 | 数据流 |
|-----|----------------|---------|------|--------|
| 日历墙 | x=263.5, y=44, w=128.5, h=144 | 开/关均可 | 点击 | `_navigateToCalendar()` → push CalendarScreen；返回时 `vm.refresh()` |
| 相框 | x=5, y=250.5, w=113.5, h=206 | 开/关均可 | 点击 | `_navigateToProfile()` → push ProfileScreen |
| 抽屉把手（关闭态） | x=66, y=538, w=79, h=92.5 | 抽屉关闭 | 点击 | `vm.toggleDrawer()` → 背景切换 |
| 抽屉把手（打开态） | x=133, y=571, w=79, h=92.5 | 抽屉打开 | 点击 | `vm.toggleDrawer()` → 背景切换 |
| 日记本 | x=93, y=556.5, w=80.5, h=47.5 | 抽屉打开 | 点击 | `vm.markDiaryViewed()` → push DiaryScreen |
| 设置图标（AppBar 右侧） | — | 任意 | 点击 | `pushNamed('/settings')` |

**ViewModel 状态字段**：

```dart
_currentPet: Pet?         // 当前宠物
_todaySticker: EmotionRecord?  // 今日贴纸（是否显示新日记红点）
_hasNewDiary: bool         // 是否有新日记
_isDrawerOpen: bool        // 抽屉开关
_isScanning: bool          // 正在扫描
_scanProgress: int         // 当前进度
_scanTotal: int            // 总数
_scanStatus: String        // 状态文案（显示在 UI）
```

**自动启动照片扫描流程（`loadData()` 时触发）**：

```
_triggerScanOnStartup()
  1. 权限检查
     BackgroundScanService.getPhotoPermissionStatus() → PhotoPermissionStatus

  2. 触发 iOS 扫描
     BackgroundScanService.performManualScan()
     → MethodChannel('com.petdiary/background_scan', 'performManualScan')
     → 返回 bool（仅触发确认，结果异步到达）

  3. 监听 EventChannel 流
     _scanService.rawScanEventStream
     ├─ {type:"scanResult", assetId, tempFilePath, animalType, confidence,
     │   creationDate, latitude, longitude} × N 条
     └─ {type:"scanComplete", totalFound:N} → 结束收集

  4. 按天聚合
     ScanUploadService.aggregateByDay(results)
     → Map<"YYYY-MM-DD", List<ScanResult>>

  5. 逐天压缩 + 上传
     for (date, results) in byDay:
       for result in results:
         ├─ PhotoCompressionService.compressPhoto(path)
         │   ├─ 在 isolate 中运行（不阻塞 UI）
         │   ├─ 如果 < 1MB → 直接返回原始路径
         │   └─ 否则 → 最大边 1080px, JPEG 80% → /tmp/compressed_XXX.jpg
         └─ ImageApiService.uploadImages([ImageUploadItem])
             └─ POST /api/mengyu/image/list/upload (multipart)
                字段: image_N, assetId_N, petId_N, date_N, time_N, location_N
                服务端自动：
                  ├─ 写入 pet_photos（按 assetId+petId 去重）
                  ├─ 合并 imageList 到对应日期 diary
                  └─ 创建该日期占位 diary（如不存在）

  6. 清理临时文件
     PhotoCompressionService.cleanupTempFile(path)

  7. UI 更新
     _isScanning, _scanProgress, _scanTotal, _scanStatus → notifyListeners()
```

---

### 4. CalendarScreen（日历）

**ViewModel**: `CalendarViewModel`
**背景图**：`room_calendar_expanded.jpg`

| 交互元素 | 操作 | 数据流 |
|---------|------|--------|
| 返回按钮 | 点击 | `Navigator.pop()` |
| "上月"按钮 | 点击 | `vm.changeMonth(-1)` → 重新加载月度情绪数据 |
| "下月"按钮 | 点击 | `vm.changeMonth(+1)` → 重新加载月度情绪数据 |
| 日期格子（有情绪记录） | 点击 | `_handleDayTap()` → BottomSheet（EmotionSelectorWidget） |
| 情绪选择器 6 个按钮 | 点击 | `vm.updateRecordEmotion(date, emotion)` → 更新本地 + async POST emotion/save |
| FAB "+" 按钮 | 点击 | 见下方完整流程 |

**情绪枚举**（Emotion）：`happy 😊` / `calm 😌` / `sad 😢` / `angry 😠` / `sleepy 😴` / `curious 🤔`

**FAB 添加情绪数据流**：

```
_handleAddEmotion()
  ├─ vm.pickImage()
  │   └─ ImagePicker.pickImage(source: gallery) → _selectedImage: File?

  ├─ 权限错误 → SnackBar 提示 + AppSettings.openAppSettings()

  ├─ showDialog(ProcessingDialog)  // 显示进度条 + 步骤文案

  ├─ vm.processImageSimple()
  │   ├─ 尝试 AI 处理
  │   │   └─ StickerGenerationService.generateStickerFromServer(photo)
  │   │       └─ POST /api/mengyu/ai/sticker/generate
  │   │           返回: {emotion, confidence, features{species,breed,color,pose}, stickerUrl}
  │   │           → _recognizedEmotion, _generatedStickerPath, _extractedFeatures
  │   └─ 失败 fallback (_fallbackProcess)
  │       └─ 随机 emotion + 照片路径作为 stickerPath

  ├─ ProcessingDialog 自动关闭（processImageSimple 完成时）

  └─ saveRecord()
      ├─ 创建 EmotionRecord 对象
      ├─ EmotionRepository.saveRecord()
      │   └─ SharedPreferences('emotion_records')
      └─ (async 非阻塞) EmotionApiService.saveEmotionRecord()
          └─ POST /api/mengyu/emotions/save
```

**ViewModel 状态字段**：

```dart
_currentYear, _currentMonth: int       // 当前显示月份
_monthRecords: Map<DateTime, EmotionRecord>  // 月度情绪数据
_selectedImage: File?                  // 选中图片
_progress: double                      // 处理进度 (0.0~1.0)
_currentStep: String                   // 当前步骤文案
_recognizedEmotion: Emotion?           // AI 识别的情绪
_extractedFeatures: PetFeatures?       // AI 提取的特征
_generatedStickerPath: String?         // 贴纸路径/URL
_isProcessing: bool
_usedFallback: bool                    // 是否使用了 fallback
_permissionError: String?              // 权限错误信息
```

---

### 5. DiaryScreen（日记本）

**ViewModel**: `DiaryViewModel`

**密码验证流程（`initState` 触发）**：

```
DiaryPasswordService.needsPasswordVerification()
  └─ 需要验证 → showDialog(DiaryPasswordDialog)
       ├─ 验证通过 → markEntered() → _isVerified = true → 展示内容
       └─ 验证失败 / 取消 → Navigator.pop()（直接关闭日记页）
```

**通过验证后的交互**：

| 交互元素 | 操作 | 数据流 |
|---------|------|--------|
| AppBar 右侧菜单 → "清空所有日记" | 点击 → 确认对话框 → 确认 | 删除 SharedPreferences('diary_entries') → `vm.loadData()` → SnackBar |
| PageView 左右滑动 | 滑动 | `vm.jumpToIndex(index)` → `_currentIndex` 更新 |
| 左翻页箭头 | 点击 | `vm.previousPage()` → `_currentIndex--` |
| 右翻页箭头 | 点击 | `vm.nextPage()` → `_currentIndex++` |
| 日记图片（横向滚动） | 滚动浏览 | 纯展示：优先读 `imageUrls`（网络 URL），fallback `imagePath`（本地文件） |
| "升级会员"按钮（锁定页） | 点击 | `UpgradeDialog.show()` |
| "重试"按钮（错误态） | 点击 | `vm.loadData()` |

**数据加载流程**：

```
loadData()
  ├─ _currentPet = PetRepository.getCurrentPet()
  │
  ├─ 尝试服务端：
  │   ├─ GET /api/mengyu/diaries?petId=XXX&limit=30&offset=0
  │   │   返回: { diaries: [{id, date, ...}] }
  │   └─ for each diary:
  │       GET /api/mengyu/diaries/:diaryId
  │       返回: imageList（动态合并 pet_photos + diary.imageList）
  │
  └─ 服务端失败 → fallback：
      DiaryRepository.getRecentEntries(limit: 30)
      └─ SharedPreferences('diary_entries')

访问控制 (_applyEntryAccessRules):
  会员用户: isLocked = false（全部可读）
  免费用户: index ≥ 3 → isLocked = true

自动生成日记 (_autoGenerateRecentDiariesIfNeeded, init 时触发):
  条件: isPremium && canGenerateAI()
  遍历: 今天 / 昨天 / 前天
  ├─ 该日期无日记内容 → 触发生成
  │   POST /api/mengyu/ai/diary/auto-generate
  │   body: {petId, date}
  │   返回: {generated, diaryId, date, contentLength}
  └─ 成功 → QuotaService.recordAIUsage() → 刷新配额 → UI 更新
```

**ViewModel 状态字段**：

```dart
_entries: List<DiaryEntry>     // 日记列表
_currentIndex: int             // 当前页索引
_isLoading: bool
_errorMessage: String?
_currentPet: Pet?
_quotaStatus: QuotaStatus      // AI 配额（用于判断是否显示升级提示）
```

---

### 6. ProfileScreen（宠物档案）

**ViewModel**: `ProfileViewModel`

| 交互元素 | 操作 | 数据流 |
|---------|------|--------|
| 下拉刷新 | 下拉 | `vm.refresh()` → 重新加载档案 |
| "编辑"按钮 | 点击 | `_showEditDialog()` → EditProfileDialog → `vm.updateProfile(updatedPet)` → 本地保存 + async API 同步 |
| 右上角同步按钮（非同步中） | 点击 | `vm.manualSync()` → POST 同步宠物档案 |
| 右上角同步按钮（同步中） | 点击 | 不可点（显示 loading 圈） |
| "创建档案"（空态） | 点击 | `pushReplacementNamed('/profile-setup')` |
| "重试"按钮（错误态） | 点击 | `vm.refresh()` |

**展示字段**：主人称呼 / 生日 + 年龄 / 性别（图标 + 颜色编码）/ 性格（emoji + 名称）/ 上次同步时间

**ViewModel 状态字段**：

```dart
_pet: Pet?
_isLoading: bool
_errorMessage: String?
_isSyncing: bool
_lastSyncTime: DateTime?
```

---

### 7. SettingsScreen（设置）

**ViewModel**: `SettingsViewModel`

| 交互元素 | 操作 | 数据流 |
|---------|------|--------|
| "后台宠物识别"开关 | Toggle | `vm.toggleBackgroundScan(value)` → iOS MethodChannel enable/disable |
| "请求权限"按钮（未授权） | 点击 | `vm.requestPermission()` → 系统权限对话框 |
| "去设置"按钮（权限被拒） | 点击 | `AppSettings.openAppSettings()` |
| "立即扫描"按钮 | 点击 | `vm.performManualScan()` → 同 HomeViewModel 扫描流程 |
| 扫描结果 ListTile | 点击 | `_showScanResults()` → BottomSheet 展示 List\<ScanResult\> |
| "重置扫描记录" | 点击 → 确认对话框 → 确认 | `vm.resetProcessedPhotos()` → 清除已处理照片记录 → SnackBar |

**ViewModel 状态字段**：

```dart
_isBackgroundScanEnabled: bool
_permissionStatus: PhotoPermissionStatus
_lastScanTime: DateTime?
_isLoading: bool
_isScanning: bool
_errorMessage: String?
_lastScanResults: List<ScanResult>
```

---

## 三、所有交互点汇总表

| 交互元素 | 所在页面 | 操作 | 回调方法 | 最终数据流向 |
|---------|---------|------|---------|------------|
| "开始使用"按钮 | Onboarding | 点击 | — | → /profile-setup |
| 头像选择区域 | ProfileSetup | 点击 | `pickPhoto()` | ImagePicker → File |
| 宠物名输入框 | ProfileSetup | 输入 | `setName()` | ViewModel 状态 |
| 主人称呼选项 | ProfileSetup | 点击 | `setOwnerNickname()` | ViewModel 状态 |
| 生日选择 | ProfileSetup | 点击 | `setBirthday()` | DatePicker → DateTime |
| 性别选择 | ProfileSetup | 点击 | `setGender()` | ViewModel 状态 |
| 性格选择 | ProfileSetup | 点击 | `setPersonality()` | ViewModel 状态 |
| "完成设置"按钮 | ProfileSetup | 点击 | `submitProfile()` | → SharedPreferences + API + /home |
| 日历热区 | Home | 点击 | `_navigateToCalendar()` | → CalendarScreen |
| 相框热区 | Home | 点击 | `_navigateToProfile()` | → ProfileScreen |
| 抽屉把手 | Home | 点击 | `vm.toggleDrawer()` | 背景图切换 |
| 日记本热区 | Home（抽屉打开） | 点击 | `vm.markDiaryViewed()` | → DiaryScreen |
| 设置图标 | Home | 点击 | — | → /settings |
| 返回按钮 | Calendar | 点击 | `Navigator.pop()` | — |
| "上月"按钮 | Calendar | 点击 | `changeMonth(-1)` | 月度数据重新加载 |
| "下月"按钮 | Calendar | 点击 | `changeMonth(+1)` | 月度数据重新加载 |
| 日期格子 | Calendar | 点击 | `_handleDayTap()` | BottomSheet(情绪选择) |
| 情绪选择按钮 | Calendar(BottomSheet) | 点击 | `updateRecordEmotion()` | → SharedPreferences + API |
| FAB "+" | Calendar | 点击 | `_handleAddEmotion()` | ImagePicker → AI → SharedPreferences + API |
| PageView 滑动 | Diary | 滑动 | `vm.jumpToIndex()` | `_currentIndex` 更新 |
| 左翻页箭头 | Diary | 点击 | `vm.previousPage()` | `_currentIndex--` |
| 右翻页箭头 | Diary | 点击 | `vm.nextPage()` | `_currentIndex++` |
| "清空日记"菜单 | Diary | 点击 → 确认 | — | 删除 SharedPreferences + reload |
| "升级会员"按钮 | Diary（锁定页） | 点击 | — | UpgradeDialog |
| 编辑按钮 | Profile | 点击 | `_showEditDialog()` | → SharedPreferences + API |
| 同步按钮 | Profile | 点击 | `manualSync()` | → API |
| 下拉刷新 | Profile | 下拉 | `vm.refresh()` | 重新加载 |
| 后台扫描开关 | Settings | Toggle | `toggleBackgroundScan()` | iOS MethodChannel |
| 请求权限按钮 | Settings | 点击 | `requestPermission()` | 系统权限对话框 |
| 去设置按钮 | Settings | 点击 | — | AppSettings |
| 立即扫描按钮 | Settings | 点击 | `performManualScan()` | iOS MethodChannel + 上传流程 |
| 扫描结果 ListTile | Settings | 点击 | `_showScanResults()` | BottomSheet |
| 重置扫描记录 | Settings | 点击 → 确认 | `resetProcessedPhotos()` | 清除记录 |

---

## 四、API 接口汇总

**基础配置**：

| 环境 | Base URL |
|-----|---------|
| Dev | `http://172.20.10.6:3000`（可配置） |
| Staging | `https://staging-api.petdiary.com` |
| Prod | `https://api.petdiary.com` |

- Auth：`token` header（自动附加）
- 普通超时：10s；上传超时：30s

**接口列表**：

| 端点 | 方法 | 调用方 | 用途 |
|-----|------|--------|------|
| `/api/mengyu/pet/list` | GET | ProfileViewModel | 拉取宠物列表 |
| `/api/mengyu/diaries?petId=&limit=&offset=` | GET | DiaryViewModel | 日记列表 |
| `/api/mengyu/diaries/:diaryId` | GET | DiaryViewModel | 日记详情（含动态 imageList） |
| `/api/mengyu/pets/profile` | POST | ProfileSetupVM / ProfileVM | 创建 / 同步宠物档案 |
| `/api/mengyu/emotions/save` | POST | CalendarViewModel | 保存情绪记录 |
| `/api/mengyu/emotions/month?year=&month=&petId=` | GET | CalendarViewModel | 月度情绪数据（含贴纸 URL） |
| `/api/mengyu/image/list/upload` | POST (multipart) | ScanUploadService | 批量上传照片（含去重） |
| `/api/mengyu/ai/sticker/generate` | POST (multipart) | StickerGenerationService | AI 情绪识别 + 贴纸生成 |
| `/api/mengyu/ai/diary/generate` | POST (multipart) | DiaryGenerationService | AI 日记生成（含图片） |
| `/api/mengyu/ai/diary/auto-generate` | POST | DiaryViewModel | 自动生成最近日记 |

---

## 五、本地存储键值表

| SharedPreferences Key | 数据类型 | 所属 Repository | 用途 |
|----------------------|---------|----------------|------|
| `current_pet` | JSON (Pet) | PetRepository | 当前宠物档案 |
| `emotion_records` | JSON List (EmotionRecord) | EmotionRepository | 情绪记录历史 |
| `diary_entries` | JSON List (DiaryEntry) | DiaryRepository | 日记条目 |
| `app_photos` | JSON List (AppPhoto) | AppPhotoRepository | 应用内照片 |
| `quota_status` | JSON (QuotaStatus) | QuotaRepository | AI 配额状态 |
| `api_token` | String | ApiConfig | API token（内存缓存 + 持久化） |
| `last_diary_view_date` | String (YYYY-MM-DD) | HomeViewModel | 上次查看日记时间（用于新日记红点） |

---

## 六、核心数据模型

### Pet（宠物）

```dart
id: String              // 设备 ID（用作 petId）
name: String            // 宠物名
species: String         // "cat" / "dog"（API 字段 type: cat=2, dog=1）
breed: String?
profilePhotoPath: String?
birthday: DateTime?
ownerNickname: String?  // API 字段: ownerTitle
gender: PetGender?      // male(1) / female(2) / unknown
personality: PetPersonality?  // 6 种性格
createdAt: DateTime
```

### EmotionRecord（情绪记录）

```dart
id: String
petId: String
date: DateTime
originalPhotoPath: String?  // 原始照片本地路径
aiEmotion: Emotion          // AI 识别情绪
aiConfidence: double
aiFeatures: PetFeatures     // species, breed, color, pose
selectedEmotion: Emotion    // 用户最终选择的情绪
stickerUrl: String?         // 贴纸 URL（可能是网络 URL 或本地路径）
createdAt: DateTime
updatedAt: DateTime
```

### DiaryEntry（日记条目）

```dart
id: String
petId: String
date: DateTime
content: String
imagePath: String?          // 本地图片（fallback）
imageUrls: List<String>     // 网络图片 URL 列表（优先）
isLocked: bool              // 访问控制（免费用户第 3 篇后锁定）
isAiGenerated: bool         // 是否 AI 生成
emotionRecordId: String?
createdAt: DateTime
```

### QuotaStatus（AI 配额）

```dart
freeQuotaTotal: int         // 免费总配额
freeQuotaUsed: int          // 已使用
freeQuotaRemaining: int     // 剩余
isPremium: bool             // 是否会员
premiumExpiry: DateTime?
canGenerateAI: bool         // getter：会员 || remaining > 0
```

---

## 七、iOS 原生通信层

### MethodChannel（`com.petdiary/background_scan`）

| 方法名 | 方向 | 说明 |
|-------|------|------|
| `performManualScan` | Flutter → iOS | 触发扫描，fire-and-forget，返回 `bool` |
| `requestPhotoPermission` | Flutter → iOS | 请求相册权限 |
| `enableBackgroundScan` | Flutter → iOS | 启用后台扫描 |
| `disableBackgroundScan` | Flutter → iOS | 禁用后台扫描 |

### EventChannel（`com.petdiary/photo_scan_events`）

| 事件类型 | 字段 | 说明 |
|---------|------|------|
| `scanResult` | `assetId, tempFilePath, animalType, confidence, creationDate, latitude, longitude` | 每发现一张宠物照片推送一条 |
| `scanComplete` | `totalFound: int` | 扫描结束哨兵事件 |

---

## 八、服务端（Mock Server）概览

**文件**：`mock-server/server.js`
**持久化**：`mock-server/db.json`（collections: `pets`, `photos`, `pet_photos`, `diaries`, `users`）
**文件上传**：`mock-server/uploads/`
**AI 集成**：Gemini 2.5 Flash Vision（需 `.env` 中配置 `GEMINI_API_KEY`）

**关键业务逻辑**：

- 图片上传去重：`assetId + petId` 联合唯一
- 上传后自动合并：`pet_photos.imageList` → 对应日期 `diary.imageList`
- 占位日记：上传新日期图片时，若该日期无日记则自动创建
- 日记详情接口动态合并：每次请求实时将 `pet_photos` 合并进 `imageList` 返回

---

## 九、缺口与待确认项

> 以下为梳理过程中发现的潜在缺口，上架前需团队确认

| # | 问题 | 影响模块 | 优先级 |
|---|------|---------|--------|
| 1 | ProfileSetup 没有**宠物种类（猫/狗）选择器**，但 Pet 模型有 `species` 字段 | 客户端 / UI | 高 |
| 2 | 日记密码的**设置入口**未找到（只有读取 / 验证逻辑） | 客户端 / UI | 高 |
| 3 | 会员升级 `UpgradeDialog` 展示后缺少**实际支付 / 订阅流程** | 客户端 / 服务端 | 高 |
| 4 | AI 日记生成目前只有**自动触发**，无用户手动触发入口 | 客户端 / UI | 中 |
| 5 | ProfileScreen 相框点击进入完整档案页，是否符合设计意图（相框应仅展示头像/简介？） | UI / 客户端 | 中 |
| 6 | `DiaryGenerationService.generateSmart()` 手动生成流程在 UI 中无暴露 | 客户端 | 中 |
| 7 | 错误码 `403` 配额耗尽后的 Upgrade 引导 UI 是否已完整实现 | 客户端 / UI | 中 |
| 8 | `prod` 环境 base URL 为占位地址，上架前需替换为真实域名 | 服务端 / 客户端 | 高 |

---

*文档由 Claude Code 自动生成，基于代码库快照（2026-02-24）*
