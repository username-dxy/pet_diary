#!/usr/bin/env node
/**
 * 测试 AI 日记生成 API
 *
 * 使用方法:
 *   node tests/test_diary_generate.js [图片路径]
 *
 * 示例:
 *   node tests/test_diary_generate.js uploads/photos/test.jpg
 */

const fs = require('fs');
const path = require('path');
const http = require('http');

const SERVER_HOST = process.env.SERVER_HOST || 'localhost';
const SERVER_PORT = process.env.SERVER_PORT || 3000;
const TOKEN = process.env.TOKEN || 'test123';

/**
 * 发送 multipart/form-data 请求
 */
function sendMultipartRequest(options, fields, files) {
  return new Promise((resolve, reject) => {
    const boundary = '----FormBoundary' + Math.random().toString(36).substring(2);
    const parts = [];

    // 添加普通字段
    for (const [key, value] of Object.entries(fields)) {
      parts.push(
        `--${boundary}\r\n` +
        `Content-Disposition: form-data; name="${key}"\r\n\r\n` +
        `${value}\r\n`
      );
    }

    // 添加文件
    for (const file of files) {
      const content = fs.readFileSync(file.path);
      const filename = path.basename(file.path);
      const mimeType = file.mimeType || 'application/octet-stream';

      parts.push(
        `--${boundary}\r\n` +
        `Content-Disposition: form-data; name="${file.fieldName}"; filename="${filename}"\r\n` +
        `Content-Type: ${mimeType}\r\n\r\n`
      );
      parts.push(content);
      parts.push('\r\n');
    }

    parts.push(`--${boundary}--\r\n`);

    // 计算总长度
    let totalLength = 0;
    const buffers = parts.map(part => {
      const buf = Buffer.isBuffer(part) ? part : Buffer.from(part, 'utf-8');
      totalLength += buf.length;
      return buf;
    });

    const body = Buffer.concat(buffers, totalLength);

    const reqOptions = {
      ...options,
      method: 'POST',
      headers: {
        ...options.headers,
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
        'Content-Length': body.length
      }
    };

    const req = http.request(reqOptions, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, data: data });
        }
      });
    });

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function testDiaryGenerate(imagePath) {
  console.log('📖 ========== 测试 AI 日记生成 ==========\n');

  // 查找测试图片
  let testImagePath = imagePath;
  if (!testImagePath) {
    // 尝试在 uploads 目录下找一张图片
    const uploadsDir = path.join(__dirname, '..', 'uploads', 'photos');
    if (fs.existsSync(uploadsDir)) {
      const files = fs.readdirSync(uploadsDir).filter(f =>
        /\.(jpg|jpeg|png|webp)$/i.test(f)
      );
      if (files.length > 0) {
        testImagePath = path.join(uploadsDir, files[0]);
        console.log(`📷 自动选择测试图片: ${files[0]}`);
      }
    }
  }

  if (!testImagePath || !fs.existsSync(testImagePath)) {
    console.error('❌ 请提供有效的图片路径');
    console.log('\n使用方法: node tests/test_diary_generate.js <图片路径>');
    process.exit(1);
  }

  console.log(`📷 测试图片: ${testImagePath}`);
  console.log(`🌐 服务器: http://${SERVER_HOST}:${SERVER_PORT}`);
  console.log('');

  // 构建宠物信息
  const pet = {
    id: 'test-pet-1',
    name: '橘子',
    species: 'cat',
    breed: '橘猫',
    gender: 'male',
    personality: '活泼好动，喜欢撒娇',
    ownerNickname: '铲屎官'
  };

  const today = new Date().toISOString().split('T')[0];

  // 其他宠物（可选）
  const otherPets = [
    { id: 'test-pet-2', name: '小黑', species: 'cat' }
  ];

  console.log('📤 发送请求...');
  console.log(`   宠物: ${pet.name} (${pet.species})`);
  console.log(`   日期: ${today}`);
  console.log(`   其他宠物: ${otherPets.map(p => p.name).join(', ')}`);
  console.log('');

  try {
    const result = await sendMultipartRequest(
      {
        hostname: SERVER_HOST,
        port: SERVER_PORT,
        path: '/api/chongyu/ai/diary/generate',
        headers: { 'token': TOKEN }
      },
      {
        'pet': JSON.stringify(pet),
        'date': today,
        'otherPets': JSON.stringify(otherPets)
      },
      [
        {
          fieldName: 'images',
          path: testImagePath,
          mimeType: 'image/jpeg'
        }
      ]
    );

    if (result.status === 200 && result.data.success) {
      console.log('✅ 日记生成成功!\n');
      console.log('📝 ========== 日记内容 ==========\n');
      console.log(result.data.data.content);
      console.log('\n================================\n');

      if (result.data.data.mentionedAnimals?.length > 0) {
        console.log('🐾 识别到的动物:');
        result.data.data.mentionedAnimals.forEach(animal => {
          console.log(`   - ${animal.species}: ${animal.description}`);
        });
        console.log('');
      }

      console.log('📊 元数据:');
      console.log(`   模型: ${result.data.data.meta?.model || 'unknown'}`);
      console.log(`   图片数: ${result.data.data.meta?.imageCount || 1}`);
      console.log(`   生成时间: ${result.data.data.meta?.generatedAt || 'unknown'}`);
    } else {
      console.error('❌ 请求失败:', result.data?.error?.message || result.data);
    }
  } catch (error) {
    console.error('❌ 请求异常:', error.message);
  }
}

// 运行测试
const imagePath = process.argv[2];
testDiaryGenerate(imagePath);
