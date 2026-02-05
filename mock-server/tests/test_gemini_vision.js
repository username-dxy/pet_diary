#!/usr/bin/env node

/**
 * Gemini 视觉能力测试（SDK 版本）
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { GoogleGenAI } = require('@google/genai');

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash-image';

if (!GEMINI_API_KEY) {
  console.error('❌ GEMINI_API_KEY 未设置');
  process.exit(1);
}

const client = new GoogleGenAI({ apiKey: GEMINI_API_KEY });

function inferMimeType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.png') return 'image/png';
  if (ext === '.heic') return 'image/heic';
  return 'image/jpeg';
}

async function main() {
  const uploadsDir = path.join(__dirname, '..', 'uploads', 'photos');
  if (!fs.existsSync(uploadsDir)) {
    console.error('❌ 未找到 uploads/photos 目录');
    process.exit(1);
  }

  const files = fs.readdirSync(uploadsDir).filter(f =>
    f.endsWith('.jpg') || f.endsWith('.png') || f.endsWith('.jpeg') || f.endsWith('.heic')
  );

  if (files.length === 0) {
    console.error('❌ uploads/photos 目录为空');
    process.exit(1);
  }

  const testImagePath = path.join(uploadsDir, files[0]);
  const imageBuffer = fs.readFileSync(testImagePath);
  const base64Data = imageBuffer.toString('base64');

  const interaction = await client.interactions.create({
    model: GEMINI_MODEL,
    input: [
      {
        inlineData: {
          mimeType: inferMimeType(testImagePath),
          data: base64Data
        }
      },
      { text: '请描述这张宠物照片（简短一句话）。' }
    ]
  });

  const outputs = interaction?.outputs || [];
  const last = outputs[outputs.length - 1] || {};
  const text = last.text || '';

  console.log('✅ 视觉测试成功');
  console.log(`图片: ${path.basename(testImagePath)}`);
  console.log(`描述: ${text.trim()}`);
}

main().catch(err => {
  console.error('❌ 视觉测试失败:', err.message);
  process.exit(1);
});
