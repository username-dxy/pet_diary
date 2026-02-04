# Mock Server 连接测试结果

测试时间: 2026-02-04
测试环境: Development

---

## ✅ 服务器状态

**地址**: http://192.168.3.129:3000
**状态**: 运行正常
**环境变量**: GEMINI_API_KEY 已配置

**当前数据:**
- 宠物: 4 个
- 照片: 3 张（photos 集合）
- 宠物照片: 3 张（pet_photos 集合）
- 日记: 10 篇

---

## ✅ API 端点测试

### 1. 基础连接
```bash
curl http://192.168.3.129:3000/
```
**结果**: ✅ 返回端点列表

### 2. Token 认证
```bash
curl -H "token: test123" http://192.168.3.129:3000/api/chongyu/pet/list
```
**结果**: ✅ 返回 4 个宠物
- test_pet_001 (橘猫 - 测试小猫)
- test_pet_002 (萨摩耶 - 小白)
- 51b1c795-... (Ty)
- dde10bd0-... (dd)

### 3. 日记列表
```bash
curl -H "token: test123" "http://192.168.3.129:3000/api/chongyu/diary/list?petId=test_pet_001"
```
**结果**: ✅ 返回 6 篇日记（2026-01-26 至 2026-01-31）

### 4. 宠物照片查询
```bash
curl -H "token: test123" "http://192.168.3.129:3000/api/chongyu/pet/photos?petId=test_pet_001"
```
**结果**: ✅ 返回空数组（test_pet_001 暂无上传的照片）

---

## 🔍 日记数据结构验证

示例日记（test_diary_001）包含:
- ✅ `id`, `petId`, `date`, `title`, `content`
- ✅ `imagePath` (主图)
- ✅ `imageList` (照片列表数组)
- ✅ `emotion` (情绪值)
- ✅ `isLocked`, `createdAt`, `syncedAt`

**imageList 示例:**
```json
[
  "https://placekitten.com/400/300",
  "https://placekitten.com/401/301"
]
```

---

## 📱 客户端集成测试步骤

### 步骤 1: 验证客户端配置

在 App 启动后，添加日志检查:
```dart
// 在 HomeViewModel.loadData() 开始处
final token = await ApiConfig.getToken();
final baseUrl = ApiConfig.baseUrl;
debugPrint('🔧 [Connection] Token: $token');
debugPrint('🔧 [Connection] Base URL: $baseUrl');
```

**期望输出:**
```
🔧 [Connection] Token: <device-id or pet-id>
🔧 [Connection] Base URL: http://192.168.3.129:3000
```

### 步骤 2: 测试宠物列表 API

添加测试代码:
```dart
// 在任意 ViewModel 中
final petService = PetApiService();
final response = await petService.getPetList();
debugPrint('🐾 [Test] Pet list: ${response.success}');
if (response.success) {
  debugPrint('   Found ${response.data.petList.length} pets');
  for (var pet in response.data.petList) {
    debugPrint('   - ${pet.nickName} (${pet.petId})');
  }
} else {
  debugPrint('   Error: ${response.errorMessage}');
}
```

**期望输出:**
```
🐾 [Test] Pet list: true
   Found 4 pets
   - 测试小猫 (test_pet_001)
   - 小白 (test_pet_002)
   - Ty (51b1c795-...)
   - dd (dde10bd0-...)
```

### 步骤 3: 测试日记列表 API

```dart
final diaryService = DiaryApiService();
final response = await diaryService.getDiaryList('test_pet_001');
debugPrint('📔 [Test] Diary list: ${response.success}');
if (response.success) {
  debugPrint('   Found ${response.data.diaryList.length} diaries');
  for (var diary in response.data.diaryList) {
    debugPrint('   - ${diary.date}: ${diary.title}');
  }
}
```

**期望输出:**
```
📔 [Test] Diary list: true
   Found 6 diaries
   - 2026-01-31: 对新玩具充满好奇
   - 2026-01-30: 睡了一整天
   ...
```

### 步骤 4: 测试日记详情（包含 imageList）

```dart
final response = await diaryService.getDiaryDetail(
  petId: 'test_pet_001',
  diaryId: 'test_diary_001',
);
debugPrint('📷 [Test] Diary detail: ${response.success}');
if (response.success) {
  final detail = response.data;
  debugPrint('   Date: ${detail.date}');
  debugPrint('   Title: ${detail.title}');
  debugPrint('   Images: ${detail.imageList.length}');
  for (var url in detail.imageList) {
    debugPrint('     - $url');
  }
}
```

**期望输出:**
```
📷 [Test] Diary detail: true
   Date: 2026-01-26
   Title: 阳光下打滚的一天
   Images: 2
     - https://placekitten.com/400/300
     - https://placekitten.com/401/301
```

### 步骤 5: 测试照片上传

创建测试照片并上传:
```dart
final imageService = ImageApiService();
final item = ImageUploadItem(
  filePath: '/path/to/test/photo.jpg',
  assetId: 'test-asset-001',
  petId: 'test_pet_001',
  date: '2026-02-04',
);
final response = await imageService.uploadImages([item]);
debugPrint('📤 [Test] Upload: ${response.success}');
if (response.success) {
  debugPrint('   Uploaded: ${response.data.uploaded}');
  debugPrint('   Duplicates: ${response.data.duplicates}');
}
```

**期望输出:**
```
📤 [Test] Upload: true
   Uploaded: 1
   Duplicates: 0
```

---

## 🔧 客户端日志关键词

监听以下日志确认流程:

**扫描流程:**
```
[HomeScan] No pet, skip scan
[HomeScan] No photo permission
[HomeScan] 正在扫描相册...
[HomeScan] Scan complete: N found
[HomeScan] No pet photos found
```

**上传流程:**
```
[HomeScan] 正在上传照片...
[HomeScan] 正在上传 1/N 天...
[ScanUpload] Uploaded assetId for date
[ScanUpload] Upload failed for assetId: error
[HomeScan] Upload complete: N photos
```

**API 请求:**
```
[ApiClient] GET http://192.168.3.129:3000/api/chongyu/pet/list
[ApiClient] Response [200]: {"success":true,...}
[ApiClient] UPLOAD http://192.168.3.129:3000/api/chongyu/image/list/upload
[ApiClient] 网络连接失败
[ApiClient] 请求超时
[ApiClient] 未授权，请重新登录
```

---

## ⚠️ 常见错误及解决方案

### 1. 网络连接失败
**日志**: `[ApiClient] 网络连接失败`
**原因**:
- 服务器未启动
- IP 地址不正确
- 设备不在同一局域网

**解决**:
```bash
# 检查服务器是否运行
ps aux | grep "node server.js"

# 重启服务器
cd mock-server && npm start

# 检查本机 IP
ifconfig | grep "inet "
```

### 2. 401 未授权
**日志**: `[ApiClient] Response [401]`
**原因**: Token 未设置或无效

**解决**:
```dart
// 检查 token
final token = await ApiConfig.getToken();
debugPrint('Current token: $token');

// 重新设置 token
await ApiConfig.setToken('test123');
```

### 3. 上传失败
**日志**: `[ScanUpload] Upload failed`
**可能原因**:
- 文件不存在
- 文件格式不支持
- 文件大小超过 10MB

**解决**:
- 检查文件路径是否正确
- 确认格式为 JPEG/PNG/HEIC
- 检查压缩是否成功

### 4. 日记 imageList 为空
**原因**: 该日期没有上传的照片

**验证**:
```bash
# 查询宠物照片
curl -H "token: test123" \
  "http://192.168.3.129:3000/api/chongyu/pet/photos?petId=YOUR_PET_ID&date=2026-02-04"
```

---

## 📊 数据库验证命令

```bash
# 查看所有宠物
cat mock-server/db.json | jq '.pets[] | {id, name: .name}'

# 查看所有日记
cat mock-server/db.json | jq '.diaries[] | {id, petId, date, title}'

# 查看所有 pet_photos
cat mock-server/db.json | jq '.pet_photos[] | {petId, date, assetId, url}'

# 查看特定日记的 imageList
cat mock-server/db.json | jq '.diaries[] | select(.id == "test_diary_001") | .imageList'

# 查看上传统计
curl http://192.168.3.129:3000/api/v1/stats | jq '.data'
```

---

## ✅ 下一步操作

1. **在 App 中添加连接测试日志**
   - 在 HomeViewModel.loadData() 添加 token 和 baseUrl 日志
   - 运行 App，查看日志确认配置正确

2. **测试扫描和上传流程**
   - 确保有照片权限
   - 观察扫描日志
   - 检查上传是否成功

3. **验证日记数据**
   - 查看日记列表是否加载
   - 检查日记详情的 imageList
   - 确认照片 URL 可访问

4. **如有问题**
   - 查看 Flutter 日志中的 [ApiClient] 标记
   - 检查服务器控制台日志
   - 使用 curl 命令手动测试 API
   - 查看 mock-server/db.json 数据结构

---

## 📝 测试检查清单

- [x] 服务器启动成功
- [x] Token 认证工作正常
- [x] 宠物列表 API 可访问
- [x] 日记列表 API 可访问
- [x] 日记详情包含 imageList
- [x] 照片查询 API 可访问
- [ ] 客户端成功连接服务器
- [ ] 照片上传成功
- [ ] 自动创建日记成功
- [ ] 日记 imageList 动态更新成功

---

**服务器状态**: ✅ 运行中
**监听地址**: 192.168.3.129:3000
**环境**: Development
**GEMINI_API_KEY**: 已配置
