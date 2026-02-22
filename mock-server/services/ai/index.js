const { analyzeEmotion } = require('./emotionAnalyzer');
const { buildStickerPrompt } = require('./stickerPromptBuilder');
const { generateStickerImage } = require('./stickerGenerator');
const { generateDiary } = require('./diaryGenerator');

async function generateStickerPipeline({ imagePath, host, protocol }) {
  // Step 1: 情绪 & 特征识别
  const analysisResult = await analyzeEmotion(imagePath);

  // Step 2: 构建生图 prompt
  const stickerPrompt = buildStickerPrompt(analysisResult);

  // Step 3: 生成贴纸图
  const imageUrl = await generateStickerImage({
    imagePath,
    prompt: stickerPrompt,
    host,
    protocol
  });

  return {
    ...analysisResult,
    sticker: {
      style: 'chibi',
      // debug 阶段可返回 prompt，稳定后可移除
      prompt: stickerPrompt,
      imageUrl
    },
    meta: {
      pipelineVersion: 'v1',
      generatedAt: new Date().toISOString()
    }
  };
}

module.exports = {
  generateStickerPipeline,
  generateDiary
};
