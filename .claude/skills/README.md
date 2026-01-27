# Pet Diary Skills 使用指南

## 已安装的 Skills

### 1. MVVM Checker (`mvvm-checker.md`)
**功能**: 验证代码是否符合 Pet Diary 的 MVVM + Repository 架构规范

**触发方式**:
- 关键词: `check-mvvm`
- 自然语言: "检查 MVVM 架构", "验证架构规范"

**使用示例**:
```
# 检查 ViewModel
"check-mvvm HomeViewModel"

# 检查整个模块
"check-mvvm home 模块的架构"

# 检查特定文件
"check-mvvm lib/presentation/screens/home/home_viewmodel.dart"
```

**检查内容**:
- ViewModel: ChangeNotifier, 状态管理, notifyListeners
- Model: Equatable, JSON 序列化, copyWith
- Repository: SharedPreferences, CRUD 操作
- Screen: Provider 结构, 状态处理
- Widget: StatelessWidget, 参数设计
- Service: 业务逻辑分离

---

### 2. New Feature Generator (`new-feature.md`)
**功能**: 自动生成完整的功能模块（Model + Repository + ViewModel + Screen）

**触发方式**:
- 关键词: `new-feature`
- 自然语言: "创建新功能", "生成功能模块"

**使用示例**:
```
# 生成完整功能
"new-feature UserSettings"

# 指定需求生成
"new-feature 通知中心，包含通知列表和设置"

# 生成简单功能
"new-feature 关于页面"
```

**生成内容**:
- Model: `lib/data/models/`
- Repository: `lib/data/repositories/`
- ViewModel: `lib/presentation/screens/{feature}/`
- Screen: `lib/presentation/screens/{feature}/`
- Widgets: `lib/presentation/screens/{feature}/widgets/`
- Route: 添加到 `main.dart`

---

## 触发 Skills 的方法

### 方法 1: 使用触发关键词
直接在消息中使用 skill 的 trigger 关键词：
```
"check-mvvm 我的代码"
"new-feature 用户中心"
```

### 方法 2: 自然语言描述
用自然语言描述你的需求，Claude 会自动识别合适的 skill：
```
"帮我检查这个 ViewModel 是否符合 MVVM 规范"
"我想创建一个新的设置页面"
```

### 方法 3: 显式调用（最清晰）
明确指定要使用的 skill：
```
"使用 mvvm-checker skill 检查 HomeViewModel"
"使用 new-feature skill 生成一个搜索功能"
```

---

## 查看所有可用 Skills

```bash
# 列出所有 skills
ls .claude/skills/

# 查看 skill 内容
cat .claude/skills/mvvm-checker.md
```

---

## 创建自定义 Skill

### 步骤 1: 创建 Markdown 文件
在 `.claude/skills/` 目录下创建 `.md` 文件

### 步骤 2: 添加 Frontmatter
```markdown
---
name: "Your Skill Name"
description: "What this skill does"
trigger: "trigger-keyword"
---

# Skill Content

Your instructions and templates here...
```

### 步骤 3: 编写 Skill 内容
- 提供清晰的指导
- 包含代码模板
- 说明使用场景
- 添加示例

### 步骤 4: 测试 Skill
在对话中使用触发词测试

---

## Skill 最佳实践

### ✅ 推荐做法:
- 使用描述性的名称和触发词
- 提供具体的代码模板
- 包含项目特定的约定
- 添加 checklist 和验证规则
- 使用占位符 (如 `{{directory}}`, `{{date}}`)

### ❌ 避免:
- 过于通用的指导（应该针对项目）
- 重复 CLAUDE.md 中已有的信息
- 触发词太常见（容易误触发）
- 缺少实际示例

---

## 项目特定的 Skill 建议

基于 Pet Diary 的特点，可以创建以下 Skills:

### 1. AI Pipeline Helper ✨
- 触发词: `ai-pipeline`
- 功能: 指导 AI 三模型流程开发
- 内容: 情绪识别、特征提取、贴纸生成的最佳实践

### 2. Debug Helper 🐛
- 触发词: `debug`
- 功能: 快速诊断常见问题
- 内容: SharedPreferences、Provider、状态管理调试

### 3. Test Generator 🧪
- 触发词: `generate-tests`
- 功能: 生成单元测试和 Widget 测试
- 内容: Model、Repository、ViewModel 测试模板

### 4. Widget Library 🎨
- 触发词: `widget-lib`
- 功能: 常用 Widget 模板库
- 内容: 按钮、卡片、对话框等组件模板

---

## 实战示例

### 示例 1: 检查代码规范
```
User: "check-mvvm CalendarViewModel"

Claude: 根据 MVVM Checker:
✅ 继承 ChangeNotifier
✅ 私有状态变量
✅ 公开 Getter
⚠️ 建议添加错误状态处理
```

### 示例 2: 生成新功能
```
User: "new-feature Notifications 通知中心"

Claude: 正在生成通知中心功能模块...
1. 创建 Notification 模型
2. 创建 NotificationRepository
3. 创建 NotificationsViewModel
4. 创建 NotificationsScreen
5. 注册路由
```

### 示例 3: 自然语言
```
User: "帮我检查 DiaryViewModel 的架构是否正确"

Claude: [自动触发 mvvm-checker]
正在检查 DiaryViewModel...
```

---

## 调试 Skills

### Skill 没有触发？
1. 检查触发词拼写是否正确
2. 使用显式调用: "使用 xxx skill"
3. 查看 skill 文件是否存在: `ls .claude/skills/`
4. 检查 frontmatter 格式是否正确

### Skill 触发不准确？
1. 使用更具体的触发词
2. 使用显式调用而非关键词
3. 在 skill 中添加更详细的 description

---

## 贡献 Skills

如果你创建了有用的 Skill:

1. 确保遵循命名规范
2. 添加完整的文档和示例
3. 在此 README 中更新列表
4. 提交到版本控制

---

**最后更新**: 2026-01-26
