# 更新日志

## [2026-01-27] - API 配置化重构

### 新增 ✨

- **全局 API 配置系统**
  - 新建 `lib/config/api_config.dart`
  - 支持开发/预发布/生产环境切换
  - 支持环境变量覆盖配置
  - 可配置超时时间

- **Mock Server 配置化**
  - 新建 `mock-server/.env` 配置文件
  - 新建 `mock-server/.env.example` 配置模板
  - 支持端口、主机、日志级别配置
  - 添加 dotenv 依赖

### 改进 🔧

- **移除硬编码**
  - `lib/domain/services/profile_service.dart` 使用全局配置
  - `mock-server/server.js` 使用环境变量配置
  - 所有 URL 和超时时间均可配置

- **代码清理**
  - 注释掉 `lib/pages/api_test_page.dart` 测试路由
  - 删除临时测试文档：
    - `START_HERE.md`
    - `QUICK_START_API_TEST.md`
    - `HOW_TO_ACCESS_API_TEST.md`
    - `VERIFY_HTTP_CONFIG.md`
  - 删除测试脚本：
    - `enable_api_test.sh`
    - `disable_api_test.sh`

- **文档更新**
  - 更新 `README.md` - 添加项目介绍和使用说明
  - 更新 `API_INTEGRATION_COMPLETE.md` - 反映配置化改进
  - 更新 `LOCAL_SERVER_GUIDE.md` - 添加配置说明

### 修复 🐛

- Mock Server 重启以使用新配置
- 修复 curl 代理问题（使用 --noproxy）

### 技术细节

**Flutter 端更改**:
```
lib/
├── config/
│   └── api_config.dart          (新建)
├── domain/services/
│   └── profile_service.dart     (已更新)
├── main.dart                    (已更新)
└── pages/
    └── api_test_page.dart       (路由已注释)
```

**服务端更改**:
```
mock-server/
├── .env                         (新建)
├── .env.example                 (新建)
├── server.js                    (已更新)
└── package.json                 (添加 dotenv)
```

### 使用方法

**设置环境**:
```dart
// lib/main.dart
ApiConfig.setEnvironment(Environment.development);
```

**使用环境变量**:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000
```

**配置 Mock Server**:
```bash
# 编辑 mock-server/.env
PORT=3000
HOST=0.0.0.0
LOG_LEVEL=info
```

### 代码质量

- ✅ Flutter analyze: 0 errors
- ⚠️ 5 warnings (未使用的代码)
- ℹ️ 33 info (代码风格建议)

### 下一步

- [ ] 清理未使用的代码（warnings）
- [ ] 完善单元测试
- [ ] 添加集成测试
- [ ] 准备生产环境部署

---

## [2026-01-26] - API 服务集成

### 新增

- API Profile Service 实现
- Mock Server 创建
- iOS HTTP 配置
- API 测试页面

详见 `API_INTEGRATION_COMPLETE.md`

---

## [2026-01-25] - 用户 Profile 功能

### 新增

- Profile Setup 页面
- 宠物档案管理
- 照片上传
- 日期选择器
- 性别/性格选择

详见 Plan 文档

---

## [更早版本]

- 基础 UI 框架
- 日记功能
- 照片管理
- 本地数据存储
