# AI Pipeline (Mock)

单次流程：
- Emotion Analyzer -> Sticker Prompt Builder -> Sticker Generator

入口：`generateStickerPipeline({ imagePath })`

当前为 mock 实现，方便 Flutter 先跑通全流程。

## 环境变量

Gemini:
- `GEMINI_API_KEY`
- `GEMINI_MODEL` (default: gemini-2.5-flash-image) — 情绪/特征识别
- `GEMINI_IMAGE_MODEL` (default: gemini-2.5-flash-image) — 贴纸生成

贴纸生图供应商（可切换）:
- `STICKER_IMAGE_PROVIDER` (default: gemini) — 可选: `gemini` / `seedream`

Seedream (火山方舟):
- `SEEDREAM_API_KEY` 或 `ARK_API_KEY`
- `SEEDREAM_BASE_URL` (default: https://ark.cn-beijing.volces.com/api/v3)
- `SEEDREAM_MODEL` (default: doubao-seedream-4-5-251128)
- `SEEDREAM_SIZE` (default: 2K)
- `SEEDREAM_RESPONSE_FORMAT` (default: url)
- `SEEDREAM_WATERMARK` (default: false)
- `SEEDREAM_TIMEOUT_MS` (default: 30000)
