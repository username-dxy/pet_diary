# Pet Diary MCP 服务器配置

## 什么是 MCP？

**MCP (Model Context Protocol)** 是一个开放协议，允许 Claude Code 连接外部工具和服务，扩展其能力边界。

### MCP vs Skills 对比

| 特性 | Skills | MCP |
|------|--------|-----|
| **配置位置** | `.claude/skills/*.md` | `.claude/mcp.json` |
| **实现方式** | Markdown 指令 | 外部进程/服务 |
| **作用范围** | 项目级提示 | 系统级工具集成 |
| **适用场景** | 快速命令、模板、指导 | 数据库、API、系统命令 |
| **复杂度** | 简单 | 复杂 |

**简单记忆**：
- **Skills**: 项目内的"速记本"（快速指令）
- **MCP**: 项目外的"工具箱"（强大集成）

---

## 已配置的 MCP 服务器

### 1. filesystem
**功能**: 安全的文件系统访问
**来源**: 官方 MCP 服务器
**使用**: 自动可用，无需手动调用

### 2. git
**功能**: Git 版本控制操作
**来源**: 官方 MCP 服务器
**使用**: 自动可用，支持 commit、branch、diff 等操作

### 3. flutter-tools (自定义)
**功能**: Flutter 项目专用工具集
**来源**: 本项目自定义
**文件**: `.claude/mcp-servers/flutter-tools.js`

**可用工具**:
- `flutter_test` - 运行测试
- `flutter_analyze` - 代码分析
- `pub_get` - 获取依赖
- `dart_format` - 格式化代码
- `check_mvvm` - 检查 MVVM 架构

---

## 如何使用 MCP 工具

### 方法 1: 自动调用（推荐）
Claude Code 会在需要时自动调用相应的 MCP 工具，你只需要自然地描述需求：

```
"运行所有测试"
→ Claude 自动调用 flutter_test

"帮我分析代码质量"
→ Claude 自动调用 flutter_analyze

"检查 home 模块的架构"
→ Claude 自动调用 check_mvvm
```

### 方法 2: 显式请求
明确要求使用某个工具：

```
"使用 flutter_test 运行 test/widget_test.dart"
"使用 check_mvvm 检查 calendar 功能"
"使用 dart_format 格式化所有代码"
```

---

## Flutter Tools 详细说明

### flutter_test
运行 Flutter 单元测试或集成测试

**参数**:
- `test_path` (可选): 测试文件路径，默认运行所有测试

**示例**:
```javascript
// 运行所有测试
{ "test_path": "test" }

// 运行特定测试
{ "test_path": "test/data/models/pet_test.dart" }

// 运行带覆盖率的测试
{ "test_path": "test --coverage" }
```

**Claude Code 使用**:
```
"运行所有测试"
"测试 pet 模型"
"运行测试并生成覆盖率报告"
```

---

### flutter_analyze
分析 Flutter 代码质量，检查语法错误、警告和最佳实践违规

**参数**: 无

**示例**:
```javascript
{}
```

**Claude Code 使用**:
```
"分析代码质量"
"检查有没有代码问题"
"运行 flutter analyze"
```

---

### pub_get
获取和更新 Flutter 项目依赖

**参数**: 无

**示例**:
```javascript
{}
```

**Claude Code 使用**:
```
"获取依赖"
"更新 packages"
"运行 pub get"
```

---

### dart_format
格式化 Dart 代码，使其符合 Dart 官方风格指南

**参数**:
- `path` (可选): 要格式化的文件或目录，默认格式化整个项目

**示例**:
```javascript
// 格式化整个项目
{ "path": "." }

// 格式化特定文件
{ "path": "lib/presentation/screens/home/home_screen.dart" }

// 格式化目录
{ "path": "lib/data/models" }
```

**Claude Code 使用**:
```
"格式化所有代码"
"格式化 home_screen.dart"
"格式化 models 目录"
```

---

### check_mvvm
检查 MVVM 架构文件结构是否完整

**参数**:
- `feature` (必需): 功能模块名称

**示例**:
```javascript
{ "feature": "home" }
{ "feature": "calendar" }
{ "feature": "diary" }
```

**检查项**:
- ✅ Screen: `lib/presentation/screens/{feature}/{feature}_screen.dart`
- ✅ ViewModel: `lib/presentation/screens/{feature}/{feature}_viewmodel.dart`
- ✅ Widgets Dir: `lib/presentation/screens/{feature}/widgets/`
- ✅ Model: `lib/data/models/{feature}.dart`
- ✅ Repository: `lib/data/repositories/{feature}_repository.dart`

**Claude Code 使用**:
```
"检查 home 模块的架构"
"验证 calendar 的 MVVM 结构"
"check mvvm diary"
```

---

## 配置文件位置

### 主配置
**文件**: `/Users/00ffff/pet_diary/.claude/mcp.json`

```json
{
  "mcpServers": {
    "flutter-tools": {
      "command": "node",
      "args": ["/Users/00ffff/pet_diary/.claude/mcp-servers/flutter-tools.js"],
      "env": {
        "FLUTTER_PROJECT_ROOT": "/Users/00ffff/pet_diary"
      }
    }
  }
}
```

### 服务器实现
**文件**: `/Users/00ffff/pet_diary/.claude/mcp-servers/flutter-tools.js`

---

## 测试 MCP 服务器

### 方法 1: 直接测试服务器
```bash
# 进入项目目录
cd /Users/00ffff/pet_diary

# 手动运行服务器（调试用）
node .claude/mcp-servers/flutter-tools.js
```

### 方法 2: 在 Claude Code 中测试
```
"使用 flutter_test 运行测试"
"使用 check_mvvm 检查 home"
```

---

## 调试和日志

### 查看 MCP 日志
MCP 服务器的日志输出到 stderr，在 Claude Code 中可见。

### 手动调试
```bash
# 设置环境变量
export FLUTTER_PROJECT_ROOT=/Users/00ffff/pet_diary

# 运行服务器（会监听 stdin）
node .claude/mcp-servers/flutter-tools.js

# 发送测试请求（JSON-RPC 格式）
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | node .claude/mcp-servers/flutter-tools.js
```

---

## 添加更多 MCP 服务器

### 官方服务器列表

安装命令：
```bash
# SQLite 数据库
npm install -g @modelcontextprotocol/server-sqlite

# PostgreSQL 数据库
npm install -g @modelcontextprotocol/server-postgresql

# Web 抓取
npm install -g @modelcontextprotocol/server-web-fetch

# GitHub 集成
npm install -g @modelcontextprotocol/server-github
```

配置示例（添加到 `mcp.json`）：
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

---

## 常见问题

### Q: MCP 服务器没有启动？
**A**: 检查：
1. Node.js 是否安装：`node --version`
2. 文件权限：`chmod +x .claude/mcp-servers/flutter-tools.js`
3. 配置文件路径是否正确

### Q: MCP 工具调用失败？
**A**: 查看：
1. Flutter 是否在 PATH 中：`which flutter`
2. 项目路径是否正确：`echo $FLUTTER_PROJECT_ROOT`
3. 检查 Claude Code 日志

### Q: 如何禁用某个 MCP 服务器？
**A**: 在 `mcp.json` 中注释或删除对应条目

### Q: MCP vs Skills，我应该用哪个？
**A**:
- 需要执行系统命令、访问外部服务 → 用 MCP
- 需要快速指令、模板、项目指导 → 用 Skills
- 两者可以配合使用

---

## 扩展建议

### 可以添加的功能

1. **测试覆盖率报告生成**
2. **性能分析工具集成**
3. **自动化部署脚本**
4. **依赖版本检查和更新**
5. **代码复杂度分析**
6. **国际化文件管理**
7. **图片资源优化**

### 创建新工具的步骤

1. 在 `flutter-tools.js` 中添加新工具定义
2. 实现工具的执行逻辑
3. 更新此 README 文档
4. 在 Claude Code 中测试

---

## 最佳实践

1. **保持服务器轻量**: 不要在一个服务器中塞太多功能
2. **详细的错误信息**: 帮助快速定位问题
3. **环境变量管理**: 敏感信息用环境变量
4. **日志输出**: 使用 `console.error()` 输出调试信息
5. **超时处理**: 为长时间运行的命令设置超时

---

**最后更新**: 2026-01-26
