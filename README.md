# Pet Diary - 宠物日记

一个用 Flutter 开发的宠物日记应用，记录您宠物的每一天。

## 功能特性

- ✅ **宠物档案管理** - 创建和管理宠物的基本信息
  - 上传宠物照片
  - 记录名称、生日、性别、性格
  - 设置主人称呼

- ✅ **日记功能** - 记录宠物的日常点滴
  - 日历视图选择日期
  - 添加照片
  - 文字记录
  - 密码保护私密日记

- ✅ **情绪记录** - 追踪宠物的情绪状态

- ✅ **照片相册** - 管理宠物照片

- ✅ **服务端同步** - 数据云端备份（开发中）

## 技术栈

- **框架**: Flutter 3.x
- **架构**: MVVM + Repository Pattern
- **状态管理**: Provider
- **本地存储**: SharedPreferences
- **网络请求**: http package
- **国际化**: flutter_localizations (中文)

## 快速开始

### 前置要求

- Flutter SDK 3.0+
- Dart 3.0+
- iOS: Xcode 14+
- Android: Android Studio / SDK 33+

### 安装依赖

```bash
flutter pub get
```

### 运行应用

**iOS 模拟器**:
```bash
flutter run
```

**Android 模拟器**:
```bash
flutter run
```

### 启动本地测试服务器

应用支持与本地 Mock Server 通信进行测试：

```bash
# 进入服务器目录
cd mock-server

# 安装依赖（首次运行）
npm install

# 启动服务器
npm start
```

详见 [LOCAL_SERVER_GUIDE.md](./LOCAL_SERVER_GUIDE.md)

## 项目结构

```
lib/
├── config/                    # 全局配置
│   └── api_config.dart       # API 环境配置
├── data/                      # 数据层
│   ├── models/               # 数据模型
│   └── repositories/         # 数据仓库
├── domain/                    # 业务逻辑层
│   └── services/             # 业务服务
├── presentation/              # 表现层
│   ├── screens/              # 页面
│   └── widgets/              # 通用组件
└── main.dart                 # 应用入口

mock-server/                   # 本地测试服务器
├── server.js                 # Express 服务器
├── .env                      # 配置文件
└── db.json                   # JSON 数据库
```

## 配置说明

### API 环境配置

在 `lib/main.dart` 中设置环境：

```dart
import 'package:pet_diary/config/api_config.dart';

void main() {
  // 开发环境（本地 Mock Server）
  ApiConfig.setEnvironment(Environment.development);

  // 生产环境
  // ApiConfig.setEnvironment(Environment.production);

  runApp(const MyApp());
}
```

### 使用环境变量

```bash
# 自定义 API 地址
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000

# 真机测试（需要电脑局域网 IP）
flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3000
```

## 文档

- [PROJECT_GUIDE.md](./PROJECT_GUIDE.md) - 项目架构详细说明
- [API_INTEGRATION_COMPLETE.md](./API_INTEGRATION_COMPLETE.md) - API 集成指南
- [LOCAL_SERVER_GUIDE.md](./LOCAL_SERVER_GUIDE.md) - 本地服务器使用指南
- [PRODUCTION_ROADMAP.md](./PRODUCTION_ROADMAP.md) - 生产环境部署规划

## 开发指南

### 代码检查

```bash
flutter analyze
```

### 运行测试

```bash
flutter test
```

### 清理缓存

```bash
flutter clean
flutter pub get
```

## 功能截图

（待补充）

## 开发路线图

- [x] 基础 UI 框架
- [x] 宠物档案创建
- [x] 日记记录功能
- [x] 照片管理
- [x] 本地数据持久化
- [x] API 服务集成
- [ ] 云端数据同步
- [ ] 用户认证系统
- [ ] 多设备同步
- [ ] 数据导出功能
- [ ] 社交分享功能

## 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 联系方式

项目维护者：[Your Name]

项目链接：[https://github.com/yourusername/pet_diary](https://github.com/yourusername/pet_diary)

## 致谢

- Flutter 团队提供的优秀框架
- 所有贡献者的辛勤付出
