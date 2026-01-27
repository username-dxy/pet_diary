# ✅ API 服务集成完成

## 概述

Pet Diary 已完成 API 服务集成，采用**全局配置管理**方式，支持开发/预发布/生产环境无缝切换。

## 核心架构

### 1. 全局配置系统 ⭐ NEW

**文件**: `lib/config/api_config.dart`

```dart
class ApiConfig {
  static Environment _environment = Environment.development;

  // 设置环境
  static void setEnvironment(Environment env) {
    _environment = env;
  }

  // 获取当前环境的 API Base URL
  static String get baseUrl { ... }

  // 支持环境变量覆盖
  // flutter run --dart-define=API_BASE_URL=http://your-server
}

enum Environment {
  development,   // 本地 Mock Server
  staging,       // 预发布环境
  production,    // 生产环境
}
```

**特性**:
- ✅ 支持环境变量配置（`--dart-define`）
- ✅ 可配置超时时间
- ✅ 开发环境自动启用调试日志
- ✅ 生产环境禁用敏感日志

---

### 2. ApiProfileService 实现

**文件**: `lib/domain/services/profile_service.dart`

```dart
class ApiProfileService implements ProfileService {
  final String baseUrl;

  // 构造函数使用全局配置
  ApiProfileService({String? baseUrl})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  @override
  Future<ProfileSyncResult> syncProfile(Pet pet) {
    // POST /api/v1/pets/profile
    // 使用 ApiConfig.timeoutSeconds
  }

  @override
  Future<String> uploadProfilePhoto(File photo) {
    // POST /api/v1/upload/profile-photo
    // 使用 ApiConfig.uploadTimeoutSeconds
  }

  @override
  Future<Pet?> fetchProfile(String petId) {
    // GET /api/v1/pets/{petId}/profile
  }
}
```

**关键改进**:
- ✅ 移除硬编码 URL
- ✅ 使用全局配置的超时时间
- ✅ 保留平台自动检测（仅开发环境）
- ✅ 支持自定义 baseUrl 覆盖

---

### 3. Mock Server 配置化

**配置文件**: `mock-server/.env`

```bash
# 服务器配置
PORT=3000
HOST=0.0.0.0  # 允许局域网访问

# 数据库配置
DB_FILE=db.json
UPLOAD_DIR=uploads

# 日志配置
LOG_LEVEL=info
VERBOSE=false
```

**server.js 改进**:
- ✅ 使用 dotenv 加载配置
- ✅ 端口、主机可配置
- ✅ 日志级别可控制
- ✅ 支持局域网访问（真机测试）

---

## 使用方法

### 开发环境（本地测试）

**第 1 步**: 启动 Mock Server

```bash
cd mock-server
npm install  # 首次运行需要安装 dotenv
npm start
```

**第 2 步**: 配置 Flutter App

在 `lib/main.dart` 中设置环境：

```dart
import 'package:pet_diary/config/api_config.dart';

void main() {
  // 开发环境使用本地 Mock Server
  ApiConfig.setEnvironment(Environment.development);

  runApp(const MyApp());
}
```

**第 3 步**: 运行 App

```bash
flutter run
```

---

### 真机测试（局域网）

**第 1 步**: 获取电脑 IP

```bash
# macOS
ipconfig getifaddr en0

# 示例输出: 192.168.1.100
```

**第 2 步**: 使用环境变量运行

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000
```

或修改 `api_config.dart` 的 `_developmentUrl`：

```dart
static String get _developmentUrl {
  return const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.100:3000',  // 改为你的 IP
  );
}
```

---

### 生产环境

**第 1 步**: 修改 `lib/main.dart`

```dart
void main() {
  // 生产环境
  ApiConfig.setEnvironment(Environment.production);

  runApp(const MyApp());
}
```

**第 2 步**: 配置生产 URL

方式 A - 修改 `api_config.dart`：

```dart
static String get _productionUrl {
  return const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.petdiary.com',  // 你的生产 API
  );
}
```

方式 B - 使用环境变量编译：

```bash
flutter build ios --dart-define=API_BASE_URL=https://api.petdiary.com
```

---

## 测试验证

### 功能测试

**1. 创建宠物档案**

1. 运行 App 进入 Profile Setup 页
2. 填写完整信息并提交
3. 查看 Flutter 控制台日志：

```
[API] 同步宠物档案到服务器...
[API] URL: http://localhost:3000/api/v1/pets/profile
[API] ✅ 同步成功
```

4. 查看 Mock Server 控制台：

```
✅ 创建宠物档案: 测试小猫
```

5. 验证数据持久化：

```bash
cat mock-server/db.json
```

**2. 编辑档案**

1. 进入 Profile 页
2. 点击编辑按钮
3. 修改信息并保存
4. 验证同步成功

---

## 配置参考

### API 配置选项

| 配置项 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| API Base URL | `API_BASE_URL` | 根据环境 | API 服务器地址 |
| 请求超时 | `API_TIMEOUT` | 10秒 | 普通请求超时 |
| 上传超时 | `UPLOAD_TIMEOUT` | 30秒 | 文件上传超时 |

### 环境对比

| 环境 | Base URL | 日志 | 用途 |
|------|----------|------|------|
| Development | `http://localhost:3000` | 详细 | 本地开发 |
| Staging | `https://staging-api.petdiary.com` | 中等 | 测试验证 |
| Production | `https://api.petdiary.com` | 精简 | 正式上线 |

---

## Mock Server 配置

### 配置文件说明

`.env` 文件配置项：

```bash
# 端口配置
PORT=3000              # 服务端口

# 主机配置
HOST=0.0.0.0          # 0.0.0.0 允许局域网访问
                       # localhost 仅本地访问

# 存储配置
DB_FILE=db.json       # 数据库文件名
UPLOAD_DIR=uploads    # 上传目录

# 日志配置
LOG_LEVEL=info        # debug | info | warn | error
VERBOSE=false         # 是否显示详细日志
```

### 启动选项

```bash
# 默认配置启动
npm start

# 自定义端口
PORT=8080 npm start

# 仅本地访问
HOST=localhost npm start

# 启用详细日志
VERBOSE=true npm start
```

---

## 故障排查

### 问题 1: "Connection refused"

**原因**: Mock Server 未运行

**解决**:
```bash
# 检查服务状态
curl http://localhost:3000

# 启动服务
cd mock-server && npm start
```

---

### 问题 2: 真机无法连接

**原因**: 使用了 localhost 而非局域网 IP

**解决**:
```bash
# 1. 获取电脑 IP
ipconfig getifaddr en0

# 2. 使用环境变量运行
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000
```

---

### 问题 3: iOS 不允许 HTTP 连接

**原因**: ATS 安全策略

**解决**: 已在 `ios/Runner/Info.plist` 配置 localhost 例外（仅开发环境）

生产环境必须使用 HTTPS。

---

## 关键文件清单

### Flutter 端

```
lib/
├── config/
│   └── api_config.dart          ✅ 全局配置（新建）
├── domain/services/
│   └── profile_service.dart     ✅ 使用配置（已更新）
└── main.dart                    ✅ 环境初始化（已更新）
```

### 服务端

```
mock-server/
├── .env                         ✅ 配置文件（新建）
├── .env.example                 ✅ 配置模板（新建）
├── server.js                    ✅ 使用配置（已更新）
└── package.json                 ✅ 添加 dotenv（已更新）
```

---

## 生产环境 Checklist

- [ ] 修改 `main.dart` 设置 `Environment.production`
- [ ] 配置生产环境 API URL
- [ ] 切换到 HTTPS
- [ ] 移除 iOS Info.plist 的 HTTP 例外
- [ ] 添加用户认证（JWT）
- [ ] 配置 CDN 加速
- [ ] 添加错误监控
- [ ] 性能监控
- [ ] 证书校验

详见 `PRODUCTION_ROADMAP.md`

---

## 下一步

### 立即可做

1. **测试创建档案功能**
   ```bash
   flutter run
   # 填写表单 → 提交 → 查看日志
   ```

2. **验证数据同步**
   ```bash
   cat mock-server/db.json
   ```

### 短期优化（1 周）

- 添加同步状态 UI 指示器
- 实现自动重试机制
- 添加离线模式提示

### 中期目标（2-4 周）

- 集成云存储（阿里云 OSS）
- 实现用户登录系统
- 配置生产环境域名
- 添加性能监控

---

## 相关文档

- `LOCAL_SERVER_GUIDE.md` - Mock Server 完整使用指南
- `PRODUCTION_ROADMAP.md` - 生产部署规划
- `PROJECT_GUIDE.md` - 项目整体架构说明

---

**最后更新**: 2026-01-27
**配置方式**: ✅ 全局可配置
**硬编码清理**: ✅ 已完成
**生产就绪度**: 🟡 开发测试阶段（需完成生产 Checklist）
