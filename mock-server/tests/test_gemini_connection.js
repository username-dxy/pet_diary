#!/usr/bin/env node

/**
 * Gemini API 连接测试脚本
 *
 * 用途：验证 GEMINI_API_KEY 是否有效，以及 API 是否可访问
 *
 * 运行方法：
 *   node test_gemini_connection.js
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_API_BASE_URL = process.env.GEMINI_API_BASE_URL || 'https://generativelanguage.googleapis.com/v1beta';
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash-image';

console.log('');
console.log('🧪 =====================================');
console.log('   Gemini API 连接测试');
console.log('=====================================');
console.log('');

// 检查环境变量
console.log('📋 配置检查:');
console.log(`   API Key: ${GEMINI_API_KEY ? '✅ 已设置 (' + GEMINI_API_KEY.substring(0, 10) + '...)' : '❌ 未设置'}`);
console.log(`   Base URL: ${GEMINI_API_BASE_URL}`);
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

// 测试 1: 简单文本生成
async function testTextGeneration() {
  console.log('🧪 测试 1: 文本生成能力');
  console.log('   发送提示: "用一句话介绍宠物日记应用"');

  const endpoint = `${GEMINI_API_BASE_URL}/models/${GEMINI_MODEL}:generateContent`;

  try {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': GEMINI_API_KEY
      },
      body: JSON.stringify({
        contents: [
          {
            role: 'user',
            parts: [
              { text: '用一句话介绍宠物日记应用。只回答一句话，不要解释。' }
            ]
          }
        ]
      })
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(`HTTP ${response.status}: ${error?.error?.message || 'Unknown error'}`);
    }

    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || '';

    console.log(`   ✅ 成功!`);
    console.log(`   响应: "${text.trim()}"`);
    console.log('');
    return true;
  } catch (error) {
    console.error(`   ❌ 失败: ${error.message}`);
    console.log('');
    return false;
  }
}

// 测试 2: 视觉识别（使用已上传的图片）
async function testVisionAnalysis() {
  console.log('🧪 测试 2: 视觉识别能力（宠物照片分析）');

  // 查找测试图片
  const uploadsDir = path.join(__dirname, 'uploads', 'photos');
  let testImagePath = null;

  if (fs.existsSync(uploadsDir)) {
    const files = fs.readdirSync(uploadsDir).filter(f =>
      f.endsWith('.jpg') || f.endsWith('.png') || f.endsWith('.jpeg')
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

    const endpoint = `${GEMINI_API_BASE_URL}/models/${GEMINI_MODEL}:generateContent`;

    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': GEMINI_API_KEY
      },
      body: JSON.stringify({
        contents: [
          {
            role: 'user',
            parts: [
              {
                inline_data: {
                  mime_type: mimeType,
                  data: base64Data
                }
              },
              {
                text: '这是什么动物？它看起来情绪如何？用简短一句话回答。'
              }
            ]
          }
        ]
      })
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(`HTTP ${response.status}: ${error?.error?.message || 'Unknown error'}`);
    }

    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || '';

    console.log(`   ✅ 成功!`);
    console.log(`   分析结果: "${text.trim()}"`);
    console.log('');
    return true;
  } catch (error) {
    console.error(`   ❌ 失败: ${error.message}`);
    console.log('');
    return false;
  }
}

// 测试 3: JSON 结构化输出（实际业务场景）
async function testStructuredOutput() {
  console.log('🧪 测试 3: 结构化 JSON 输出（模拟情绪分析）');

  const uploadsDir = path.join(__dirname, 'uploads', 'photos');
  let testImagePath = null;

  if (fs.existsSync(uploadsDir)) {
    const files = fs.readdirSync(uploadsDir).filter(f =>
      f.endsWith('.jpg') || f.endsWith('.png') || f.endsWith('.jpeg')
    );
    if (files.length > 0) {
      testImagePath = path.join(uploadsDir, files[0]);
    }
  }

  if (!testImagePath) {
    console.log('   ⚠️ 跳过: 未找到测试图片');
    console.log('');
    return null;
  }

  console.log(`   使用图片: ${path.basename(testImagePath)}`);

  const prompt = [
    'Analyze this pet photo and return STRICT JSON only.',
    'JSON format:',
    '{',
    '  "analysis": {',
    '    "emotion": "happy|calm|sad|angry|sleepy|curious",',
    '    "confidence": 0.85,',
    '    "reasoning": "short reason"',
    '  },',
    '  "pet_features": {',
    '    "species": "dog|cat|other",',
    '    "breed": "breed name",',
    '    "primary_color": "color"',
    '  }',
    '}',
    'Return JSON only, no other text.'
  ].join('\n');

  try {
    const imageBuffer = fs.readFileSync(testImagePath);
    const base64Data = imageBuffer.toString('base64');
    const mimeType = testImagePath.endsWith('.png') ? 'image/png' : 'image/jpeg';

    const endpoint = `${GEMINI_API_BASE_URL}/models/${GEMINI_MODEL}:generateContent`;

    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': GEMINI_API_KEY
      },
      body: JSON.stringify({
        contents: [
          {
            role: 'user',
            parts: [
              {
                inline_data: {
                  mime_type: mimeType,
                  data: base64Data
                }
              },
              { text: prompt }
            ]
          }
        ]
      })
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(`HTTP ${response.status}: ${error?.error?.message || 'Unknown error'}`);
    }

    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || '';

    // 尝试解析 JSON
    const trimmed = text.trim();
    let jsonMatch = trimmed;
    if (!trimmed.startsWith('{')) {
      const match = trimmed.match(/\{[\s\S]*\}/);
      if (match) jsonMatch = match[0];
    }

    const parsed = JSON.parse(jsonMatch);

    console.log(`   ✅ 成功!`);
    console.log(`   情绪: ${parsed?.analysis?.emotion} (${parsed?.analysis?.confidence})`);
    console.log(`   物种: ${parsed?.pet_features?.species}`);
    console.log(`   品种: ${parsed?.pet_features?.breed}`);
    console.log('');
    return true;
  } catch (error) {
    console.error(`   ❌ 失败: ${error.message}`);
    console.log('');
    return false;
  }
}

// 运行所有测试
async function runAllTests() {
  const results = [];

  results.push(await testTextGeneration());
  results.push(await testVisionAnalysis());
  results.push(await testStructuredOutput());

  console.log('=====================================');
  console.log('📊 测试结果汇总:');
  console.log('');

  const passed = results.filter(r => r === true).length;
  const failed = results.filter(r => r === false).length;
  const skipped = results.filter(r => r === null).length;

  console.log(`   ✅ 通过: ${passed}`);
  console.log(`   ❌ 失败: ${failed}`);
  console.log(`   ⚠️  跳过: ${skipped}`);
  console.log('');

  if (failed > 0) {
    console.log('❌ 部分测试失败，请检查:');
    console.log('   1. API Key 是否有效');
    console.log('   2. 网络连接是否正常');
    console.log('   3. API 配额是否充足');
    console.log('');
    process.exit(1);
  } else if (passed > 0) {
    console.log('✅ Gemini API 连接正常！');
    console.log('');
    process.exit(0);
  } else {
    console.log('⚠️ 所有测试被跳过（可能缺少测试数据）');
    console.log('');
    process.exit(0);
  }
}

// 执行测试
runAllTests().catch(error => {
  console.error('');
  console.error('❌ 测试执行出错:', error);
  console.error('');
  process.exit(1);
});
