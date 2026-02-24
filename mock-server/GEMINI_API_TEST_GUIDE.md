# Gemini API 测试指南

## ✅ 测试结果总结

**测试时间**: 2026-02-04
**API 状态**: ✅ 正常工作

### 测试通过项

1. ✅ **基础文本生成** - API Key 有效，连接正常
2. ✅ **视觉识别** - 成功识别宠物照片（三花猫）
3. ✅ **结构化 JSON 输出** - 情绪分析返回正确格式

### 识别示例

**测试图片**: `8808bc26-adc6-44ab-a502-6498031b076d.png` (1.5 MB)

**识别结果**:
```json
{
  "analysis": {
    "emotion": "curious",
    "confidence": 0.85,
    "reasoning": "The cat's ears are perked up and its eyes are wide open, looking directly at the camera, suggesting curiosity."
  },
  "pet_features": {
    "species": "cat",
    "breed": "Domestic Shorthair",
    "primary_color": "calico"
  }
}
```

---

## 🧪 测试方法

### 方法 1: 快速测试（推荐）

```bash
cd mock-server

# 测试基础连接
node test_gemini_simple.js

# 测试视觉识别（需要有测试图片）
node test_gemini_vision.js
```

**期望输出**:
```
✅ 连接成功!
响应: "Hello"
✅ Gemini API 工作正常！
```

### 方法 2: 使用 curl 手动测试

```bash
# 1. 设置环境变量
export GEMINI_API_KEY="your-api-key-here"

# 2. 测试文本生成
curl -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent" \
  -H "Content-Type: application/json" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -d '{
    "contents": [{
      "role": "user",
      "parts": [{"text": "Say hello"}]
    }]
  }'
```

**期望响应**:
```json
{
  "candidates": [{
    "content": {
      "parts": [{"text": "Hello"}],
      "role": "model"
    },
    "finishReason": "STOP"
  }],
  "usageMetadata": {
    "promptTokenCount": 9,
    "candidatesTokenCount": 1,
    "totalTokenCount": 10
  }
}
```

### 方法 3: 在 Mock Server 中测试

```bash
# 1. 启动 mock server
cd mock-server
npm start

# 2. 上传测试照片并生成贴纸
curl -X POST "http://192.168.3.129:3000/api/chongyu/ai/sticker/generate" \
  -F "image=@/path/to/pet-photo.jpg"
```

**期望响应**:
```json
{
  "success": true,
  "data": {
    "analysis": {
      "emotion": "happy",
      "confidence": 0.85
    },
    "pet_features": {
      "species": "cat",
      "breed": "..."
    },
    "sticker": {
      "style": "chibi",
      "imageUrl": "http://..."
    }
  }
}
```

---

## ⚙️ 配置说明

### 环境变量（.env 文件）

```bash
# Gemini API 配置
GEMINI_API_KEY=your key
GEMINI_MODEL=gemini-2.5-flash-image
GEMINI_IMAGE_MODEL=gemini-2.5-flash-image
```

### 模型选择

**可用模型**:
- `gemini-2.5-flash-image` - 快速，支持视觉（推荐）
- `gemini-2.5-flash` - 纯文本，速度最快
- `gemini-2.5-pro` - 更强性能，较慢

### API Key 获取

1. 访问 [Google AI Studio](https://aistudio.google.com/apikey)
2. 登录 Google 账号
3. 点击 "Create API Key"
4. 复制 API Key 到 `.env` 文件

---

## 🔍 常见问题排查

### 1. API Key 无效

**错误信息**:
```json
{
  "error": {
    "code": 400,
    "message": "API key not valid"
  }
}
```

**解决方法**:
1. 检查 `.env` 文件中的 `GEMINI_API_KEY` 是否正确
2. 确认 API Key 未过期
3. 检查 API Key 是否启用了 Gemini API

**验证命令**:
```bash
cat .env | grep GEMINI_API_KEY
```

### 2. 网络连接失败

**错误信息**: `fetch failed` 或 `ECONNREFUSED`

**可能原因**:
- 无法访问 Google API（网络限制）
- 防火墙阻止连接
- 代理设置问题

**解决方法**:
```bash
# 测试网络连接
curl -I https://generativelanguage.googleapis.com

# 使用代理（如需要）
export https_proxy=http://your-proxy:port
```

### 3. API 配额超限

**错误信息**:
```json
{
  "error": {
    "code": 429,
    "message": "Resource has been exhausted"
  }
}
```

**解决方法**:
1. 等待配额重置（通常每分钟重置）
2. 检查 [API 配额使用情况](https://console.cloud.google.com/apis/api/generativelanguage.googleapis.com/quotas)
3. 升级到付费版（如需要）

### 4. 模型不存在

**错误信息**:
```json
{
  "error": {
    "code": 404,
    "message": "models/xxx not found"
  }
}
```

**解决方法**:
检查模型名称是否正确：
```bash
# 列出可用模型
curl "https://generativelanguage.googleapis.com/v1beta/models?key=$GEMINI_API_KEY"
```

### 5. 图片太大

**错误信息**: `Request payload size exceeds the limit`

**解决方法**:
- 压缩图片到 < 4MB
- 使用 JPEG 格式（而非 PNG）
- 降低图片分辨率

**图片压缩示例**（在 Flutter 中已实现）:
```javascript
// PhotoCompressionService 会自动压缩到 1080p, JPEG 80%
```

---

## 📊 性能基准

基于测试结果：

| 操作 | 耗时 | Token 消耗 |
|------|------|-----------|
| 简单文本生成 | ~1-2s | 10 tokens |
| 图片内容描述 | ~3-5s | ~100 tokens |
| 结构化 JSON 分析 | ~3-5s | ~150 tokens |

**说明**:
- 图片大小: 1.5 MB
- 网络: 正常家庭宽带
- API 响应时间因网络而异

---

## 🔧 集成到业务流程

### 1. 照片情绪分析

**端点**: `POST /api/chongyu/ai/sticker/generate`

**流程**:
```
1. 客户端上传照片
2. Mock Server 调用 Gemini Vision API
3. 解析 JSON 返回情绪和特征
4. 生成贴纸图（可选）
5. 返回结果给客户端
```

**代码位置**:
- `mock-server/services/ai/emotionAnalyzer.js` - 情绪分析
- `mock-server/services/ai/stickerGenerator.js` - 贴纸生成
- `mock-server/services/ai/index.js` - 完整管线

### 2. 批量照片处理

当前流程会为**每张照片**调用 API，可能导致：
- ⚠️ API 配额快速消耗
- ⚠️ 响应时间较长

**优化建议**:
1. 只对精选照片（如封面）调用 AI
2. 缓存分析结果（相同 assetId 不重复调用）
3. 后台异步处理，不阻塞上传

---

## 🎯 测试清单

运行完整测试：

```bash
cd mock-server

# ✅ 1. 测试 API Key 配置
cat .env | grep GEMINI_API_KEY

# ✅ 2. 测试基础连接
node test_gemini_simple.js

# ✅ 3. 测试视觉识别
node test_gemini_vision.js

# ✅ 4. 测试完整管线（需要服务器运行）
curl -X POST "http://192.168.3.129:3000/api/chongyu/ai/sticker/generate" \
  -F "image=@uploads/photos/8808bc26-adc6-44ab-a502-6498031b076d.png"
```

---

## 📝 测试文件说明

| 文件 | 用途 | 依赖 |
|------|------|------|
| `test_gemini_simple.js` | 基础文本生成测试 | .env |
| `test_gemini_vision.js` | 视觉识别测试 | .env + 测试图片 |
| `test_gemini_connection.js` | 完整测试套件 | .env + 测试图片 |

---

## ✅ 结论

**当前状态**: Gemini API 连接正常，可以进行宠物情绪分析

**已验证功能**:
- ✅ 文本生成
- ✅ 图片识别（宠物物种、品种、颜色）
- ✅ 情绪分析（happy, calm, sad, angry, sleepy, curious）
- ✅ 结构化 JSON 输出

**可用于生产**:
- AI 照片情绪分析
- 宠物特征提取
- 自动生成日记描述

**下一步**:
1. 在客户端集成 AI 分析功能
2. 测试批量照片处理性能
3. 优化 API 调用频率（缓存 + 异步）

---

## 🔗 相关资源

- [Gemini API 文档](https://ai.google.dev/gemini-api/docs)
- [Google AI Studio](https://aistudio.google.com/)
- [API Key 管理](https://aistudio.google.com/apikey)
- [配额和限制](https://ai.google.dev/gemini-api/docs/quota-and-limits)
