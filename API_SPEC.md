# Pet Diary API 接口规范

> 基于 `mock-server/server.js` 提取，服务端直接对照实现
> 整理日期：2026-02-25

---

## 变更与对齐说明（2026-02-25）

- 新增接口：`GET /api/chongyu/emotions/month`
- 已移除接口：`GET /api/chongyu/diary/list`、`GET /api/chongyu/diary/calendar`、`GET /api/chongyu/diary/7days`
- 文档与实现存在差异（实现有、文档原先未写）：
  - `GET /api/chongyu/photos/:photoId`
  - `GET /api/chongyu/diaries`
  - `GET /api/chongyu/diaries/:diaryId`
- 贴纸静态资源目录已更新为 `uploads/stickers`（原文档写成 `uploads/photos`）

---

## 一、全局约定

### Base URL

| 环境 | Base URL |
|-----|---------|
| Dev（Mock） | `http://<局域网IP>:3000` |
| Staging | `https://staging-api.petdiary.com`（待配置） |
| Prod | `https://api.petdiary.com`（待配置） |

### 认证

所有 `/api/chongyu/` 路由均需在 Header 携带 `token`，缺失返回 401。

```
token: <petId（设备ID）>
```

### 统一响应结构

**成功**：
```json
{
  "success": true,
  "data": { ... }
}
```

**失败**：
```json
{
  "success": false,
  "error": {
    "message": "错误描述",
    "code": 400
  }
}
```

### 通用错误码

| HTTP 状态码 | code | 含义 |
|-----------|------|------|
| 401 | 401 | 未携带 `token` header |
| 400 | 400 | 请求参数缺失或格式错误 |
| 404 | 404 | 资源不存在 |
| 500 | 500 | 服务端内部错误 |

### 文件上传约束

- 支持格式：JPEG / JPG / PNG / HEIC / HEIF
- 单文件上限：10 MB
- Content-Type：`multipart/form-data`

---

## 二、字段枚举值

### 宠物种类（type）

| 值 | 含义 |
|----|------|
| 1 | 狗 dog |
| 2 | 猫 cat |
| 0 | 其他 |

### 性别（gender）

| 值 | 含义 |
|----|------|
| 0 | 未知 unknown |
| 1 | 雄性 male |
| 2 | 雌性 female |

### 情绪（emotion）— 贴纸 & 日历使用

| 值（int） | 字符串 | 含义 |
|---------|--------|------|
| 0 | — | 未知（占位日记默认值） |
| 1 | `happy` | 开心 😊 |
| 2 | `calm` | 平静 😌 |
| 3 | `sad` | 难过 😢 |
| 4 | `angry` | 生气 😠 |
| 5 | `sleepy` | 困倦 😴 |
| 6 | `curious` | 好奇 🤔 |

### 字段格式统一说明（当前规范）

当前接口规范统一为 int 枚举（string 仅作为兼容输入）：

| 场景 | species / type | gender | emotion |
|-----|---------------|--------|---------|
| POST 写入（宠物档案 4.3） | Int：`1`=dog, `2`=cat | Int：`0`=unknown, `1`=male, `2`=female | — |
| GET 读取（宠物列表/详情 4.1 / 4.2） | Int：`1`=dog, `2`=cat | Int：`0`=unknown, `1`=male, `2`=female | — |
| POST 写入（情绪记录 4.13） | — | — | Int：`0`~`6` |
| GET 读取（情绪月历 4.18） | — | — | Int：`0`~`6` |
| GET 读取（日记列表/详情 4.6 / 4.7） | — | — | Int：`0`~`6` |

规律：
- 宠物档案接口统一使用 `type/gender` int；服务端兼容 `species/gender` string 入参并在接口层转换。
- 情绪记录接口（`/api/chongyu/emotions/*`）统一使用 int emotion；服务端兼容 string 入参并转换为 int。
- 日记接口（`/api/chongyu/diaries*`）维持 int emotion。

> 兼容策略：为避免历史客户端中断，服务端仍接受旧 string 值，但响应与存储按 int 规范输出。

---

## 三、数据模型

### PetApiModel（宠物详情）

```json
{
  "petId": "string",
  "type": 2,
  "gender": 1,
  "birthday": "2023-01-01",
  "ownerTitle": "string",
  "avatar": "http://...",
  "nickName": "string",
  "character": "string",
  "description": "string"
}
```

**客户端字段对照**：

| API 字段 | 客户端字段 | 说明 |
|---------|----------|------|
| `petId` | `id` | 设备 ID |
| `type` | `species` | 枚举映射见上方 |
| `gender` | `gender` | 枚举映射见上方 |
| `birthday` | `birthday` | ISO 日期字符串 |
| `ownerTitle` | `ownerNickname` | 主人称呼 |
| `avatar` | `profilePhotoPath` | 头像 URL |
| `nickName` | `name` | 宠物名 |
| `character` | `personality` | 性格描述 |
| `description` | `breed` | 品种 |

### DiaryListItem（日记列表条目）

```json
{
  "diaryId": "string",
  "date": "2026-01-15",
  "title": "string",
  "avatar": "http://...",
  "emotion": 1
}
```

### CalendarDayItem（日历条目）

```json
{
  "diaryId": "string",
  "date": "2026-01-15",
  "weekDay": 3,
  "title": "string",
  "avatar": "http://...",
  "emotion": 1
}
```

> `weekDay`：0=周日，1=周一，...，6=周六

### DiaryDetail（日记详情）

```json
{
  "date": "2026-01-15",
  "title": "string",
  "avatar": "http://...",
  "emotion": 1,
  "content": "string",
  "imageList": ["http://...", "http://..."]
}
```

---

## 四、接口详情

---

### 4.1 GET `/api/chongyu/pet/list` — 宠物列表

**用途**：查询当前 token 下所有宠物档案。

**Request**

| 位置 | 字段 | 类型 | 必填 | 说明 |
|-----|------|------|------|------|
| Header | `token` | String | ✅ | 设备 ID |

**Response**（200）

```json
{
  "success": true,
  "data": {
    "petList": [ PetApiModel, ... ]
  }
}
```

---

### 4.2 GET `/api/chongyu/pet/detail` — 宠物详情 / 日记详情（复用路由）

**用途**：
- 仅传 `petId` → 返回宠物档案详情
- 传 `petId + diaryId` 或 `petId + date` → 返回该日记详情（含动态 `imageList`）

**Request**

| 位置 | 字段 | 类型 | 必填 | 说明 |
|-----|------|------|------|------|
| Header | `token` | String | ✅ | |
| Query | `petId` | String | ✅ | |
| Query | `diaryId` | String | — | 有则返回日记详情 |
| Query | `date` | String | — | YYYY-MM-DD，`diaryId` 不传时用此定位日记 |

**Response — 宠物详情**（仅传 petId）

```json
{
  "success": true,
  "data": PetApiModel
}
```

**Response — 日记详情**（传 petId + diaryId 或 date）

```json
{
  "success": true,
  "data": {
    "date": "2026-01-15",
    "title": "string",
    "avatar": "http://...",
    "emotion": 1,
    "content": "string",
    "imageList": ["http://...", "http://..."]
  }
}
```

> **关键规则**：`imageList` 由两部分动态合并返回：
> 1. diary 记录本身存储的 `imageList`
> 2. 该 `petId + date` 下 `pet_photos` 表中所有图片 URL（去重后追加）
>
> 客户端每次请求均获得最新合并结果，无需客户端自行合并。

**Error**

| 场景 | HTTP | code | message |
|-----|------|------|---------|
| 缺少 petId | 400 | 400 | 缺少 petId 参数 |
| 宠物不存在 | 404 | 404 | 宠物不存在 |
| 日记不存在 | 404 | 404 | 日记不存在 |

---

### 4.3 POST `/api/chongyu/pets/profile` — 同步宠物档案

**用途**：创建或更新宠物档案（以 `id` 字段做 upsert）。

**Request**

| 位置 | 字段 | 类型 | 必填 | 说明 |
|-----|------|------|------|------|
| Header | `token` | String | ✅ | |
| Body (JSON) | `id` | String | ✅ | 设备 ID，同 petId |
| Body | `name` | String | ✅ | 宠物名 |
| Body | `type` | Int | ✅ | `1`=dog, `2`=cat |
| Body | `breed` | String | — | 品种 |
| Body | `profilePhotoPath` | String | — | 头像 URL 或本地路径 |
| Body | `birthday` | String | — | YYYY-MM-DD |
| Body | `ownerNickname` | String | — | 主人称呼 |
| Body | `gender` | Int | — | `0`=unknown, `1`=male, `2`=female |
| Body | `personality` | String | — | 性格描述 |
| Body | `createdAt` | String | — | ISO 时间戳 |

> 兼容：服务端仍接受历史 `species` / `gender` string 入参，并在接口层转换为 int 规范。

**Response**（200）

```json
{
  "success": true,
  "data": {
    "petId": "device-uuid",
    "syncedAt": "2026-01-15T10:00:00.000Z"
  },
  "message": "同步成功"
}
```

---

### 4.4 GET `/api/chongyu/pets/:petId/profile` — 获取宠物档案（原始格式）

**用途**：按 petId 获取原始宠物档案（非 API 映射格式，客户端用于启动时校验档案是否存在）。

**Request**

| 位置 | 字段 | 类型 | 必填 |
|-----|------|------|------|
| Header | `token` | String | ✅ |
| Path | `petId` | String | ✅ |

**Response**（200）

```json
{
  "success": true,
  "data": { ...Pet 原始对象... }
}
```

**Error** — 404 宠物档案不存在

---

### 4.5 POST `/api/chongyu/image/list/upload` — 批量上传相册图片

**用途**：客户端扫描宠物照片后批量上传，服务端负责去重、关联 diary。

**Request**

| 位置 | 字段 | 类型 | 必填 | 说明 |
|-----|------|------|------|------|
| Header | `token` | String | ✅ | |
| Form | `image` | File[] | ✅ | 字段名固定为 `image`（允许多次），每文件 ≤ 10MB，最多 20 个 |
| Form | `assetId_N` | String | — | 第 N 张图片的 iOS Photos assetId，用于去重 |
| Form | `petId_N` | String | — | 第 N 张图片对应的宠物 ID |
| Form | `date_N` | String | — | 第 N 张图片的拍摄日期，YYYY-MM-DD |
| Form | `time_N` | String | — | 拍摄时间戳（毫秒或 ISO 字符串） |
| Form | `location_N` | String | — | 拍摄地点（自由格式） |

> N 从 0 开始，与 `req.files` 数组下标对应，即第 0 张文件对应 `assetId_0`, `petId_0`, `date_0`。

**去重规则**：
- 同一 `assetId + petId` 组合已存在 → 跳过写库，计入 `duplicates`
- 任意一方为空时不做去重检查（均会写入）

**服务端副作用**：
1. 写入 `pet_photos` 表
2. 若该 `petId + date` 已有 diary → 将图片 URL 追加到 `diary.imageList`（不重复）
3. 若该 `petId + date` 无 diary → 自动创建**占位日记**（content 为空，imageList 含当天所有已上传图片）

**Response**（200）

```json
{
  "success": true,
  "data": {
    "uploaded": 3,
    "duplicates": 1
  }
}
```

**Error**

| 场景 | HTTP | message |
|-----|------|---------|
| 未接收到文件 | 400 | 未接收到图片文件 |
| 文件格式不支持 | 400 | 只支持 JPEG/PNG/HEIC 格式的图片 |

---

### 4.6 GET `/api/chongyu/diaries` — 日记列表

**用途**：获取某宠物日记列表，支持分页。

**Request**

| 位置 | 字段 | 类型 | 必填 | 说明 |
|-----|------|------|------|------|
| Header | `token` | String | ✅ | |
| Query | `petId` | String | — | 过滤指定宠物 |
| Query | `limit` | Int | — | 默认 `30` |
| Query | `offset` | Int | — | 默认 `0` |

**Response**（200）

```json
{
  "success": true,
  "data": {
    "diaries": [
      {
        "id": "string",
        "petId": "string",
        "date": "2026-01-15",
        "content": "string",
        "imagePath": "http://...",
        "emotion": 1,
        "imageList": ["http://...", "http://..."]
      }
    ],
    "total": 12,
    "limit": 30,
    "offset": 0
  }
}
```

> 按 `date` 降序排列。

---

### 4.7 GET `/api/chongyu/diaries/:diaryId` — 日记详情

**用途**：根据 `diaryId` 获取日记详情（含动态合并 `imageList`）。

**Request**

| 位置 | 字段 | 类型 | 必填 |
|-----|------|------|------|------|
| Header | `token` | String | ✅ |
| Path | `diaryId` | String | ✅ |

**Response**（200）

```json
{
  "success": true,
  "data": {
    "date": "2026-01-15",
    "title": "string",
    "avatar": "http://...",
    "emotion": 1,
    "content": "string",
    "imageList": ["http://...", "http://..."]
  }
}
```

**Error**

| 场景 | HTTP | code | message |
|-----|------|------|---------|
| 日记不存在 | 404 | 404 | 日记不存在 |

---

### 4.8 `GET /api/chongyu/diary/list` / `GET /api/chongyu/diary/calendar` / `GET /api/chongyu/diary/7days` — 已移除

已由 `/api/chongyu/diaries` 与 `/api/chongyu/diaries/:diaryId` 覆盖，不再提供。

---

### 4.9 GET `/api/chongyu/pet/photos` — 查询宠物照片

**用途**：查询已上传的宠物照片，可按日期过滤。

**Request**

| 位置 | 字段 | 类型 | 必填 | 说明 |
|-----|------|------|------|------|
| Header | `token` | String | ✅ | |
| Query | `petId` | String | ✅ | |
| Query | `date` | String | — | YYYY-MM-DD，不传则返回全部 |

**Response**（200）

```json
{
  "success": true,
  "data": {
    "photoList": [
      {
        "id": "uuid",
        "petId": "string",
        "date": "2026-01-15",
        "assetId": "string",
        "url": "http://...",
        "size": 204800,
        "time": "string",
        "location": "string",
        "uploadedAt": "2026-01-15T10:00:00.000Z"
      }
    ]
  }
}
```

---

### 4.10 POST `/api/chongyu/upload/profile-photo` — 上传头像

**用途**：上传宠物头像图片，返回可访问 URL。

**Request**

| 位置 | 字段 | 类型 | 必填 |
|-----|------|------|------|
| Header | `token` | String | ✅ |
| Form | `photo` | File | ✅ |

**Response**（200）

```json
{
  "success": true,
  "data": {
    "url": "http://.../uploads/profiles/uuid.jpg",
    "thumbnailUrl": "http://.../uploads/profiles/uuid.jpg",
    "fileSize": 204800,
    "mimeType": "image/jpeg"
  }
}
```

---

### 4.11 POST `/api/chongyu/upload/photo` — 上传普通照片

**Request**

| 位置 | 字段 | 类型 | 必填 |
|-----|------|------|------|
| Header | `token` | String | ✅ |
| Form | `photo` | File | ✅ |

**Response**（200）

```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "url": "http://.../uploads/photos/uuid.jpg",
    "size": 204800,
    "mimeType": "image/jpeg",
    "uploadedAt": "2026-01-15T10:00:00.000Z"
  }
}
```

---

### 4.12 POST `/api/chongyu/diaries` — 创建 / 更新日记

**用途**：upsert 一条日记（以 `id` 字段做唯一键）。

**Request**

| 位置 | 字段 | 类型 | 必填 | 说明 |
|-----|------|------|------|------|
| Header | `token` | String | ✅ | |
| Body (JSON) | `id` | String | — | 不传则服务端生成 UUID |
| Body | `petId` | String | ✅ | |
| Body | `date` | String | ✅ | YYYY-MM-DD |
| Body | `content` | String | ✅ | 日记正文 |
| Body | `imagePath` | String | — | 封面图 URL 或本地路径 |
| Body | `isLocked` | Boolean | — | 默认 false |
| Body | `emotionRecordId` | String | — | 关联情绪记录 ID |
| Body | `createdAt` | String | — | 客户端创建时间 |

**Response**（200）

```json
{
  "success": true,
  "data": { ...Diary 完整对象... }
}
```

---

### 4.13 POST `/api/chongyu/emotions/save` — 保存情绪记录

**用途**：upsert 一条情绪记录（以 `id` 字段做唯一键）。

**Request**

| 位置 | 字段 | 类型 | 必填 | 说明 |
|-----|------|------|------|------|
| Header | `token` | String | ✅ | |
| Body (JSON) | `id` | String | ✅ | 记录唯一 ID（缺失返回 400） |
| Body | `petId` | String | ✅ | |
| Body | `date` | String | ✅ | YYYY-MM-DD |
| Body | `aiEmotion` | Int | — | `0`~`6` |
| Body | `aiConfidence` | Number | — | 0.0~1.0 |
| Body | `selectedEmotion` | Int | — | `0`~`6` |
| Body | `stickerUrl` | String | — | 贴纸 URL |
| Body | `originalPhotoPath` | String | — | 原始照片路径 |
| Body | `createdAt` | String | — | 客户端创建时间 |

> 兼容：服务端仍接受历史 string emotion（如 `"happy"`）并转换为 int 存储。

**Response**（200）

```json
{
  "success": true,
  "data": {
    "recordId": "string",
    "syncedAt": "2026-01-15T10:00:00.000Z"
  }
}
```

**Error** — 400 缺少 id 字段

---

### 4.14 POST `/api/chongyu/ai/sticker/generate` — AI 贴纸生成

**用途**：上传一张宠物照片，返回情绪分析结果 + 生成的卡通贴纸图片 URL。

**Request**

| 位置 | 字段 | 类型 | 必填 | 说明 |
|-----|------|------|------|------|
| Header | `token` | String | ✅ | |
| Form | `image` | File | ✅ | 单张图片 |

**服务端处理流程（AI Pipeline）**：
```
Step 1: 情绪 & 特征识别（Ark Vision 或 Gemini Vision）
        输入：照片 base64
        输出：emotion, confidence, reasoning, pet_features

Step 2: 构建生图 Prompt
        基于情绪 + 宠物特征 → 卡通 chibi 风格 prompt

Step 3: 生成贴纸图（Gemini 或 Seedream）
        输入：prompt + 参考图
        输出：贴纸图片 URL

降级（任意步骤失败）：返回原图 URL 作为贴纸，emotion='calm', confidence=0.0
```

**Response（成功）**（200）

```json
{
  "success": true,
  "data": {
    "analysis": {
      "emotion": 1,
      "confidence": 0.92,
      "reasoning": "The pet is wagging its tail and has wide eyes"
    },
    "pet_features": {
      "species": "dog",
      "breed": "Golden Retriever",
      "primary_color": "golden",
      "markings": "none",
      "eye_color": "brown",
      "pose": "sitting"
    },
    "sticker": {
      "style": "chibi",
      "prompt": "...",
      "imageUrl": "http://.../uploads/stickers/uuid.png"
    },
    "meta": {
      "pipelineVersion": "v1",
      "generatedAt": "2026-01-15T10:00:00.000Z"
    }
  }
}
```

**Response（降级，AI 失败但不报错）**（200）

```json
{
  "success": true,
  "data": {
    "analysis": {
      "emotion": 2,
      "confidence": 0.0,
      "reasoning": "fallback"
    },
    "pet_features": {
      "species": "other",
      "breed": "宠物",
      "primary_color": "unknown",
      "markings": "unknown",
      "eye_color": "unknown",
      "pose": "unknown"
    },
    "sticker": {
      "style": "fallback",
      "prompt": "",
      "imageUrl": "http://.../uploads/photos/原图.jpg"
    },
    "meta": {
      "pipelineVersion": "fallback",
      "generatedAt": "2026-01-15T10:00:00.000Z",
      "error": "具体错误信息"
    }
  }
}
```

> **重要**：AI 失败时服务端**不返回 5xx**，而是返回 200 + fallback 结构，客户端通过 `meta.pipelineVersion === "fallback"` 或 `confidence === 0.0` 识别降级。
>
> **持久化说明**：当生图供应商返回外链（如 Seedream 的时效 URL）时，服务端会下载并保存到 `uploads/stickers`，再返回本地可长期访问 URL；下载失败时才回退外链。

**Error** — 400 未接收到图片文件

---

### 4.15 POST `/api/chongyu/ai/diary/generate` — AI 日记生成（含图片上传）

**用途**：上传多张照片 + 宠物信息，服务端调用 AI 生成日记文字，日记内容不自动写库。

**Request**

| 位置 | 字段 | 类型 | 必填 | 说明 |
|-----|------|------|------|------|
| Header | `token` | String | ✅ | |
| Form | `images` | File[] | ✅ | 最多 10 张，字段名为 `images` |
| Form | `pet` | String | ✅ | JSON 序列化的宠物对象（含 name, species, breed, gender, personality, ownerNickname 等） |
| Form | `date` | String | — | YYYY-MM-DD，不传默认今天 |
| Form | `otherPets` | String | — | JSON 序列化的数组，元素格式 `{id, name, species}`，用于日记中提及同伴 |

**`pet` 字段示例**：
```json
{
  "id": "device-uuid",
  "name": "小白",
  "species": "cat",
  "breed": "英短",
  "gender": "female",
  "personality": "粘人",
  "ownerNickname": "主人"
}
```

**服务端 AI 行为**：
- 以第一人称（宠物视角）生成 200~400 字中文日记
- 分析照片中出现的其他动物（主角 / 非主角）
- 调用 Ark Vision（`doubao-1-5-vision-pro-32k-250115`）

**Response**（200）

```json
{
  "success": true,
  "data": {
    "content": "今天真是开心的一天，主人带我去公园...",
    "mentionedAnimals": [
      {
        "species": "dog",
        "description": "棕色的柯基",
        "is_main": false
      }
    ],
    "meta": {
      "imageCount": 3,
      "generatedAt": "2026-01-15T10:00:00.000Z",
      "model": "doubao-1-5-vision-pro-32k-250115"
    }
  }
}
```

**Error**

| 场景 | HTTP | message |
|-----|------|---------|
| 未接收到图片 | 400 | 未接收到图片文件 |
| 缺少 pet 参数 | 400 | 缺少 pet 参数 |
| pet JSON 格式错误 | 400 | pet 参数格式错误 |
| AI 调用失败 | 500 | 具体错误信息 |

---

### 4.16 POST `/api/chongyu/ai/diary/auto-generate` — 自动生成日记（使用服务端已有照片）

**用途**：基于服务端 `pet_photos` 表中已上传的照片，自动为某天生成日记并写库。与 4.15 不同：**不需要客户端上传图片，直接用服务端存储**。

**Request**

| 位置 | 字段 | 类型 | 必填 | 说明 |
|-----|------|------|------|------|
| Header | `token` | String | ✅ | |
| Body (JSON) | `petId` | String | ✅ | |
| Body | `date` | String | — | YYYY-MM-DD，不传默认今天 |

**服务端执行逻辑**：

```
1. 查找 pet_photos 中 petId + date 的照片
   → 无照片 → 返回 generated:false, reason:'NO_PHOTOS'

2. 查找该 petId + date 是否已有日记且有内容
   → 已有内容 → 返回 generated:false, reason:'ALREADY_GENERATED'

3. 调用 generateDiary（同 4.15 逻辑）
   → AI 失败 → 返回 500

4. 写入/更新 diaries 表（自动关联 imageList）

5. 返回 generated:true
```

**Response — 无照片**（200）

```json
{
  "success": true,
  "data": {
    "generated": false,
    "reason": "NO_PHOTOS",
    "date": "2026-01-15"
  }
}
```

**Response — 已有内容，跳过**（200）

```json
{
  "success": true,
  "data": {
    "generated": false,
    "reason": "ALREADY_GENERATED",
    "diaryId": "string",
    "contentLength": 320,
    "date": "2026-01-15"
  }
}
```

**Response — 生成成功**（200）

```json
{
  "success": true,
  "data": {
    "generated": true,
    "diaryId": "string",
    "contentLength": 285,
    "date": "2026-01-15"
  }
}
```

**Error**

| 场景 | HTTP | message |
|-----|------|---------|
| 缺少 petId | 400 | 缺少 petId 参数 |
| 宠物不存在 | 404 | 宠物不存在 |
| AI 失败 | 500 | 具体错误信息 |

---

### 4.17 GET `/api/chongyu/stats` — 服务器统计信息

**用途**：监控用，查看各集合数量和服务状态。

**Response**（200）

```json
{
  "success": true,
  "data": {
    "pets": 1,
    "photos": 42,
    "pet_photos": 38,
    "diaries": 15,
    "emotion_records": 10,
    "users": 0,
    "uptime": 3600.5,
    "memory": { "rss": 0, "heapTotal": 0, "heapUsed": 0 }
  }
}
```

---

### 4.18 GET `/api/chongyu/emotions/month` — 按月查询情绪记录

**用途**：按月份拉取 `emotion_records`，用于日历启动/切月时与本地缓存对齐（含历史 `stickerUrl`）。

**Request**

| 位置 | 字段 | 类型 | 必填 | 说明 |
|-----|------|------|------|------|
| Header | `token` | String | ✅ | |
| Query | `year` | Int | ✅ | 如 `2026` |
| Query | `month` | Int | ✅ | 1~12，如 `2` |
| Query | `petId` | String | — | 传入时只返回该宠物记录 |

**示例**

`GET /api/chongyu/emotions/month?year=2026&month=2&petId=xxx`

**Response**（200）

```json
{
  "success": true,
  "data": {
    "records": [
      {
        "id": "1770736183258",
        "petId": "f9f97894-d7ac-4360-b1ca-4ed62cf18e63",
        "date": "2026-02-10T23:09:43.259002",
        "aiEmotion": 2,
        "aiConfidence": 0.7,
        "aiFeatures": {
          "species": "dog",
          "breed": "Australian Shepherd",
          "color": "white",
          "pose": "Sitting"
        },
        "selectedEmotion": 2,
        "stickerUrl": "http://<host>:3000/uploads/stickers/xxx.jpg",
        "createdAt": "2026-02-10T23:09:43.259048",
        "updatedAt": "2026-02-10T23:09:43.259048",
        "syncedAt": "2026-02-10T15:09:43.557Z"
      }
    ]
  }
}
```

**Error**

| 场景 | HTTP | code | message |
|-----|------|------|---------|
| `year` 或 `month` 非法 | 400 | 400 | year/month 参数不合法 |

---

## 五、业务规则汇总

### 图片去重规则

上传接口（4.5）按 `assetId + petId` 联合唯一，两者均不为空时才检查去重。去重命中的照片文件**仍会写入磁盘**（multer 已存储），但不写入 `pet_photos` 表，`duplicates` 计数加 1。

### 占位日记自动创建

上传照片时（4.5），若 `petId + date` 对应的 diary 不存在，服务端自动创建一条：

```json
{
  "content": "",
  "title": "",
  "emotion": 0,
  "imageList": ["<已上传图片URL>"],
  "isLocked": false
}
```

后续同一天继续上传图片，会追加到已有 diary 的 `imageList`。

### 日记 imageList 动态合并

`/api/chongyu/diaries/:diaryId` 每次返回时实时合并：

```
最终 imageList = diary.imageList（存储值）∪ pet_photos（petId+date 过滤结果）
```

两个来源的 URL 去重后返回，保持稳定顺序。

### AI 管线降级策略

- 贴纸生成（4.14）：任意步骤失败 → 200 + fallback 结构，客户端不感知失败
- 日记生成（4.15）：AI 失败 → 500，客户端有本地模板兜底
- 自动日记生成（4.16）：AI 失败 → 500，客户端不重试

---

## 六、AI 服务配置

| 环境变量 | 用途 | 默认值 |
|---------|------|--------|
| `GEMINI_API_KEY` | Gemini 情绪识别 & 生图（备选） | — |
| `GEMINI_MODEL` | 情绪 & 特征识别模型 | `gemini-2.5-flash-image` |
| `GEMINI_IMAGE_MODEL` | 贴纸生图模型 | `gemini-2.5-flash-image` |
| `ARK_API_KEY` | 豆包 Vision（情绪识别主选 & 日记生成） | — |
| `ARK_VISION_MODEL` | 情绪识别模型 | `doubao-1-5-vision-pro-32k-250115` |
| `ARK_API_BASE_URL` | 豆包 API 地址 | `https://ark.cn-beijing.volces.com/api/v3` |
| `SEEDREAM_API_KEY` | Seedream 情绪识别 &贴纸生图 | — |
| `SEEDREAM_MODEL` | 生图模型 | `doubao-seedream-4-5-251128` |
| `STICKER_IMAGE_PROVIDER` | 贴纸生图供应商 `gemini` / `seedream` | `gemini` |

> 情绪识别：优先 ARK，失败则 Gemini，两者均无则报错。
> 贴纸生图：由 `STICKER_IMAGE_PROVIDER` 决定供应商。

---

## 七、静态资源访问

上传文件通过 HTTP 静态服务访问：

```
http://<host>:<port>/uploads/profiles/<filename>   # 头像
http://<host>:<port>/uploads/photos/<filename>     # 宠物照片
http://<host>:<port>/uploads/stickers/<filename>   # AI 贴纸
```

相对路径图片 URL 会经 `normalizeUrl` 处理并按请求 `host` 拼接；已是绝对 URL（`http/https`）时保持原样返回。

---

*基于 mock-server/server.js 及 services/ai/ 提取*
