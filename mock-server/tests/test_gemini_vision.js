#!/usr/bin/env node

/**
 * 测试 Gemini Vision API（图片识别）
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_API_BASE_URL = process.env.GEMINI_API_BASE_URL || 'https://generativelanguage.googleapis.com/v1beta';
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash-image';

console.log('');
console.log('🧪 Gemini Vision API 测试');
console.log('=====================================');
console.log('');

if (!GEMINI_API_KEY) {
  console.error('❌ GEMINI_API_KEY 未设置');
  process.exit(1);
}

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
  console.log('❌ 未找到测试图片');
  console.log('');
  console.log('💡 请上传宠物照片到 mock-server/uploads/photos/ 目录');
  console.log('');
  process.exit(1);
}

console.log(`📸 使用图片: ${path.basename(testImagePath)}`);
console.log('');

// 读取图片并转换为 base64
const imageBuffer = fs.readFileSync(testImagePath);
const base64Data = imageBuffer.toString('base64');
const mimeType = testImagePath.endsWith('.png') ? 'image/png' : 'image/jpeg';

console.log(`   类型: ${mimeType}`);
console.log(`   大小: ${(imageBuffer.length / 1024).toFixed(2)} KB`);
console.log('');

// 测试 1: 简单描述
console.log('🧪 测试 1: 图片内容描述');

const prompt1 = '这是什么动物？用一句话描述。';

const payload1 = {
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
        { text: prompt1 }
      ]
    }
  ]
};

try {
  const tmpFile1 = '/tmp/gemini_payload_1.json';
  fs.writeFileSync(tmpFile1, JSON.stringify(payload1));

  const endpoint = `${GEMINI_API_BASE_URL}/models/${GEMINI_MODEL}:generateContent`;
  const result = execSync(`curl -s -X POST "${endpoint}" \
    -H "Content-Type: application/json" \
    -H "x-goog-api-key: ${GEMINI_API_KEY}" \
    -d @${tmpFile1}`,
    { encoding: 'utf-8', maxBuffer: 20 * 1024 * 1024 }
  );

  const response = JSON.parse(result);

  if (response.error) {
    console.log(`❌ 失败: ${response.error.message}`);
  } else {
    const text = response?.candidates?.[0]?.content?.parts?.[0]?.text || '';
    console.log(`✅ 成功!`);
    console.log(`   识别结果: ${text.trim()}`);
  }

  fs.unlinkSync(tmpFile1);
} catch (error) {
  console.error(`❌ 错误: ${error.message}`);
}

console.log('');

// 测试 2: 结构化 JSON 输出（实际业务场景）
console.log('🧪 测试 2: 情绪分析（结构化 JSON）');

const prompt2 = [
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
  'Return JSON only, no markdown, no other text.'
].join('\n');

const payload2 = {
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
        { text: prompt2 }
      ]
    }
  ]
};

try {
  const tmpFile2 = '/tmp/gemini_payload_2.json';
  fs.writeFileSync(tmpFile2, JSON.stringify(payload2));

  const endpoint = `${GEMINI_API_BASE_URL}/models/${GEMINI_MODEL}:generateContent`;
  const result = execSync(`curl -s -X POST "${endpoint}" \
    -H "Content-Type: application/json" \
    -H "x-goog-api-key: ${GEMINI_API_KEY}" \
    -d @${tmpFile2}`,
    { encoding: 'utf-8', maxBuffer: 20 * 1024 * 1024 }
  );

  const response = JSON.parse(result);

  if (response.error) {
    console.log(`❌ 失败: ${response.error.message}`);
  } else {
    const text = response?.candidates?.[0]?.content?.parts?.[0]?.text || '';

    // 尝试解析 JSON
    try {
      const trimmed = text.trim();
      let jsonMatch = trimmed;

      // 去除 markdown 代码块
      if (trimmed.startsWith('```')) {
        const match = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/);
        if (match) jsonMatch = match[1].trim();
      }

      // 提取 JSON 对象
      if (!jsonMatch.startsWith('{')) {
        const match = jsonMatch.match(/\{[\s\S]*\}/);
        if (match) jsonMatch = match[0];
      }

      const parsed = JSON.parse(jsonMatch);

      console.log(`✅ 成功!`);
      console.log('');
      console.log('📊 分析结果:');
      console.log(`   情绪: ${parsed?.analysis?.emotion}`);
      console.log(`   置信度: ${parsed?.analysis?.confidence}`);
      console.log(`   原因: ${parsed?.analysis?.reasoning}`);
      console.log(`   物种: ${parsed?.pet_features?.species}`);
      console.log(`   品种: ${parsed?.pet_features?.breed}`);
      console.log(`   颜色: ${parsed?.pet_features?.primary_color}`);
      console.log('');
      console.log('原始 JSON:');
      console.log(JSON.stringify(parsed, null, 2));

    } catch (parseError) {
      console.log(`⚠️ JSON 解析失败（但 API 调用成功）`);
      console.log(`原始响应: ${text.substring(0, 200)}...`);
    }
  }

  fs.unlinkSync(tmpFile2);
} catch (error) {
  console.error(`❌ 错误: ${error.message}`);
}

console.log('');
console.log('=====================================');
console.log('✅ Vision API 测试完成！');
console.log('');
