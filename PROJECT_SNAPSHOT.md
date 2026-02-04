# Pet Diary 快速了解与进度快照

最后更新: 2026-02-03

## 一句话定位
一款 Flutter 宠物日记应用，主打宠物档案 + 日记 + 情绪贴纸，并带有 AI 识别和游戏化房间场景，当前以本地 Mock Server + SharedPreferences 为主。

## 快速运行
- 安装依赖: `flutter pub get`
- 启动 App: `flutter run`
- 启动 Mock Server:
  - `cd mock-server`
  - `npm install`
  - `npm start`

## 架构速览
- 架构: MVVM + Repository + Provider
- 本地存储: SharedPreferences
- 网络层: `api_config.dart` + `ApiClient`（支持 dev/staging/prod 和 token）
- 远端接口: `mock-server/`，数据落在 `mock-server/db.json`

## 主要模块
- 引导与档案
  - Onboarding -> Profile Setup -> Home
- Home 房间场景
  - 日历墙、抽屉（日记）、相框（资料）
- 日历与 AI 处理
  - 情绪识别 -> 特征提取 -> 贴纸生成
- 日记
  - 翻页展示、相册、密码保护、EXIF 信息

## 关键数据流
- View -> ViewModel -> Repository/Service -> Model -> `notifyListeners()`
- Diary: 先从 API 拉取，失败回退到本地仓库
- Photo Scan: iOS 原生扫描 -> EventChannel -> 上传 -> 服务器合并到 diary.imageList

## 当前代码状态（基于代码与文档）
- 入口路由会根据是否已有宠物档案决定跳转（`/home` 或 `/onboarding`）。
- 设备级稳定 ID 已加入（通过 SharedPreferences 持久化）。
- token 恢复逻辑在启动时完成（使用 petId 作为 dev token）。
- Mock Server 已有完整 API 结构，支持上传图片与合并日记图片列表。

## 已完成（来自 README/CHANGELOG）
- 基础 UI 框架
- 宠物档案创建
- 日记记录功能
- 照片管理
- 本地数据持久化
- API 服务集成与配置化（2026-01-27）

## 进行中/待完成
- 云端数据同步
- 用户认证系统
- 多设备同步
- 数据导出与社交分享
- 清理未使用代码、完善测试

## 关键入口/文件
- App 入口: `lib/main.dart`
- API 配置: `lib/config/api_config.dart`
- Home: `lib/presentation/screens/home/`
- 日记: `lib/presentation/screens/diary/`
- 日历: `lib/presentation/screens/calendar/`
- Profile Setup: `lib/presentation/screens/profile_setup/`
- Mock Server: `mock-server/server.js`

## 常用指令
- 静态检查: `flutter analyze`
- 测试: `flutter test`
- 单测文件: `flutter test test/widget_test.dart`

## 继续工作时的建议检查点
- 启动时的路由与 token 恢复流程是否符合业务预期
- 日记列表与图片列表的合并逻辑（API 与本地回退）
- iOS Photo Scan 的 EventChannel 流程是否稳定

