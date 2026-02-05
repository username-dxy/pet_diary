#!/usr/bin/env node

/**
 * 简化版 Gemini API 测试（SDK 版本）
 */

require('dotenv').config();
const { GoogleGenAI } = require('@google/genai');

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash-image';

console.log('');
console.log('🧪 Gemini API 简化测试（SDK）');
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

async function main() {
  const client = new GoogleGenAI({ apiKey: GEMINI_API_KEY });

  console.log('🧪 测试 1: 基础文本生成');
  console.log('');

  try {
    const interaction = await client.interactions.create({
      model: GEMINI_MODEL,
      input: 'Say "Hello" in one word.'
    });

    const outputs = interaction?.outputs || [];
    const last = outputs[outputs.length - 1] || {};
    const text = last.text || '';

    console.log('✅ 连接成功!');
    console.log(`响应: "${text.trim()}"`);
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
    process.exit(1);
  }
}

main();
