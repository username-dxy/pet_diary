# 日记流程检查总结

分支: `check-diary-scan-flow`
检查时间: 2026-02-04

---

## ✅ 已完成检查

### 1. Mock Server 连接测试

**状态**: ✅ 正常
**地址**: http://192.168.3.129:3000
**端口**: 3000

**测试结果**:
- ✅ 服务器运行正常
- ✅ Token 认证工作
- ✅ 宠物列表 API 可访问（4 个宠物）
- ✅ 日记列表 API 可访问（10 篇日记）
- ✅ 照片查询 API 可访问
- ✅ 日记详情包含 imageList

**测试文档**: `mock-server/CONNECTION_TEST_RESULT.md`

### 2. Gemini API 连接测试

**状态**: ✅ 正常
**API Key**: 已配置并验证

**测试结果**:
- ✅ 基础文本生成正常
- ✅ 视觉识别正常（识别出三花猫）
- ✅ 情绪分析正常（curious, 0.85 confidence）
- ✅ 结构化 JSON 输出正常

**识别示例**:
```json
{
  "analysis": {
    "emotion": "curious",
    "confidence": 0.85
  },
  "pet_features": {
    "species": "cat",
    "breed": "Domestic Shorthair",
    "primary_color": "calico"
  }
}
```

**测试脚本**:
- `mock-server/test_gemini_simple.js` - 基础连接测试
- `mock-server/test_gemini_vision.js` - 视觉识别测试

**测试文档**: `mock-server/GEMINI_API_TEST_GUIDE.md`

---

## 📋 日记流程架构

### 完整流程图

```
用户打开 App
    │
    ▼
HomeViewModel.loadData()
    │
    ├─ 加载宠物 profile
    ├─ 加载今日贴纸
    └─ _triggerScanOnStartup()
         │
         ├─ 1. 检查照片权限
         │
         ├─ 2. 监听 EventChannel（iOS 扫描结果流）
         │
         ├─ 3. 触发扫描 performManualScan()
         │      │
         │      ▼
         │   iOS PhotoScannerService
         │      │ (Vision 框架识别猫/狗)
         │      │
         │      ▼
         │   EventChannel 流式返回:
         │      - {type: "scanResult", assetId, petId, ...}
         │      - {type: "scanComplete", totalFound: N}
         │
         ├─ 4. 等待 scanComplete 事件（超时 5 分钟）
         │
         ├─ 5. 按天聚合 ScanUploadService.aggregateByDay()
         │      │
         │      ▼
         │   Map<date, List<ScanResult>>
         │
         └─ 6. 逐天压缩上传
              │
              ├─ PhotoCompressionService.compressPhoto()
              │    └─ 压缩到 1080p, JPEG 80%
              │
              └─ ImageApiService.uploadImages()
                   │
                   ▼
              POST /api/mengyu/image/list/upload
                   │
                   ├─ 字段: petId_N, date_N, assetId_N
                   │
                   ▼
              服务端处理:
                   │
                   ├─ 1. 按 assetId + petId 去重
                   ├─ 2. 存入 pet_photos 集合
                   ├─ 3. 自动更新/创建对应日期的 diary
                   └─ 4. 返回 {uploaded, duplicates}
                        │
                        ▼
              日记生成完成
                   │
                   ├─ diary.imageList 自动包含当天所有照片
                   └─ 客户端可查询日记详情
```

### 关键组件

| 组件 | 职责 | 文件位置 |
|------|------|----------|
| HomeViewModel | 触发扫描上传 | `lib/presentation/screens/home/home_viewmodel.dart:88-200` |
| BackgroundScanService | iOS 扫描桥接 | `lib/domain/services/background_scan_service.dart` |
| ScanUploadService | 聚合、压缩、上传 | `lib/domain/services/scan_upload_service.dart` |
| PhotoCompressionService | 照片压缩 | `lib/domain/services/photo_compression_service.dart` |
| ImageApiService | 上传 API 调用 | `lib/data/data_sources/remote/image_api_service.dart` |
| DiaryApiService | 日记查询 | `lib/data/data_sources/remote/diary_api_service.dart` |
| Mock Server | 接收上传、生成日记 | `mock-server/server.js:292-396` |

---

## 🔍 需要检查的客户端问题

### 1. Token 设置验证

在 `HomeViewModel.loadData()` 添加日志：
```dart
final token = await ApiConfig.getToken();
debugPrint('🔧 [Connection] Token: $token');
debugPrint('🔧 [Connection] Base URL: ${ApiConfig.baseUrl}');
```

**期望输出**:
```
🔧 [Connection] Token: <device-id or pet-id>
🔧 [Connection] Base URL: http://192.168.3.129:3000
```

### 2. 扫描流程验证

查找日志关键词：
```
[HomeScan] 正在扫描相册...
[HomeScan] Scan complete: N found
[HomeScan] 正在上传照片...
[HomeScan] 正在上传 1/N 天...
[ScanUpload] Uploaded assetId for date
[HomeScan] Upload complete: N photos
```

### 3. API 请求验证

查找日志关键词：
```
[ApiClient] UPLOAD http://192.168.3.129:3000/api/mengyu/image/list/upload
[ApiClient] Response [200]: {"success":true,"data":{...}}
```

**错误日志**:
```
[ApiClient] Response [401]: 未授权        → Token 未设置
[ApiClient] 网络连接失败                  → 服务器不可达
[ApiClient] 请求超时                      → 照片太大或网络慢
```

---

## 🐛 已知问题和解决方案

### 问题 1: AI 贴纸生成错误（已解决）

**错误**: `❌ AI 贴纸生成失败: Error: Missing GEMINI_API_KEY`

**原因**: 服务器启动时未加载环境变量

**解决**:
1. 确认 `.env` 中有 `GEMINI_API_KEY`
2. 重启 mock server: `npm start`
3. 验证: `node test_gemini_simple.js`

**状态**: ✅ 已解决

### 问题 2: 照片上传后日记无照片（潜在）

**可能原因**:
- 上传时未传递 `petId_N` 和 `date_N` 字段
- 日期格式不正确（应为 `yyyy-MM-dd`）
- 服务端未自动创建日记

**验证方法**:
```bash
# 查看 pet_photos 集合
cat mock-server/db.json | jq '.pet_photos'

# 查看日记的 imageList
cat mock-server/db.json | jq '.diaries[] | {date, imageList}'
```

**解决**: 检查 `ImageUploadItem` 构建是否包含所有字段

---

## 📊 当前数据状态

### Mock Server 数据

```bash
# 查看统计
curl http://192.168.3.129:3000/api/v1/stats | jq '.data'
```

**结果**:
- 宠物: 4 个
- 照片: 3 张（photos 集合）
- 宠物照片: 3 张（pet_photos 集合）
- 日记: 10 篇

### 测试数据

**宠物**:
- test_pet_001 (测试小猫 - 橘猫)
- test_pet_002 (小白 - 萨摩耶)
- 51b1c795-... (Ty)
- dde10bd0-... (dd)

**日记**:
- test_pet_001 有 6 篇日记（2026-01-26 至 2026-01-31）
- 每篇日记包含 imageList 数组

**示例日记**:
```json
{
  "id": "test_diary_001",
  "petId": "test_pet_001",
  "date": "2026-01-26",
  "title": "阳光下打滚的一天",
  "content": "今天测试小猫很开心...",
  "imagePath": "https://placekitten.com/400/300",
  "emotion": 1,
  "imageList": [
    "https://placekitten.com/400/300",
    "https://placekitten.com/401/301"
  ]
}
```

---

## 🎯 下一步操作

### 1. 客户端调试

添加详细日志以确认：
- [x] Token 是否正确设置
- [ ] 扫描是否正常触发
- [ ] 照片是否成功上传
- [ ] 日记是否包含照片

**建议添加日志的位置**:
- `home_viewmodel.dart:58` - loadData 开始
- `scan_upload_service.dart:66` - 上传前
- `api_client.dart:106` - 上传请求

### 2. 功能测试

在 App 中测试完整流程：
1. ✅ 创建宠物 profile
2. ✅ 触发照片扫描
3. ⏳ 验证照片上传成功
4. ⏳ 查看日记列表
5. ⏳ 打开日记详情查看照片

### 3. API 集成测试

创建单元测试：
```dart
// test/integration/api_test.dart
test('照片上传并创建日记', () async {
  // 1. 上传照片
  final imageService = ImageApiService();
  final response = await imageService.uploadImages([...]);
  expect(response.success, true);

  // 2. 查询日记
  final diaryService = DiaryApiService();
  final diary = await diaryService.getDiaryDetail(...);
  expect(diary.data.imageList, isNotEmpty);
});
```

### 4. 性能优化

- 批量上传多张照片（当前逐张上传）
- 缓存压缩结果（避免重复压缩）
- 后台异步上传（不阻塞 UI）

---

## 📚 相关文档

已创建的测试文档：

1. **API 连接测试**: `mock-server/CONNECTION_TEST_RESULT.md`
   - 服务器状态检查
   - API 端点测试
   - 客户端集成测试步骤

2. **Gemini API 测试**: `mock-server/GEMINI_API_TEST_GUIDE.md`
   - API Key 配置
   - 文本生成测试
   - 视觉识别测试
   - 常见问题排查

3. **API 测试指南**: `API_TEST_GUIDE.md`
   - 完整 API 路径列表
   - curl 测试命令
   - 数据库检查命令

---

## ✅ 检查清单

服务端：
- [x] Mock Server 运行正常
- [x] Token 认证工作
- [x] 照片上传 API 可访问
- [x] 日记查询 API 可访问
- [x] Gemini API 连接正常
- [x] AI 情绪分析工作

客户端（待验证）：
- [ ] Token 设置正确
- [ ] 扫描流程触发
- [ ] 照片上传成功
- [ ] 日记包含照片
- [ ] imageList 显示正常

---

## 🔗 快速命令

```bash
# 重启 mock server
cd mock-server && npm start

# 测试服务器连接
curl http://192.168.3.129:3000/

# 测试 Gemini API
node mock-server/test_gemini_simple.js

# 查看数据库
cat mock-server/db.json | jq '.diaries[] | {date, imageList}'

# 手动上传测试
curl -H "token: test123" \
  -F "image=@test.jpg" \
  -F "petId_0=test_pet_001" \
  -F "date_0=2026-02-04" \
  -F "assetId_0=test-001" \
  http://192.168.3.129:3000/api/mengyu/image/list/upload
```

---

**状态**: 服务端连接正常，可以开始客户端调试
**分支**: `check-diary-scan-flow`
**下一步**: 在客户端添加日志，运行 App 验证完整流程
