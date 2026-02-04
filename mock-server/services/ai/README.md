# AI Pipeline (Mock)

单次流程：
- Emotion Analyzer -> Sticker Prompt Builder -> Sticker Generator

入口：`generateStickerPipeline({ imagePath })`

当前为 mock 实现，方便 Flutter 先跑通全流程。

## 环境变量

Gemini:
- `GEMINI_API_KEY`
- `GEMINI_API_BASE_URL` (default: https://generativelanguage.googleapis.com/v1beta)
- `GEMINI_MODEL` (default: gemini-2.5-flash-image) — 情绪/特征识别
- `GEMINI_IMAGE_MODEL` (default: gemini-2.5-flash-image) — 贴纸生成
