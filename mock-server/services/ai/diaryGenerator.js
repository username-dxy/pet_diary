const fs = require('fs');
const path = require('path');

const ARK_API_BASE_URL =
  process.env.ARK_API_BASE_URL || 'https://ark.cn-beijing.volces.com/api/v3';
const ARK_VISION_MODEL =
  process.env.ARK_VISION_MODEL || 'doubao-1-5-vision-pro-32k-250115';
const ARK_API_KEY = process.env.ARK_API_KEY || '';

const VERBOSE = process.env.VERBOSE === 'true';

function inferMimeType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.png') return 'image/png';
  if (ext === '.webp') return 'image/webp';
  if (ext === '.heic') return 'image/heic';
  return 'image/jpeg';
}

/**
 * 构建日记生成的提示词
 * @param {Object} pet - 宠物信息
 * @param {string} date - 日期
 * @param {number} imageCount - 照片数量
 * @param {Array} otherPets - 同主人的其他宠物列表
 */
function buildDiaryPrompt(pet, date, imageCount, otherPets = []) {
  const speciesName = pet.species === 'cat' ? '猫咪' : pet.species === 'dog' ? '狗狗' : '宠物';
  const genderText = pet.gender === 'male' ? '男孩子' : pet.gender === 'female' ? '女孩子' : '';

  const otherPetsInfo = otherPets.length > 0
    ? `\n我的主人还养了其他宠物：${otherPets.map(p => `${p.name}(${p.species === 'cat' ? '猫' : p.species === 'dog' ? '狗' : '宠物'})`).join('、')}。如果照片中出现了它们，可以提到"我的兄弟/姐妹 XX"。`
    : '';

  return `你是一个${speciesName}，名叫"${pet.name}"，品种是${pet.breed || '可爱的' + speciesName}${genderText ? '，是个' + genderText : ''}${pet.personality ? '，性格' + pet.personality : ''}。你的主人叫你"${pet.ownerNickname || '主人'}"。${otherPetsInfo}

现在是${date}，请根据这${imageCount}张照片，以第一人称视角写一篇日记。

要求：
1. 用可爱、活泼的语气，像一只真正的${speciesName}在写日记
2. 描述照片中看到的场景、活动、情绪
3. 可以加入一些${speciesName}特有的动作描写（比如猫咪舔毛、狗狗摇尾巴）
4. 如果照片中出现了其他动物：
   - 如果是主人家的其他宠物，用"我的兄弟/姐妹 XX"来称呼
   - 如果是陌生的动物，描述为"遇到的那只XX"
5. 日记长度200-400字
6. 结尾可以加上${speciesName}特有的叫声（猫：喵呜~，狗：汪汪~）

请直接输出日记内容，不要加任何解释或前缀。用中文写。`;
}

/**
 * 调用 ARK Vision API 生成日记
 */
async function callArkVisionForDiary({ imageDataList, prompt }) {
  if (!ARK_API_KEY) {
    throw new Error('ARK_API_KEY 未配置');
  }

  // 构建消息内容：多张图片 + 文字提示
  const content = [
    ...imageDataList.map(img => ({
      type: 'image_url',
      image_url: { url: `data:${img.mimeType};base64,${img.base64Data}` }
    })),
    { type: 'text', text: prompt }
  ];

  if (VERBOSE) {
    console.log(`📝 [DiaryGen] 调用 ARK Vision，图片数量: ${imageDataList.length}`);
  }

  const response = await fetch(`${ARK_API_BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${ARK_API_KEY}`
    },
    body: JSON.stringify({
      model: ARK_VISION_MODEL,
      messages: [
        {
          role: 'user',
          content
        }
      ],
      max_tokens: 1024,
      temperature: 0.8  // 稍高温度让日记更有创意
    })
  });

  const payload = await response.json();

  if (!response.ok) {
    const errorMessage = payload?.error?.message || 'ARK Vision 请求失败';
    console.error('❌ [DiaryGen] ARK API 错误:', errorMessage);
    throw new Error(errorMessage);
  }

  const text = payload?.choices?.[0]?.message?.content || '';
  if (VERBOSE) {
    console.log(`✅ [DiaryGen] 生成日记成功，长度: ${text.length} 字符`);
  }

  return text;
}

/**
 * 分析照片中是否有其他动物
 */
async function analyzeOtherAnimals({ imageDataList }) {
  if (!ARK_API_KEY) {
    return [];
  }

  const prompt = `分析这些照片中出现的所有动物。返回 JSON 格式：
{
  "animals": [
    {"species": "cat|dog|other", "description": "简短描述", "is_main": true|false}
  ]
}
is_main 表示是否是照片的主角（通常是最显眼的那只）。只返回 JSON，不要其他文字。`;

  const content = [
    ...imageDataList.map(img => ({
      type: 'image_url',
      image_url: { url: `data:${img.mimeType};base64,${img.base64Data}` }
    })),
    { type: 'text', text: prompt }
  ];

  try {
    const response = await fetch(`${ARK_API_BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${ARK_API_KEY}`
      },
      body: JSON.stringify({
        model: ARK_VISION_MODEL,
        messages: [{ role: 'user', content }],
        max_tokens: 512
      })
    });

    const payload = await response.json();
    if (!response.ok) return [];

    const text = payload?.choices?.[0]?.message?.content || '';
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) return [];

    const result = JSON.parse(match[0]);
    return result.animals || [];
  } catch (e) {
    if (VERBOSE) {
      console.log('⚠️ [DiaryGen] 分析其他动物失败:', e.message);
    }
    return [];
  }
}

/**
 * 生成日记内容
 * @param {Object} options
 * @param {string[]} options.imagePaths - 照片路径列表
 * @param {Object} options.pet - 当前宠物信息
 * @param {string} options.date - 日期 (YYYY-MM-DD)
 * @param {Array} options.otherPets - 同主人的其他宠物
 */
async function generateDiary({ imagePaths, pet, date, otherPets = [] }) {
  if (!imagePaths || imagePaths.length === 0) {
    throw new Error('至少需要一张照片');
  }

  if (VERBOSE) {
    console.log('📖 ========== 开始生成日记 ==========');
    console.log(`🐱 宠物: ${pet.name} (${pet.species})`);
    console.log(`📅 日期: ${date}`);
    console.log(`📷 照片数量: ${imagePaths.length}`);
    console.log(`👥 其他宠物: ${otherPets.map(p => p.name).join(', ') || '无'}`);
  }

  // 读取所有图片并转换为 base64
  const imageDataList = imagePaths.map(imagePath => {
    const imageBuffer = fs.readFileSync(imagePath);
    return {
      base64Data: imageBuffer.toString('base64'),
      mimeType: inferMimeType(imagePath)
    };
  });

  // 构建提示词
  const prompt = buildDiaryPrompt(pet, date, imagePaths.length, otherPets);

  // 调用 ARK Vision 生成日记
  const diaryContent = await callArkVisionForDiary({ imageDataList, prompt });

  // 分析照片中的其他动物（可选，用于返回元数据）
  let mentionedAnimals = [];
  try {
    mentionedAnimals = await analyzeOtherAnimals({ imageDataList });
  } catch (e) {
    // 忽略分析失败
  }

  if (VERBOSE) {
    console.log('✅ ========== 日记生成完成 ==========');
  }

  return {
    content: diaryContent,
    mentionedAnimals,
    meta: {
      imageCount: imagePaths.length,
      generatedAt: new Date().toISOString(),
      model: ARK_VISION_MODEL
    }
  };
}

module.exports = { generateDiary };
