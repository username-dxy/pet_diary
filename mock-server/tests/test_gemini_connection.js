#!/usr/bin/env node

/**
 * Gemini API 连接测试脚本（SDK 版本）
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { GoogleGenAI } = require('@google/genai');

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash-image';

console.log('');
console.log('🧪 =====================================');
console.log('   Gemini API 连接测试（SDK）');
console.log('=====================================');
console.log('');

console.log('📋 配置检查:');
console.log(`   API Key: ${GEMINI_API_KEY ? '✅ 已设置 (' + GEMINI_API_KEY.substring(0, 10) + '...)' : '❌ 未设置'}`);
console.log(`   Model: ${GEMINI_MODEL}`);
console.log('');

if (!GEMINI_API_KEY) {
  console.error('❌ 错误: GEMINI_API_KEY 未设置');
  console.log('');
  console.log('💡 请在 .env 文件中设置:');
  console.log('   GEMINI_API_KEY=your-api-key-here');
  console.log('');
  process.exit(1);
}

const client = new GoogleGenAI({ apiKey: GEMINI_API_KEY });

async function testTextGeneration() {
  console.log('🧪 测试 1: 文本生成能力');
  console.log('   发送提示: "用一句话介绍宠物日记应用"');

  try {
    const interaction = await client.interactions.create({
      model: GEMINI_MODEL,
      input: '用一句话介绍宠物日记应用。只回答一句话，不要解释。'
    });

    const outputs = interaction?.outputs || [];
    const last = outputs[outputs.length - 1] || {};
    const text = last.text || '';

    console.log('   ✅ 成功!');
    console.log(`   响应: "${text.trim()}"`);
    console.log('');
    return true;
  } catch (error) {
    console.error(`   ❌ 失败: ${error.message}`);
    console.log('');
    return false;
  }
}

async function testVisionAnalysis() {
  console.log('🧪 测试 2: 视觉识别能力（宠物照片分析）');

  const uploadsDir = path.join(__dirname, '..', 'uploads', 'photos');
  let testImagePath = null;

  if (fs.existsSync(uploadsDir)) {
    const files = fs.readdirSync(uploadsDir).filter(f =>
      f.endsWith('.jpg') || f.endsWith('.png') || f.endsWith('.jpeg') || f.endsWith('.heic')
    );
    if (files.length > 0) {
      testImagePath = path.join(uploadsDir, files[0]);
    }
  }

  if (!testImagePath) {
    console.log('   ⚠️ 跳过: 未找到测试图片（uploads/photos/ 目录为空）');
    console.log('   💡 上传照片后可测试此功能');
    console.log('');
    return null;
  }

  console.log(`   使用图片: ${path.basename(testImagePath)}`);

  try {
    const imageBuffer = fs.readFileSync(testImagePath);
    const base64Data = imageBuffer.toString('base64');
    const mimeType = testImagePath.endsWith('.png') ? 'image/png' : 'image/jpeg';

    const interaction = await client.interactions.create({
      model: GEMINI_MODEL,
      input: [
        {
          inlineData: {
            mimeType,
            data: base64Data
          }
        },
        { text: '请判断这是猫还是狗，只回答“猫”或“狗”。' }
      ]
    });

    const outputs = interaction?.outputs || [];
    const last = outputs[outputs.length - 1] || {};
    const text = last.text || '';

    console.log('   ✅ 成功!');
    console.log(`   响应: "${text.trim()}"`);
    console.log('');
    return true;
  } catch (error) {
    console.error(`   ❌ 失败: ${error.message}`);
    console.log('');
    return false;
  }
}

async function main() {
  const okText = await testTextGeneration();
  const okVision = await testVisionAnalysis();

  if (okText || okVision) {
    console.log('✅ Gemini API 可用');
  } else {
    console.log('❌ Gemini API 不可用，请检查网络或 Key');
    process.exit(1);
  }
}

main();
