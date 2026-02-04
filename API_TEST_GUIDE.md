# API 连接测试指南

## 服务端配置

**当前配置**
- Base URL: `http://192.168.3.129:3000`
- 环境: Development
- 认证方式: Token header（`token: xxx`）

**启动服务器**
```bash
cd mock-server
npm start
# 或使用 nodemon 自动重载
npm run dev
```

服务器启动后访问 `http://localhost:3000` 可查看所有可用端点。

---

## 客户端使用的 API 路径

### 1. 宠物 API（PetApiService）

#### 获取宠物列表
```bash
curl -H "token: test123" \
  http://192.168.3.129:3000/api/chongyu/pet/list
```
**期望响应:**
```json
{
  "success": true,
  "data": {
    "petList": [
      {
        "petId": "xxx",
        "type": 2,
        "gender": 1,
        "birthday": "2020-01-01",
        "ownerTitle": "主人昵称",
        "avatar": "http://...",
        "nickName": "宠物名",
        "character": "性格",
        "description": "品种"
      }
    ]
  }
}
```

#### 获取宠物详情
```bash
curl -H "token: test123" \
  "http://192.168.3.129:3000/api/chongyu/pet/detail?petId=YOUR_PET_ID"
```

---

### 2. 日记 API（DiaryApiService）

#### 获取日记列表
```bash
curl -H "token: test123" \
  "http://192.168.3.129:3000/api/chongyu/diary/list?petId=YOUR_PET_ID"
```
**期望响应:**
```json
{
  "success": true,
  "data": {
    "diaryList": [
      {
        "diaryId": "xxx",
        "date": "2026-01-30",
        "title": "日记标题",
        "avatar": "http://...",
        "emotion": 1
      }
    ]
  }
}
```

#### 获取日记详情（带照片列表）
```bash
# 通过 diaryId 查询
curl -H "token: test123" \
  "http://192.168.3.129:3000/api/chongyu/pet/detail?petId=YOUR_PET_ID&diaryId=YOUR_DIARY_ID"

# 或通过 date 查询
curl -H "token: test123" \
  "http://192.168.3.129:3000/api/chongyu/pet/detail?petId=YOUR_PET_ID&date=2026-01-30"
```
**期望响应:**
```json
{
  "success": true,
  "data": {
    "date": "2026-01-30",
    "title": "日记标题",
    "avatar": "http://...",
    "emotion": 1,
    "content": "日记内容",
    "imageList": [
      "http://192.168.3.129:3000/uploads/photos/xxx.jpg",
      "http://192.168.3.129:3000/uploads/photos/yyy.jpg"
    ]
  }
}
```

#### 查询日历情绪
```bash
curl -H "token: test123" \
  "http://192.168.3.129:3000/api/chongyu/diary/calendar?petId=YOUR_PET_ID&yearMonth=202601"
```

#### 查询前7天情绪
```bash
curl -H "token: test123" \
  "http://192.168.3.129:3000/api/chongyu/diary/7days?petId=YOUR_PET_ID&date=20260130"
```

---

### 3. 图片上传 API（ImageApiService）

#### 批量上传照片（核心流程）
```bash
curl -H "token: test123" \
  -F "image=@/path/to/photo1.jpg" \
  -F "image=@/path/to/photo2.jpg" \
  -F "petId_0=YOUR_PET_ID" \
  -F "date_0=2026-01-30" \
  -F "assetId_0=asset_001" \
  -F "petId_1=YOUR_PET_ID" \
  -F "date_1=2026-01-30" \
  -F "assetId_1=asset_002" \
  http://192.168.3.129:3000/api/chongyu/image/list/upload
```
**期望响应:**
```json
{
  "success": true,
  "data": {
    "uploaded": 2,
    "duplicates": 0
  }
}
```

**服务端处理逻辑:**
1. 按 `assetId + petId` 去重
2. 存入 `pet_photos` 集合
3. 自动更新/创建对应日期的 diary
4. diary 的 `imageList` 自动包含当天所有照片

#### 查询宠物照片
```bash
# 查询宠物所有照片
curl -H "token: test123" \
  "http://192.168.3.129:3000/api/chongyu/pet/photos?petId=YOUR_PET_ID"

# 查询特定日期照片
curl -H "token: test123" \
  "http://192.168.3.129:3000/api/chongyu/pet/photos?petId=YOUR_PET_ID&date=2026-01-30"
```

---

## 统计与调试 API

### 查看服务器统计
```bash
curl http://192.168.3.129:3000/api/v1/stats
```
**返回:**
- 宠物数量
- 照片数量
- 宠物照片数量（pet_photos）
- 日记数量
- 服务器运行时间

### 查看所有端点
```bash
curl http://192.168.3.129:3000/
```

---

## 客户端测试方法

### 方法1: 在 Flutter App 中测试

1. **检查 token 配置**
```dart
// 在 onboarding 或 settings 中设置 token
await ApiConfig.setToken('test123');
```

2. **测试连接**
在任意 ViewModel 中调用 API:
```dart
final petService = PetApiService();
final response = await petService.getPetList();
if (response.success) {
  print('✅ 连接成功: ${response.data.petList.length} 个宠物');
} else {
  print('❌ 连接失败: ${response.error?.message}');
}
```

### 方法2: 创建测试脚本

在 `test/` 目录下创建连接测试:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_diary/config/api_config.dart';
import 'package:pet_diary/data/data_sources/remote/pet_api_service.dart';

void main() {
  test('API 连接测试', () async {
    // 设置 token
    await ApiConfig.setToken('test123');

    // 测试宠物列表
    final service = PetApiService();
    final response = await service.getPetList();

    expect(response.success, true);
    print('宠物列表: ${response.data?.petList.length ?? 0}');
  });
}
```

运行测试:
```bash
flutter test test/api_connection_test.dart
```

### 方法3: 检查日志

启动 App 并查看日志中的网络请求:
```bash
flutter run -v
```

查找关键词:
- `🌐 API Request:` - 请求发送
- `✅ API Response:` - 成功响应
- `❌ API Error:` - 错误响应

---

## 常见问题排查

### 1. 401 Unauthorized
**原因:** Token 未设置或无效
**解决:**
```dart
await ApiConfig.setToken('test123');
```

### 2. 网络连接失败
**原因:** IP 地址不匹配或服务器未启动
**检查:**
```bash
# 确认服务器运行
curl http://192.168.3.129:3000/

# 检查本机 IP
ifconfig | grep "inet "

# iOS 模拟器使用 localhost
# Android 模拟器使用 10.0.2.2
# 真机使用局域网 IP（如 192.168.3.129）
```

### 3. 照片上传失败
**检查:**
1. 文件大小是否超过 10MB
2. 文件格式是否为 JPEG/PNG/HEIC
3. `petId` 和 `date` 字段是否正确设置
4. 服务器 `uploads/photos/` 目录是否有写权限

### 4. 日记照片列表为空
**原因:** 照片未正确关联到日记
**检查:**
- 上传时是否同时传递了 `petId_N` 和 `date_N` 字段
- 日期格式是否为 `yyyy-MM-dd`
- 查询 `/api/chongyu/pet/photos` 确认照片已存入

---

## 照片扫描流程验证

完整的照片扫描→上传→日记生成流程:

1. **启动扫描（iOS）**
```dart
final scanService = BackgroundScanService();
await scanService.performManualScan();
```

2. **监听扫描结果**
```dart
scanService.scanResultStream.listen((result) {
  print('📷 扫描到照片: ${result.assetId} 宠物ID: ${result.petId}');
});
```

3. **检查上传队列**
查看 `ScanUploadService` 是否聚合了按天分组的照片

4. **验证服务端数据**
```bash
# 查看 pet_photos 集合
curl -H "token: test123" \
  "http://192.168.3.129:3000/api/chongyu/pet/photos?petId=YOUR_PET_ID"

# 查看自动生成的日记
curl -H "token: test123" \
  "http://192.168.3.129:3000/api/chongyu/diary/list?petId=YOUR_PET_ID"

# 查看日记的 imageList
curl -H "token: test123" \
  "http://192.168.3.129:3000/api/chongyu/pet/detail?petId=YOUR_PET_ID&date=2026-01-30"
```

5. **验证去重机制**
上传相同 `assetId + petId` 的照片，确认 `duplicates` 计数增加

---

## 数据库检查

Mock 服务器的数据存储在 `mock-server/db.json`:
```bash
# 查看数据库内容
cat mock-server/db.json | jq

# 查看 pet_photos 集合
cat mock-server/db.json | jq '.pet_photos'

# 查看日记 imageList
cat mock-server/db.json | jq '.diaries[] | {date, imageList}'

# 清空数据库（重新测试）
echo '{"pets":[],"photos":[],"pet_photos":[],"diaries":[],"users":[]}' > mock-server/db.json
```

---

## 性能测试

批量上传性能测试:
```bash
# 创建测试照片
for i in {1..10}; do
  cp test_photo.jpg "test_$i.jpg"
done

# 批量上传
time curl -H "token: test123" \
  -F "image=@test_1.jpg" -F "petId_0=pet1" -F "date_0=2026-01-30" \
  -F "image=@test_2.jpg" -F "petId_1=pet1" -F "date_1=2026-01-30" \
  # ... 更多文件
  http://192.168.3.129:3000/api/chongyu/image/list/upload
```

---

## 建议的测试顺序

1. ✅ 服务器启动检查 → `curl http://192.168.3.129:3000/`
2. ✅ Token 认证测试 → `curl -H "token: test123" .../pet/list`
3. ✅ 宠物列表 API → 验证数据返回
4. ✅ 照片上传 API → 上传 1-2 张测试照片
5. ✅ 日记生成验证 → 检查自动创建的 diary
6. ✅ 日记详情 API → 验证 imageList 包含上传的照片
7. ✅ 去重机制测试 → 重复上传同一照片
8. ✅ 客户端集成测试 → 在 App 中触发扫描和上传

---

## 日志级别配置

修改 `mock-server/.env`:
```env
# 详细日志（显示每个请求）
VERBOSE=true
LOG_LEVEL=debug

# 简洁日志（仅显示重要信息）
VERBOSE=false
LOG_LEVEL=info
```
