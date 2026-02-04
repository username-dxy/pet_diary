#!/usr/bin/env node

/**
 * 简化版 Gemini API 测试
 * 使用 curl 测试连接
 */

require('dotenv').config();
const { execSync } = require('child_process');

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_API_BASE_URL = process.env.GEMINI_API_BASE_URL || 'https://generativelanguage.googleapis.com/v1beta';
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash-image';

console.log('');
console.log('🧪 Gemini API 简化测试');
console.log('=====================================');
console.log('');
console.log('配置:');
console.log(`  API Key: ${GEMINI_API_KEY ? GEMINI_API_KEY.substring(0, 15) + '...' : '❌ 未设置'}`);
console.log(`  Model: ${GEMINI_MODEL}`);
console.log('');

if (!GEMINI_API_KEY) {
  console.error('❌ GEMINI_API_KEY 未设置');
  process.exit(1);
}

// 测试文本生成
console.log('🧪 测试 1: 基础文本生成');
console.log('');

const endpoint = `${GEMINI_API_BASE_URL}/models/${GEMINI_MODEL}:generateContent`;

const payload = {
  contents: [
    {
      role: 'user',
      parts: [
        { text: 'Say "Hello" in one word.' }
      ]
    }
  ]
};

try {
  console.log(`请求地址: ${endpoint}`);
  console.log('');

  const result = execSync(`curl -s -X POST "${endpoint}" \
    -H "Content-Type: application/json" \
    -H "x-goog-api-key: ${GEMINI_API_KEY}" \
    -d '${JSON.stringify(payload)}'`,
    { encoding: 'utf-8', maxBuffer: 10 * 1024 * 1024 }
  );

  const response = JSON.parse(result);

  if (response.error) {
    console.log('❌ API 返回错误:');
    console.log(`   状态: ${response.error.code}`);
    console.log(`   信息: ${response.error.message}`);
    console.log('');

    if (response.error.code === 400) {
      console.log('💡 可能的原因:');
      console.log('   - API Key 无效');
      console.log('   - 模型名称错误');
      console.log('');
    } else if (response.error.code === 429) {
      console.log('💡 可能的原因:');
      console.log('   - API 配额已用完');
      console.log('   - 请求频率过高');
      console.log('');
    }

    process.exit(1);
  }

  const text = response?.candidates?.[0]?.content?.parts?.[0]?.text || '';

  console.log('✅ 连接成功!');
  console.log(`响应: "${text.trim()}"`);
  console.log('');
  console.log('完整响应:');
  console.log(JSON.stringify(response, null, 2));
  console.log('');
  console.log('✅ Gemini API 工作正常！');
  console.log('');

} catch (error) {
  console.error('❌ 测试失败:');
  console.error(error.message);
  console.log('');
  console.log('💡 可能的原因:');
  console.log('   1. 网络连接问题（无法访问 Google API）');
  console.log('   2. API Key 无效或已过期');
  console.log('   3. 防火墙或代理阻止连接');
  console.log('');
  console.log('💡 手动测试命令:');
  console.log('');
  console.log(`curl -X POST "${endpoint}" \\`);
  console.log(`  -H "Content-Type: application/json" \\`);
  console.log(`  -H "x-goog-api-key: ${GEMINI_API_KEY}" \\`);
  console.log(`  -d '{"contents":[{"role":"user","parts":[{"text":"Hello"}]}]}'`);
  console.log('');

  process.exit(1);
}
