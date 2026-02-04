# Mock Server 测试脚本

## 📁 目录结构

```
tests/
├── README.md                      # 本文件
├── test_gemini_simple.js          # Gemini API 基础连接测试
├── test_gemini_vision.js          # Gemini Vision API 视觉识别测试
└── test_gemini_connection.js      # Gemini API 完整测试套件
```

---

## 🧪 测试脚本说明

### 1. test_gemini_simple.js

**用途**: 测试 Gemini API 基础连接和 API Key 有效性

**运行**:
```bash
cd mock-server
node tests/test_gemini_simple.js
```

**测试内容**:
- 验证 GEMINI_API_KEY 配置
- 发送简单文本生成请求
- 检查 API 响应

**期望输出**:
```
✅ 连接成功!
响应: "Hello"
✅ Gemini API 工作正常！
```

---

### 2. test_gemini_vision.js

**用途**: 测试 Gemini Vision API 图片识别和情绪分析

**前置条件**: `uploads/photos/` 目录中需要有测试图片

**运行**:
```bash
cd mock-server
node tests/test_gemini_vision.js
```

**测试内容**:
- 读取测试图片
- 测试图片内容描述
- 测试结构化 JSON 输出（情绪分析）

**期望输出**:
```
📸 使用图片: xxx.png
✅ 成功!
   识别结果: 这是一只三花猫...

📊 分析结果:
   情绪: curious
   置信度: 0.85
   物种: cat
   品种: Domestic Shorthair
```

---

### 3. test_gemini_connection.js

**用途**: 完整测试套件（文本 + 视觉 + 结构化输出）

**运行**:
```bash
cd mock-server
node tests/test_gemini_connection.js
```

**测试内容**:
- 测试 1: 文本生成
- 测试 2: 视觉识别
- 测试 3: 结构化 JSON 输出

**期望输出**:
```
📊 测试结果汇总:
   ✅ 通过: 3
   ❌ 失败: 0
   ⚠️  跳过: 0

✅ Gemini API 连接正常！
```

---

## 🚀 快速开始

### 首次运行

1. 确认 `.env` 文件配置正确:
```bash
cd mock-server
cat .env | grep GEMINI_API_KEY
```

2. 运行基础测试:
```bash
node tests/test_gemini_simple.js
```

3. 如果基础测试通过，运行视觉测试:
```bash
node tests/test_gemini_vision.js
```

---

## 🔧 故障排查

### 错误: GEMINI_API_KEY 未设置

**检查**:
```bash
cat .env | grep GEMINI_API_KEY
```

**解决**: 在 `.env` 文件中添加:
```
GEMINI_API_KEY=your-api-key-here
```

### 错误: API key not valid

**原因**: API Key 无效或过期

**解决**:
1. 访问 [Google AI Studio](https://aistudio.google.com/apikey)
2. 创建新的 API Key
3. 更新 `.env` 文件

### 错误: 未找到测试图片

**解决**:
```bash
# 上传测试图片到 uploads/photos/
cp /path/to/pet-photo.jpg uploads/photos/
```

### 错误: fetch failed

**原因**: 网络连接问题

**解决**:
```bash
# 测试网络连接
curl -I https://generativelanguage.googleapis.com

# 如需代理
export https_proxy=http://your-proxy:port
```

---

## 📊 性能基准

基于实际测试结果：

| 测试 | 耗时 | Token 消耗 |
|------|------|-----------|
| 文本生成 | ~1-2s | 10 tokens |
| 图片识别 | ~3-5s | ~100 tokens |
| 情绪分析 | ~3-5s | ~150 tokens |

---

## 🔗 相关文档

- **Gemini API 测试指南**: `../GEMINI_API_TEST_GUIDE.md`
- **服务端连接测试**: `../CONNECTION_TEST_RESULT.md`
- **完整流程总结**: `../../DIARY_FLOW_CHECK_SUMMARY.md`
