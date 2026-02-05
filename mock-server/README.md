# Pet Diary Mock Server

本地测试服务器，用于测试完整的网络交互流程。

## 快速开始

### 1. 安装依赖

```bash
cd mock-server
npm install
```

### 2. 启动服务器

```bash
npm start
```

或使用自动重启（开发模式）：

```bash
npm run dev
```

### 3. 验证服务

打开浏览器访问: http://localhost:3000

应该看到API端点列表。

---

## API文档

### 宠物管理

#### 同步宠物档案

```http
POST /api/chongyu/pets/profile
Content-Type: application/json

{
  "id": "pet_123",
  "name": "小橘",
  "species": "cat",
  "breed": "橘猫",
  "ownerNickname": "主人",
  "birthday": "2020-05-01T00:00:00.000Z",
  "gender": "male",
  "personality": "playful",
  "profilePhotoPath": "/path/to/photo.jpg",
  "createdAt": "2024-01-26T10:00:00.000Z"
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "petId": "pet_123",
    "syncedAt": "2024-01-26T10:00:00.000Z"
  },
  "message": "同步成功"
}
```

#### 获取宠物档案

```http
GET /api/chongyu/pets/{petId}/profile
```

---

### 照片上传

#### 上传头像照片

```http
POST /api/chongyu/upload/profile-photo
Content-Type: multipart/form-data

photo: <file>
```

**响应**:
```json
{
  "success": true,
  "data": {
    "url": "http://localhost:3000/uploads/profiles/abc123.jpg",
    "thumbnailUrl": "http://localhost:3000/uploads/profiles/abc123.jpg",
    "fileSize": 123456,
    "mimeType": "image/jpeg"
  }
}
```

#### 上传普通照片

```http
POST /api/chongyu/upload/photo
Content-Type: multipart/form-data

photo: <file>
```

---

### 日记管理

#### 创建日记

```http
POST /api/chongyu/diaries
Content-Type: application/json

{
  "id": "diary_123",
  "petId": "pet_123",
  "date": "2024-01-26T00:00:00.000Z",
  "content": "今天小橘很开心...",
  "imagePath": "/path/to/photo.jpg",
  "isLocked": false,
  "emotionRecordId": "photo_456",
  "createdAt": "2024-01-26T10:00:00.000Z"
}
```

#### 获取日记列表

```http
GET /api/chongyu/diaries?petId=pet_123&limit=30&offset=0
```

#### 获取日记详情

```http
GET /api/chongyu/diaries/{diaryId}
```

---

### 统计信息

```http
GET /api/chongyu/stats
```

**响应**:
```json
{
  "success": true,
  "data": {
    "pets": 1,
    "photos": 5,
    "diaries": 3,
    "users": 0,
    "uptime": 123.456,
    "memory": {
      "rss": 123456,
      "heapTotal": 123456,
      "heapUsed": 123456
    }
  }
}
```

---

## Flutter客户端集成

### 1. 添加HTTP依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  http: ^1.1.0
```

### 2. 修改ApiProfileService

文件: `lib/domain/services/profile_service.dart`

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ApiProfileService implements ProfileService {
  // 本地服务器地址
  final String baseUrl = 'http://localhost:3000';

  @override
  Future<ProfileSyncResult> syncProfile(Pet pet) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chongyu/pets/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(pet.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProfileSyncResult(
          success: true,
          message: data['message'],
          syncedAt: DateTime.parse(data['data']['syncedAt']),
        );
      } else {
        throw Exception('同步失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  @override
  Future<String> uploadProfilePhoto(File photo) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/chongyu/upload/profile-photo'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('photo', photo.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return json['data']['url'];
      } else {
        throw Exception('上传失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('上传错误: $e');
    }
  }

  @override
  Future<Pet?> fetchProfile(String petId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chongyu/pets/$petId/profile'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Pet.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('获取失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }
}
```

### 3. 切换到API服务

修改 `lib/presentation/screens/profile/profile_viewmodel.dart`:

```dart
ProfileViewModel({
  PetRepository? petRepository,
  ProfileService? profileService,
})  : _petRepository = petRepository ?? PetRepository(),
      // 从Mock改为API服务
      _profileService = profileService ?? ProfileService.api(
        baseUrl: 'http://localhost:3000'
      );
```

### 4. iOS模拟器网络配置

**重要**: iOS模拟器需要允许HTTP访问本地服务器。

修改 `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <!-- 或者只允许localhost -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 5. 测试流程

1. 启动Mock Server:
   ```bash
   cd mock-server && npm start
   ```

2. 启动Flutter App:
   ```bash
   flutter run
   ```

3. 在App中创建宠物档案，查看服务器日志:
   ```
   📝 收到宠物档案同步请求: { name: '小橘', ... }
   ✅ 创建宠物档案: 小橘
   ```

4. 检查数据持久化:
   ```bash
   cat mock-server/db.json
   ```

---

## 数据持久化

服务器会自动将数据保存到 `db.json` 文件中，重启后数据不会丢失。

### 清空数据

```bash
rm mock-server/db.json
rm -rf mock-server/uploads
```

### 查看当前数据

```bash
cat mock-server/db.json | python -m json.tool
```

或访问: http://localhost:3000/api/chongyu/stats

---

## 常见问题

### Q1: 模拟器无法连接localhost

**iOS模拟器**: localhost = 主机的localhost ✅
**Android模拟器**: 使用 `10.0.2.2` 代替 `localhost`

```dart
// Android需要使用特殊IP
final baseUrl = Platform.isAndroid
    ? 'http://10.0.2.2:3000'
    : 'http://localhost:3000';
```

### Q2: 照片上传失败

检查:
1. uploads目录权限
2. 文件大小是否超过10MB
3. 文件格式是否为JPEG/PNG

### Q3: CORS错误

服务器已配置CORS，允许所有域名访问。如果仍有问题，检查请求头。

---

## 下一步

### 增强功能

1. **添加认证**:
   ```javascript
   // JWT token验证中间件
   const jwt = require('jsonwebtoken');

   function authenticateToken(req, res, next) {
     const token = req.headers['authorization'];
     if (!token) return res.status(401).json({ message: '未授权' });

     jwt.verify(token, SECRET_KEY, (err, user) => {
       if (err) return res.status(403).json({ message: 'Token无效' });
       req.user = user;
       next();
     });
   }
   ```

2. **数据库升级**:
   - 使用SQLite: `npm install better-sqlite3`
   - 使用MongoDB: `npm install mongodb`

3. **图片处理**:
   ```bash
   npm install sharp
   ```

   ```javascript
   const sharp = require('sharp');

   // 生成缩略图
   await sharp(req.file.path)
     .resize(200, 200)
     .toFile('uploads/thumbnails/' + filename);
   ```

4. **日志系统**:
   ```bash
   npm install winston
   ```

---

## 生产环境部署

当准备部署到云端时:

1. **环境变量管理**:
   ```bash
   npm install dotenv
   ```

2. **云服务器选择**:
   - 阿里云ECS
   - 腾讯云CVM
   - AWS EC2

3. **域名和HTTPS**:
   - 注册域名
   - 申请SSL证书（Let's Encrypt免费）
   - Nginx反向代理

4. **监控告警**:
   - PM2进程管理
   - 日志收集
   - 性能监控

参考 `PRODUCTION_ROADMAP.md` 获取完整部署指南。
