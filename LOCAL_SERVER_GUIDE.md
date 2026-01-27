# 本地服务端测试指南

## 快速开始（5 分钟）

### 1. 安装 Node.js

如果还没安装，请访问: https://nodejs.org/

验证安装:
```bash
node --version  # 应显示 v18+ 或更高
npm --version   # 应显示 9+ 或更高
```

---

### 2. 配置 Mock Server

**进入服务器目录**:
```bash
cd mock-server
```

**查看配置文件** `.env`:
```bash
# 服务器配置
PORT=3000
HOST=0.0.0.0        # 0.0.0.0 允许局域网访问

# 存储配置
DB_FILE=db.json
UPLOAD_DIR=uploads

# 日志配置
LOG_LEVEL=info      # debug | info | warn | error
VERBOSE=false       # 详细日志开关
```

**自定义配置**（可选）:
```bash
# 复制配置模板
cp .env.example .env

# 编辑配置文件
vim .env
```

---

### 3. 启动 Mock Server

```bash
# 安装依赖（首次运行）
npm install

# 启动服务器
npm start
```

看到以下输出表示成功:
```
🚀 =====================================
   Pet Diary Mock Server 已启动
   监听地址: 0.0.0.0:3000
   本地访问: http://localhost:3000
=====================================

📊 当前数据统计:
   宠物: 0
   照片: 0
   日记: 0

💡 API端点:
   POST /api/v1/pets/profile - 同步宠物档案
   POST /api/v1/upload/profile-photo - 上传头像
   ...

⚙️  配置:
   数据库文件: db.json
   上传目录: uploads
   日志级别: info
```

---

### 4. 验证服务器

**方法 1**: 浏览器访问

打开 http://localhost:3000

应该看到 API 端点列表。

**方法 2**: 使用 curl

```bash
# 测试健康检查
curl http://localhost:3000

# 测试统计接口
curl http://localhost:3000/api/v1/stats
```

---

## 配置 Flutter App

### 1. 设置 API 环境

编辑 `lib/main.dart`:

```dart
import 'package:pet_diary/config/api_config.dart';

void main() {
  // 开发环境使用本地 Mock Server
  ApiConfig.setEnvironment(Environment.development);

  runApp(const MyApp());
}
```

### 2. 配置 iOS HTTP 访问

已在 `ios/Runner/Info.plist` 配置 localhost 例外（仅开发环境）:

```xml
<key>NSAppTransportSecurity</key>
<dict>
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

⚠️ **生产环境必须移除此配置并使用 HTTPS**

### 3. 运行 Flutter App

```bash
flutter run
```

---

## API 端点说明

### 宠物档案

**同步宠物档案**

```http
POST /api/v1/pets/profile
Content-Type: application/json

{
  "id": "pet_123",
  "name": "小橘",
  "species": "cat",
  "breed": "橘猫",
  "ownerNickname": "主人",
  "birthday": "2020-05-01",
  "gender": "male",
  "personality": "playful",
  "profilePhotoPath": "/path/to/photo.jpg"
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "petId": "pet_123",
    "syncedAt": "2026-01-27T10:00:00.000Z"
  },
  "message": "同步成功"
}
```

---

**获取宠物档案**

```http
GET /api/v1/pets/{petId}/profile
```

**响应**:
```json
{
  "success": true,
  "data": {
    "id": "pet_123",
    "name": "小橘",
    ...
  }
}
```

---

### 照片上传

**上传头像照片**

```http
POST /api/v1/upload/profile-photo
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
    "fileSize": 102400,
    "mimeType": "image/jpeg"
  }
}
```

---

**上传普通照片**

```http
POST /api/v1/upload/photo
Content-Type: multipart/form-data

photo: <file>
```

---

### 日记

**创建日记**

```http
POST /api/v1/diaries
Content-Type: application/json

{
  "id": "diary_123",
  "petId": "pet_123",
  "date": "2026-01-27",
  "content": "今天玩得很开心",
  "imagePath": "/path/to/image.jpg",
  "isLocked": false
}
```

---

**获取日记列表**

```http
GET /api/v1/diaries?petId=pet_123&limit=30&offset=0
```

---

**获取日记详情**

```http
GET /api/v1/diaries/{diaryId}
```

---

### 统计信息

**获取服务器统计**

```http
GET /api/v1/stats
```

**响应**:
```json
{
  "success": true,
  "data": {
    "pets": 1,
    "photos": 5,
    "diaries": 10,
    "users": 0,
    "uptime": 3600.5,
    "memory": { ... }
  }
}
```

---

## 高级配置

### 修改端口

**方式 1**: 编辑 `.env` 文件
```bash
PORT=8080
```

**方式 2**: 使用环境变量
```bash
PORT=8080 npm start
```

---

### 启用详细日志

**编辑 `.env`**:
```bash
LOG_LEVEL=debug
VERBOSE=true
```

**或使用命令行**:
```bash
VERBOSE=true npm start
```

---

### 局域网访问（真机测试）

**第 1 步**: 确认 HOST 配置

`.env` 文件:
```bash
HOST=0.0.0.0  # 允许局域网访问
```

**第 2 步**: 获取电脑 IP

```bash
# macOS
ipconfig getifaddr en0

# 输出示例: 192.168.1.100
```

**第 3 步**: 真机运行 Flutter

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000
```

---

## 数据管理

### 查看数据库

```bash
# 格式化输出
cat mock-server/db.json | python3 -m json.tool

# 或使用 jq（如果已安装）
cat mock-server/db.json | jq .
```

---

### 实时监控数据变化

```bash
# 实时显示数据库内容
watch -n 2 'cat mock-server/db.json | python3 -m json.tool'
```

---

### 清空数据库

```bash
# 备份当前数据
cp mock-server/db.json mock-server/db.backup.json

# 清空数据
echo '{"pets":[],"photos":[],"diaries":[],"users":[]}' > mock-server/db.json

# 重启服务器
```

---

### 导出/导入测试数据

**导出**:
```bash
cp mock-server/db.json test-data-$(date +%Y%m%d).json
```

**导入**:
```bash
cp test-data-20260127.json mock-server/db.json
```

---

## 故障排查

### 问题 1: 端口被占用

**错误**: `Error: listen EADDRINUSE: address already in use :::3000`

**解决**:
```bash
# 查找占用端口的进程
lsof -i :3000

# 终止进程
kill <PID>

# 或修改端口
PORT=8080 npm start
```

---

### 问题 2: npm install 失败

**可能原因**: 网络问题或 Node.js 版本过低

**解决**:
```bash
# 检查 Node.js 版本
node --version  # 需要 v18+

# 清理缓存
npm cache clean --force

# 重新安装
npm install
```

---

### 问题 3: Flutter 无法连接

**检查清单**:

1. Mock Server 是否运行？
   ```bash
   curl http://localhost:3000
   ```

2. 端口是否正确？
   - iOS 模拟器: `localhost:3000`
   - Android 模拟器: `10.0.2.2:3000`
   - 真机: `<电脑IP>:3000`

3. iOS Info.plist 是否配置？
   ```bash
   cat ios/Runner/Info.plist | grep -A 10 "NSAppTransportSecurity"
   ```

4. Flutter 配置是否正确？
   - 检查 `lib/main.dart` 是否调用 `ApiConfig.setEnvironment(Environment.development)`
   - 检查 `lib/config/api_config.dart` 的 `_developmentUrl`

---

### 问题 4: 上传的照片无法访问

**检查**:
```bash
# 确认上传目录存在
ls -la mock-server/uploads/

# 检查文件权限
ls -la mock-server/uploads/profiles/
```

**确保 server.js 正确配置静态文件服务**:
```javascript
app.use('/uploads', express.static(UPLOAD_DIR));
```

---

## 开发工具

### 推荐工具

- **Postman** / **Insomnia**: API 测试工具
- **Charles** / **Proxyman**: 网络抓包工具
- **Paw**: macOS API 开发工具
- **curl**: 命令行测试

### 使用 Postman 测试

1. 导入 API 集合（如果有 `postman_collection.json`）
2. 或手动创建请求：
   - Base URL: `http://localhost:3000`
   - 测试 POST `/api/v1/pets/profile`
   - 测试 POST `/api/v1/upload/profile-photo` (设置 body 为 form-data)

---

## 自动化测试

### 创建测试脚本

`mock-server/test-all.sh`:
```bash
#!/bin/bash

echo "🧪 测试 Mock Server API"
echo ""

# 1. 健康检查
echo "1. 健康检查..."
curl -s http://localhost:3000 | python3 -m json.tool

# 2. 统计信息
echo ""
echo "2. 获取统计..."
curl -s http://localhost:3000/api/v1/stats | python3 -m json.tool

# 3. 创建宠物
echo ""
echo "3. 创建宠物档案..."
curl -s -X POST http://localhost:3000/api/v1/pets/profile \
  -H "Content-Type: application/json" \
  -d '{"id":"test_123","name":"测试猫","species":"cat"}' \
  | python3 -m json.tool

echo ""
echo "✅ 测试完成"
```

**运行**:
```bash
chmod +x mock-server/test-all.sh
./mock-server/test-all.sh
```

---

## 生产环境迁移

本地 Mock Server 仅用于开发测试。生产环境建议：

1. **后端框架**:
   - Node.js: Express / NestJS
   - Python: FastAPI / Django
   - Go: Gin / Fiber

2. **数据库**:
   - PostgreSQL / MySQL (关系型)
   - MongoDB (文档型)

3. **云存储**:
   - 阿里云 OSS
   - 七牛云
   - AWS S3

4. **部署**:
   - Docker 容器化
   - K8s 编排
   - 云服务器（阿里云 ECS、腾讯云 CVM）

详见 `PRODUCTION_ROADMAP.md`

---

## 相关文档

- `API_INTEGRATION_COMPLETE.md` - API 集成完整说明
- `PRODUCTION_ROADMAP.md` - 生产环境部署规划
- `PROJECT_GUIDE.md` - 项目整体架构

---

**最后更新**: 2026-01-27
**Mock Server 版本**: 1.0.0
**支持的 API**: Profile、Photo、Diary、Stats
