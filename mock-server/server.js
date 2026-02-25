const path = require('path');

// 加载环境变量（固定读取 mock-server/.env，避免启动目录不同导致失效）
require('dotenv').config({ path: path.join(__dirname, '.env') });

const express = require('express');
const multer = require('multer');
const cors = require('cors');
const bodyParser = require('body-parser');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const { generateStickerPipeline, generateDiary } = require('./services/ai');

const app = express();

// 从环境变量读取配置，提供默认值
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';
const DB_FILE_NAME = process.env.DB_FILE || 'db.json';
const UPLOAD_DIR = process.env.UPLOAD_DIR || 'uploads';
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';
const VERBOSE = process.env.VERBOSE === 'true';
const STICKER_IMAGE_PROVIDER =
  (process.env.STICKER_IMAGE_PROVIDER || 'gemini').toLowerCase().trim();
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash-image';
const GEMINI_IMAGE_MODEL =
  process.env.GEMINI_IMAGE_MODEL || 'gemini-2.5-flash-image';
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const SEEDREAM_MODEL =
  process.env.SEEDREAM_MODEL || 'doubao-seedream-4-5-251128';
const SEEDREAM_API_KEY =
  process.env.SEEDREAM_API_KEY || process.env.ARK_API_KEY || '';

// 中间件
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// 静态文件服务（访问上传的照片）
app.use('/uploads', express.static(UPLOAD_DIR));

// 确保上传目录存在
const uploadDirs = [
  path.join(UPLOAD_DIR, 'profiles'),
  path.join(UPLOAD_DIR, 'photos')
];
uploadDirs.forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// 内存数据库（简单起见，生产环境应使用真实数据库）
let database = {
  pets: [],
  photos: [],
  pet_photos: [],
  diaries: [],
  users: []
};

// 从文件加载数据（持久化）
const DB_FILE = path.join(__dirname, DB_FILE_NAME);
if (fs.existsSync(DB_FILE)) {
  try {
    database = JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
    if (VERBOSE) console.log('✅ 数据库已加载');
  } catch (error) {
    console.error('❌ 加载数据库失败:', error);
  }
}

// 保存数据到文件
function saveDatabase() {
  fs.writeFileSync(DB_FILE, JSON.stringify(database, null, 2));
}

// Multer配置（文件上传）
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const subfolder = req.path.includes('profile') ? 'profiles' : 'photos';
    const folder = path.join(UPLOAD_DIR, subfolder);
    cb(null, folder);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    const filename = `${uuidv4()}${ext}`;
    cb(null, filename);
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB限制
  fileFilter: (req, file, cb) => {
    const allowedTypes = [
      'image/jpeg',
      'image/png',
      'image/jpg',
      'image/heic',
      'image/heif',
      'image/heic-sequence',
      'image/heif-sequence',
      // 某些客户端不会正确设置 Content-Type
      'application/octet-stream'
    ];
    const ext = path.extname(file.originalname || '').toLowerCase();
    const allowedExts = ['.jpg', '.jpeg', '.png', '.heic', '.heif'];
    if (allowedTypes.includes(file.mimetype) || allowedExts.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('只支持 JPEG/PNG/HEIC 格式的图片'));
    }
  }
});

// ==================== 辅助函数 ====================

// 标准响应格式
function successResponse(data) {
  return { success: true, data };
}

function errorResponse(message, code) {
  return { success: false, error: { message, code } };
}

function shouldLogHttp() {
  return ['debug', 'info'].includes(String(LOG_LEVEL).toLowerCase());
}

function summarizePayload(payload, maxLen = 600) {
  if (payload === undefined || payload === null) return String(payload);

  let text = '';
  if (Buffer.isBuffer(payload)) {
    text = `<Buffer length=${payload.length}>`;
  } else if (typeof payload === 'string') {
    text = payload;
  } else {
    try {
      text = JSON.stringify(payload);
    } catch (_) {
      text = '[Unserializable payload]';
    }
  }

  if (text.length <= maxLen) return text;
  return `${text.slice(0, maxLen)}... [truncated ${text.length - maxLen} chars]`;
}

function httpLogger(req, res, next) {
  if (!shouldLogHttp()) {
    return next();
  }

  const start = Date.now();
  const queryText =
    req.query && Object.keys(req.query).length > 0
      ? ` query=${summarizePayload(req.query, 240)}`
      : '';
  const bodyText =
    req.body && Object.keys(req.body).length > 0
      ? ` body=${summarizePayload(req.body, 300)}`
      : '';
  console.log(`[HTTP] -> ${req.method} ${req.originalUrl}${queryText}${bodyText}`);

  let responseBody;
  const originalJson = res.json.bind(res);
  const originalSend = res.send.bind(res);

  res.json = function patchedJson(body) {
    responseBody = body;
    return originalJson(body);
  };

  res.send = function patchedSend(body) {
    responseBody = body;
    return originalSend(body);
  };

  res.on('finish', () => {
    const cost = Date.now() - start;
    const responseText =
      responseBody === undefined ? '' : ` body=${summarizePayload(responseBody, 600)}`;
    console.log(
      `[HTTP] <- ${req.method} ${req.originalUrl} ${res.statusCode} ${cost}ms${responseText}`
    );
  });

  next();
}

function normalizeUrl(req, url) {
  if (!url) return url;
  const host = req.get('host') || `localhost:${PORT}`;
  const protocol = req.protocol || 'http';

  try {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      const u = new URL(url);
      return `${protocol}://${host}${u.pathname}`;
    }
  } catch (_) {
    // fallthrough to handle as relative path
  }

  if (url.startsWith('/')) {
    return `${protocol}://${host}${url}`;
  }
  return `${protocol}://${host}/${url}`;
}

function normalizeMediaUrl(req, url) {
  if (!url) return url;
  if (typeof url !== 'string') return url;
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  return normalizeUrl(req, url);
}

function normalizeDiaryList(req, diaries) {
  return diaries.map(d => ({
    ...d,
    avatar: normalizeUrl(req, d.avatar || d.imagePath || ''),
    imageList: Array.isArray(d.imageList)
      ? d.imageList.map(u => normalizeUrl(req, u))
      : d.imageList
  }));
}

function toPetType(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value === 1 || value === 2 ? value : 0;
  }
  const v = String(value || '').toLowerCase();
  if (v === 'dog') return 1;
  if (v === 'cat') return 2;
  return 0;
}

function toPetGender(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value === 1 || value === 2 ? value : 0;
  }
  const v = String(value || '').toLowerCase();
  if (v === 'male') return 1;
  if (v === 'female') return 2;
  return 0;
}

function petTypeToSpecies(type) {
  switch (toPetType(type)) {
    case 1:
      return 'dog';
    case 2:
      return 'cat';
    default:
      return 'unknown';
  }
}

function petGenderToString(gender) {
  switch (toPetGender(gender)) {
    case 1:
      return 'male';
    case 2:
      return 'female';
    default:
      return 'unknown';
  }
}

function toEmotionInt(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    const n = Math.trunc(value);
    return n >= 0 && n <= 6 ? n : 0;
  }
  const v = String(value || '').toLowerCase();
  const map = {
    happy: 1,
    calm: 2,
    sad: 3,
    angry: 4,
    sleepy: 5,
    curious: 6,
  };
  return map[v] || 0;
}

function normalizeEmotionRecord(record, req) {
  return {
    ...record,
    aiEmotion: toEmotionInt(record.aiEmotion),
    selectedEmotion: toEmotionInt(record.selectedEmotion),
    stickerUrl: normalizeMediaUrl(req, record.stickerUrl),
  };
}

// 内部 pet → api.md 格式映射
function mapPetToApi(pet) {
  const type = toPetType(pet.type ?? pet.species);
  const gender = toPetGender(pet.gender);
  return {
    petId: pet.id,
    type,
    gender,
    birthday: pet.birthday || '',
    ownerTitle: pet.ownerNickname || '',
    avatar: pet.profilePhotoPath || '',
    nickName: pet.name || '',
    character: pet.personality || '',
    description: pet.breed || '',
  };
}

// ==================== Token 中间件 ====================

function tokenMiddleware(req, res, next) {
  const token = req.headers['token'];
  if (!token) {
    return res.status(401).json(errorResponse('未授权', 401));
  }
  next();
}

// 对所有 /api/chongyu/ 路由应用 token 验证
app.use('/api/chongyu', httpLogger);
app.use('/api/chongyu', tokenMiddleware);

// ==================== 路由定义 ====================

// 根路径
app.get('/', (req, res) => {
  res.json({
    message: 'Pet Diary Mock Server',
    version: '1.0.0',
    endpoints: {
      chongyu: {
        'GET /api/chongyu/pet/list': '查询宠物列表',
        'GET /api/chongyu/pet/detail': '查询宠物/日记详情',
        'POST /api/chongyu/image/list/upload': '批量上传相册图片',
        'GET /api/chongyu/pet/photos': '查询宠物照片',
        'POST /api/chongyu/pets/profile': '同步宠物档案',
        'GET /api/chongyu/pets/:petId/profile': '获取宠物档案',
        'POST /api/chongyu/upload/profile-photo': '上传头像照片',
        'POST /api/chongyu/upload/photo': '上传普通照片',
        'GET /api/chongyu/photos/:photoId': '获取照片信息',
        'POST /api/chongyu/diaries': '创建日记',
        'GET /api/chongyu/diaries': '获取日记列表',
        'GET /api/chongyu/diaries/:diaryId': '获取日记详情',
        'POST /api/chongyu/emotions/save': '保存情绪记录',
        'GET /api/chongyu/emotions/month': '按月查询情绪记录',
        'GET /api/chongyu/stats': '获取服务器统计信息',
        'POST /api/chongyu/ai/sticker/generate': '生成贴纸（AI 管线）',
        'POST /api/chongyu/ai/diary/generate': '生成日记文字（AI 管线）',
        'POST /api/chongyu/ai/diary/auto-generate': '基于已上传照片自动生成日记'
      }
    }
  });
});

// ==================== AI Pipeline ====================

// 生成贴纸（Emotion → Prompt → Sticker）
app.post('/api/chongyu/ai/sticker/generate', upload.single('image'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json(errorResponse('未接收到图片文件', 400));
  }

  try {
    const host = req.get('host') || `localhost:${PORT}`;
    const protocol = req.protocol || 'http';
    const result = await generateStickerPipeline({
      imagePath: req.file.path,
      host,
      protocol
    });
    if (result?.analysis) {
      result.analysis.emotion = toEmotionInt(result.analysis.emotion);
    }
    res.json(successResponse(result));
  } catch (error) {
    console.error('❌ AI 贴纸生成失败:', error);
    // 兜底：返回原图作为贴纸，避免客户端长时间等待
    const host = req.get('host') || `localhost:${PORT}`;
    const protocol = req.protocol || 'http';
    const relPath = String(req.file.path || '').replace(/\\/g, '/');
    const idx = relPath.indexOf(UPLOAD_DIR);
    const publicPath = idx >= 0 ? relPath.substring(idx) : relPath;
    const imageUrl = normalizeUrl(req, publicPath);

    const fallback = {
      analysis: {
        emotion: 2,
        confidence: 0.0,
        reasoning: 'fallback'
      },
      pet_features: {
        species: 'other',
        breed: '宠物',
        primary_color: 'unknown',
        markings: 'unknown',
        eye_color: 'unknown',
        pose: 'unknown'
      },
      sticker: {
        style: 'fallback',
        prompt: '',
        imageUrl
      },
      meta: {
        pipelineVersion: 'fallback',
        generatedAt: new Date().toISOString(),
        error: error?.message || 'AI 贴纸生成失败'
      }
    };

    res.json(successResponse(fallback));
  }
});

// 生成日记文字（AI 管线）
app.post('/api/chongyu/ai/diary/generate', upload.array('images', 10), async (req, res) => {
  if (!req.files || req.files.length === 0) {
    return res.status(400).json(errorResponse('未接收到图片文件', 400));
  }

  try {
    // 解析宠物信息
    const petJson = req.body.pet;
    if (!petJson) {
      return res.status(400).json(errorResponse('缺少 pet 参数', 400));
    }

    let pet;
    try {
      pet = typeof petJson === 'string' ? JSON.parse(petJson) : petJson;
    } catch (e) {
      return res.status(400).json(errorResponse('pet 参数格式错误', 400));
    }

    const date = req.body.date || new Date().toISOString().split('T')[0];

    // 解析同主人的其他宠物（可选）
    let otherPets = [];
    if (req.body.otherPets) {
      try {
        otherPets = typeof req.body.otherPets === 'string'
          ? JSON.parse(req.body.otherPets)
          : req.body.otherPets;
      } catch (e) {
        // 忽略解析错误
      }
    }

    if (VERBOSE) {
      console.log('📖 [DiaryGen] 开始生成日记');
      console.log(`   宠物: ${pet.name} (${pet.id})`);
      console.log(`   日期: ${date}`);
      console.log(`   图片数量: ${req.files.length}`);
      console.log(`   其他宠物: ${otherPets.length} 只`);
    }

    const imagePaths = req.files.map(f => f.path);

    const result = await generateDiary({
      imagePaths,
      pet,
      date,
      otherPets
    });

    if (VERBOSE) {
      console.log(`✅ [DiaryGen] 日记生成成功，长度: ${result.content.length} 字符`);
    }

    res.json(successResponse(result));
  } catch (error) {
    console.error('❌ AI 日记生成失败:', error);
    res.status(500).json(errorResponse(error.message || 'AI 日记生成失败', 500));
  }
});

// 自动生成某天日记（使用服务端已上传照片）
app.post('/api/chongyu/ai/diary/auto-generate', async (req, res) => {
  try {
    const petId = req.body.petId;
    const date = req.body.date || new Date().toISOString().split('T')[0];

    if (!petId) {
      return res.status(400).json(errorResponse('缺少 petId 参数', 400));
    }

    const pet = database.pets.find(p => p.id === petId);
    if (!pet) {
      return res.status(404).json(errorResponse('宠物不存在', 404));
    }

    if (!database.pet_photos) {
      database.pet_photos = [];
    }

    const dayPhotos = database.pet_photos.filter(p => p.petId === petId && p.date === date);
    if (dayPhotos.length === 0) {
      return res.json(successResponse({
        generated: false,
        reason: 'NO_PHOTOS',
        date
      }));
    }

    const existingDiary = database.diaries.find(d => d.petId === petId && d.date === date);
    if (existingDiary && existingDiary.content && existingDiary.content.trim()) {
      return res.json(successResponse({
        generated: false,
        reason: 'ALREADY_GENERATED',
        diaryId: existingDiary.id,
        contentLength: existingDiary.content.length,
        date
      }));
    }

    const imagePaths = dayPhotos
      .map(photo => {
        if (photo.localPath && fs.existsSync(photo.localPath)) {
          return photo.localPath;
        }
        const photoUrl = String(photo.url || '');
        const marker = '/uploads/';
        const markerIndex = photoUrl.indexOf(marker);
        if (markerIndex < 0) return null;
        const relative = photoUrl.substring(markerIndex + 1);
        const diskPath = path.join(__dirname, relative);
        if (fs.existsSync(diskPath)) return diskPath;
        return null;
      })
      .filter(Boolean);

    if (imagePaths.length === 0) {
      return res.json(successResponse({
        generated: false,
        reason: 'NO_LOCAL_IMAGES',
        date
      }));
    }

    const otherPets = database.pets
      .filter(p => p.id !== petId)
      .map(p => ({
        id: p.id,
        name: p.name,
        species: p.species
      }));

    const generated = await generateDiary({
      imagePaths,
      pet,
      date,
      otherPets
    });

    const imageList = dayPhotos
      .map(p => p.url)
      .filter(Boolean);
    const imagePath = imageList[0] || '';

    if (existingDiary) {
      existingDiary.content = generated.content || existingDiary.content;
      existingDiary.title = existingDiary.title || '';
      existingDiary.imagePath = existingDiary.imagePath || imagePath;
      existingDiary.imageList = imageList.length > 0 ? imageList : (existingDiary.imageList || []);
      existingDiary.syncedAt = new Date().toISOString();
    } else {
      database.diaries.push({
        id: uuidv4(),
        petId,
        date,
        title: '',
        content: generated.content || '',
        imagePath,
        emotion: 0,
        imageList,
        isLocked: false,
        createdAt: new Date().toISOString(),
        syncedAt: new Date().toISOString()
      });
    }

    saveDatabase();

    const diary = database.diaries.find(d => d.petId === petId && d.date === date);
    return res.json(successResponse({
      generated: true,
      diaryId: diary?.id || '',
      contentLength: (diary?.content || '').length,
      date
    }));
  } catch (error) {
    console.error('❌ 自动生成日记失败:', error);
    return res.status(500).json(errorResponse(error.message || '自动生成日记失败', 500));
  }
});

// ==================== /api/chongyu 路由 ====================

// 查询宠物列表
app.get('/api/chongyu/pet/list', (req, res) => {
  if (VERBOSE) console.log('📋 查询宠物列表');

  const petList = database.pets.map(mapPetToApi);

  res.json(successResponse({ petList }));
});

// 查询宠物详情 / 日记详情（共用路径）
app.get('/api/chongyu/pet/detail', (req, res) => {
  const { petId, diaryId, date } = req.query;

  if (!petId) {
    return res.status(400).json(errorResponse('缺少 petId 参数', 400));
  }

  // 如果有 diaryId 或 date，返回日记详情
  if (diaryId || date) {
    let diary;
    if (diaryId) {
      diary = database.diaries.find(d => d.id === diaryId && d.petId === petId);
    } else {
      diary = database.diaries.find(d => d.date === date && d.petId === petId);
    }

    if (!diary) {
      return res.status(404).json(errorResponse('日记不存在', 404));
    }

    if (VERBOSE) console.log('📔 查询日记详情:', diaryId || date);

    // 动态从 pet_photos 构建 imageList，合并已有的 diary.imageList
    let imageList = diary.imageList ? [...diary.imageList] : [];
    if (database.pet_photos) {
      const petPhotos = database.pet_photos
        .filter(p => p.petId === petId && p.date === diary.date)
        .map(p => p.url);
      for (const url of petPhotos) {
        if (!imageList.includes(url)) {
          imageList.push(url);
        }
      }
    }

    return res.json(successResponse({
      date: diary.date || '',
      title: diary.title || '',
      avatar: normalizeUrl(req, diary.imagePath || ''),
      emotion: diary.emotion || 0,
      content: diary.content || '',
      imageList: Array.isArray(imageList)
        ? imageList.map(u => normalizeUrl(req, u))
        : imageList,
    }));
  }

  // 否则返回宠物详情
  const pet = database.pets.find(p => p.id === petId);
  if (!pet) {
    return res.status(404).json(errorResponse('宠物不存在', 404));
  }

  if (VERBOSE) console.log('🐾 查询宠物详情:', petId);

  const detail = mapPetToApi(pet);
  const normalized = {
    ...detail,
    avatar: normalizeUrl(req, detail.avatar)
  };
  res.json(successResponse(normalized));
});

// 批量上传相册图片（支持 pet_photos 去重）
app.post('/api/chongyu/image/list/upload', upload.array('image', 20), (req, res) => {
  if (!req.files || req.files.length === 0) {
    return res.status(400).json(errorResponse('未接收到图片文件', 400));
  }

  // 确保 pet_photos 集合存在
  if (!database.pet_photos) {
    database.pet_photos = [];
  }

  const host = req.get('host') || `localhost:${PORT}`;
  const protocol = req.protocol || 'http';

  let uploaded = 0;
  let duplicates = 0;

  req.files.forEach((file, index) => {
    const petId = req.body[`petId_${index}`] || null;
    const date = req.body[`date_${index}`] || null;
    const assetId = req.body[`assetId_${index}`] || null;
    const time = req.body[`time_${index}`] || null;
    const location = req.body[`location_${index}`] || null;
    const url = `${protocol}://${host}/uploads/photos/${file.filename}`;

    // 去重：同一 assetId + petId 不重复入库
    if (assetId && petId) {
      const existing = database.pet_photos.find(
        p => p.assetId === assetId && p.petId === petId
      );
      if (existing) {
        duplicates++;
        if (VERBOSE) console.log(`⏭️ 跳过重复照片: assetId=${assetId}`);
        return;
      }
    }

    // 存入 pet_photos
    const petPhoto = {
      id: uuidv4(),
      petId: petId,
      date: date,
      assetId: assetId,
      url: url,
      localPath: file.path,
      size: file.size,
      time: time,
      location: location,
      uploadedAt: new Date().toISOString()
    };
    database.pet_photos.push(petPhoto);
    uploaded++;

    // 同时存入 photos（向后兼容）
    database.photos.push({
      id: petPhoto.id,
      url: url,
      localPath: file.path,
      size: file.size,
      mimeType: file.mimetype,
      time: time,
      location: location,
      uploadedAt: petPhoto.uploadedAt
    });

    // 如果有 petId 和 date，自动更新/创建 diary 的 imageList
    if (petId && date) {
      const diary = database.diaries.find(d => d.petId === petId && d.date === date);
      if (diary) {
        // 更新已有 diary 的 imageList
        if (!diary.imageList) diary.imageList = [];
        if (!diary.imageList.includes(url)) {
          diary.imageList.push(url);
        }
      } else {
        // 自动创建占位 diary
        const photosForDay = database.pet_photos
          .filter(p => p.petId === petId && p.date === date)
          .map(p => p.url);
        // 加上当前这张（刚 push 进去的也在里面了）
        if (!photosForDay.includes(url)) photosForDay.push(url);

        database.diaries.push({
          id: uuidv4(),
          petId: petId,
          date: date,
          title: '',
          content: '',
          imagePath: photosForDay[0] || '',
          emotion: 0,
          imageList: photosForDay,
          isLocked: false,
          createdAt: new Date().toISOString(),
          syncedAt: new Date().toISOString()
        });
      }
    }
  });

  saveDatabase();

  if (LOG_LEVEL === 'info' || LOG_LEVEL === 'debug') {
    console.log(`✅ 批量上传完成: 上传=${uploaded}, 重复跳过=${duplicates}`);
  }

  res.json(successResponse({ uploaded, duplicates }));
});

// 查询宠物照片（按 petId + date）
app.get('/api/chongyu/pet/photos', (req, res) => {
  const { petId, date } = req.query;

  if (!petId) {
    return res.status(400).json(errorResponse('缺少 petId 参数', 400));
  }

  if (!database.pet_photos) {
    database.pet_photos = [];
  }

  let photos = database.pet_photos.filter(p => p.petId === petId);
  if (date) {
    photos = photos.filter(p => p.date === date);
  }

  if (VERBOSE) console.log(`📸 查询宠物照片: petId=${petId}, date=${date || 'all'}, count=${photos.length}`);

  const photoList = photos.map(p => ({
    ...p,
    url: normalizeUrl(req, p.url)
  }));
  res.json(successResponse({ photoList }));
});

// ==================== 宠物 API (chongyu) ====================

// 同步宠物档案
app.post('/api/chongyu/pets/profile', (req, res) => {
  if (VERBOSE) console.log('📝 收到宠物档案同步请求:', req.body);

  const incoming = req.body || {};
  const pet = {
    ...incoming,
    species: petTypeToSpecies(incoming.type ?? incoming.species),
    gender: petGenderToString(incoming.gender),
  };
  const existingIndex = database.pets.findIndex(p => p.id === pet.id);

  if (existingIndex >= 0) {
    database.pets[existingIndex] = {
      ...pet,
      updatedAt: new Date().toISOString()
    };
    if (LOG_LEVEL === 'info' || LOG_LEVEL === 'debug') {
      console.log('✅ 更新宠物档案:', pet.name);
    }
  } else {
    database.pets.push({
      ...pet,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    });
    if (LOG_LEVEL === 'info' || LOG_LEVEL === 'debug') {
      console.log('✅ 创建宠物档案:', pet.name);
    }
  }

  saveDatabase();

  res.json({
    success: true,
    data: {
      petId: pet.id,
      syncedAt: new Date().toISOString()
    },
    message: '同步成功'
  });
});

// 获取宠物档案
app.get('/api/chongyu/pets/:petId/profile', (req, res) => {
  const { petId } = req.params;
  const pet = database.pets.find(p => p.id === petId);

  if (pet) {
    res.json({
      success: true,
      data: pet
    });
  } else {
    res.status(404).json({
      success: false,
      message: '宠物档案不存在'
    });
  }
});

// ==================== 照片上传 API (chongyu) ====================

// 上传头像照片
app.post('/api/chongyu/upload/profile-photo', upload.single('photo'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({
      success: false,
      message: '未接收到照片文件'
    });
  }

  // 使用请求的 host 构建 URL，支持局域网访问
  const host = req.get('host') || `localhost:${PORT}`;
  const protocol = req.protocol || 'http';
  const url = `${protocol}://${host}/uploads/profiles/${req.file.filename}`;
  const thumbnailUrl = url; // 简化处理，实际应生成缩略图

  if (LOG_LEVEL === 'info' || LOG_LEVEL === 'debug') {
    console.log('✅ 头像照片上传成功:', url);
  }

  res.json({
    success: true,
    data: {
      url: url,
      thumbnailUrl: thumbnailUrl,
      fileSize: req.file.size,
      mimeType: req.file.mimetype
    }
  });
});

// 上传普通照片
app.post('/api/chongyu/upload/photo', upload.single('photo'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({
      success: false,
      message: '未接收到照片文件'
    });
  }

  const photoId = uuidv4();
  const host = req.get('host') || `localhost:${PORT}`;
  const protocol = req.protocol || 'http';
  const url = `${protocol}://${host}/uploads/photos/${req.file.filename}`;

  const photoRecord = {
    id: photoId,
    url: url,
    localPath: req.file.path,
    size: req.file.size,
    mimeType: req.file.mimetype,
    uploadedAt: new Date().toISOString()
  };

  database.photos.push(photoRecord);
  saveDatabase();

  if (LOG_LEVEL === 'info' || LOG_LEVEL === 'debug') {
    console.log('✅ 照片上传成功:', url);
  }

  res.json({
    success: true,
    data: photoRecord
  });
});

// 获取照片信息
app.get('/api/chongyu/photos/:photoId', (req, res) => {
  const { photoId } = req.params;
  const photo = database.photos.find(p => p.id === photoId);

  if (photo) {
    res.json({
      success: true,
      data: photo
    });
  } else {
    res.status(404).json({
      success: false,
      message: '照片不存在'
    });
  }
});

// ==================== 日记 API (chongyu) ====================

// 创建日记
app.post('/api/chongyu/diaries', (req, res) => {
  if (VERBOSE) console.log('📔 收到日记创建请求:', req.body);

  const diary = {
    id: req.body.id || uuidv4(),
    petId: req.body.petId,
    date: req.body.date,
    content: req.body.content,
    imagePath: req.body.imagePath,
    isLocked: req.body.isLocked || false,
    emotionRecordId: req.body.emotionRecordId,
    createdAt: req.body.createdAt || new Date().toISOString(),
    syncedAt: new Date().toISOString()
  };

  const existingIndex = database.diaries.findIndex(d => d.id === diary.id);
  if (existingIndex >= 0) {
    database.diaries[existingIndex] = diary;
    if (LOG_LEVEL === 'info' || LOG_LEVEL === 'debug') {
      console.log('✅ 更新日记');
    }
  } else {
    database.diaries.push(diary);
    if (LOG_LEVEL === 'info' || LOG_LEVEL === 'debug') {
      console.log('✅ 创建日记');
    }
  }

  saveDatabase();

  res.json({
    success: true,
    data: diary
  });
});

// 获取日记列表
app.get('/api/chongyu/diaries', (req, res) => {
  const { petId, limit = 30, offset = 0 } = req.query;

  let diaries = database.diaries;

  if (petId) {
    diaries = diaries.filter(d => d.petId === petId);
  }

  // 按日期倒序排序
  diaries.sort((a, b) => new Date(b.date) - new Date(a.date));

  const total = diaries.length;
  const result = diaries.slice(parseInt(offset), parseInt(offset) + parseInt(limit));

  res.json({
    success: true,
    data: {
      diaries: result,
      total: total,
      limit: parseInt(limit),
      offset: parseInt(offset)
    }
  });
});

// 获取日记详情
app.get('/api/chongyu/diaries/:diaryId', (req, res) => {
  const { diaryId } = req.params;
  const diary = database.diaries.find(d => d.id === diaryId);

  if (diary) {
    // 动态从 pet_photos 构建 imageList，合并已有的 diary.imageList
    let imageList = diary.imageList ? [...diary.imageList] : [];
    if (database.pet_photos) {
      const petPhotos = database.pet_photos
        .filter(p => p.petId === diary.petId && p.date === diary.date)
        .map(p => p.url);
      for (const url of petPhotos) {
        if (!imageList.includes(url)) {
          imageList.push(url);
        }
      }
    }

    return res.json(successResponse({
      date: diary.date || '',
      title: diary.title || '',
      avatar: normalizeUrl(req, diary.imagePath || ''),
      emotion: diary.emotion || 0,
      content: diary.content || '',
      imageList: Array.isArray(imageList)
        ? imageList.map(u => normalizeUrl(req, u))
        : imageList,
    }));
  }

  return res.status(404).json(errorResponse('日记不存在', 404));
});

// ==================== 情绪记录 API (chongyu) ====================

// 保存情绪记录（upsert）
app.post('/api/chongyu/emotions/save', (req, res) => {
  if (VERBOSE) console.log('🎭 收到情绪记录保存请求:', req.body);

  // 确保 emotion_records 集合存在
  if (!database.emotion_records) {
    database.emotion_records = [];
  }

  const record = normalizeEmotionRecord(req.body || {}, req);
  if (!record.id) {
    return res.status(400).json(errorResponse('缺少 id 字段', 400));
  }

  const existingIndex = database.emotion_records.findIndex(r => r.id === record.id);
  if (existingIndex >= 0) {
    database.emotion_records[existingIndex] = {
      ...record,
      syncedAt: new Date().toISOString()
    };
    console.log('🎭 更新情绪记录:', record.id);
  } else {
    database.emotion_records.push({
      ...record,
      syncedAt: new Date().toISOString()
    });
    console.log('🎭 创建情绪记录:', record.id);
  }

  saveDatabase();

  res.json(successResponse({
    recordId: record.id,
    syncedAt: new Date().toISOString()
  }));
});

// 按月查询情绪记录
app.get('/api/chongyu/emotions/month', (req, res) => {
  const { year, month, petId } = req.query;
  const yearNum = parseInt(year, 10);
  const monthNum = parseInt(month, 10);

  if (!Number.isInteger(yearNum) || !Number.isInteger(monthNum)) {
    return res.status(400).json(errorResponse('year/month 参数不合法', 400));
  }

  const records = (database.emotion_records || []).filter((record) => {
    if (petId && record.petId !== petId) return false;
    const d = new Date(record.date);
    if (Number.isNaN(d.getTime())) return false;
    return d.getFullYear() === yearNum && d.getMonth() + 1 === monthNum;
  }).map((record) => normalizeEmotionRecord(record, req));

  res.json(successResponse({ records }));
});

// ==================== 统计 API (chongyu) ====================

// 获取服务器统计信息
app.get('/api/chongyu/stats', (req, res) => {
  res.json({
    success: true,
    data: {
      pets: database.pets.length,
      photos: database.photos.length,
      pet_photos: (database.pet_photos || []).length,
      diaries: database.diaries.length,
      emotion_records: (database.emotion_records || []).length,
      users: database.users.length,
      uptime: process.uptime(),
      memory: process.memoryUsage()
    }
  });
});

// ==================== 错误处理 ====================

app.use((error, req, res, next) => {
  console.error('❌ 服务器错误:', error);
  res.status(500).json(errorResponse(error.message || '服务器内部错误', 500));
});

// ==================== 启动服务器 ====================

app.listen(PORT, HOST, () => {
  console.log('');
  console.log('🚀 =====================================');
  console.log(`   Pet Diary Mock Server 已启动`);
  console.log(`   监听地址: ${HOST}:${PORT}`);
  console.log(`   本地访问: http://localhost:${PORT}`);
  console.log('=====================================');
  console.log('');
  console.log('📊 当前数据统计:');
  console.log(`   宠物: ${database.pets.length}`);
  console.log(`   照片: ${database.photos.length}`);
  console.log(`   宠物照片: ${(database.pet_photos || []).length}`);
  console.log(`   日记: ${database.diaries.length}`);
  console.log(`   情绪记录: ${(database.emotion_records || []).length}`);
  console.log('');
  console.log('🤖 AI 配置:');
  console.log(`   贴纸供应商: ${STICKER_IMAGE_PROVIDER}`);
  console.log(`   Gemini 模型(情绪/特征): ${GEMINI_MODEL}`);
  console.log(`   Gemini 模型(生图): ${GEMINI_IMAGE_MODEL}`);
  console.log(`   Gemini Key: ${GEMINI_API_KEY ? '✅ 已设置' : '❌ 未设置'}`);
  console.log(`   Seedream 模型: ${SEEDREAM_MODEL}`);
  console.log(`   Seedream Key: ${SEEDREAM_API_KEY ? '✅ 已设置' : '❌ 未设置'}`);
  console.log('');
  console.log('💡 API端点:');
  console.log('   [chongyu] GET  /api/chongyu/pet/list - 宠物列表');
  console.log('   [chongyu] GET  /api/chongyu/pet/detail - 宠物/日记详情');
  console.log('   [chongyu] POST /api/chongyu/image/list/upload - 批量上传图片');
  console.log('   [chongyu] GET  /api/chongyu/pet/photos - 宠物照片');
  console.log('   [chongyu] POST /api/chongyu/pets/profile - 同步宠物档案');
  console.log('   [chongyu] POST /api/chongyu/upload/profile-photo - 上传头像');
  console.log('   [chongyu] POST /api/chongyu/upload/photo - 上传照片');
  console.log('   [chongyu] POST /api/chongyu/diaries - 创建日记');
  console.log('   [chongyu] GET  /api/chongyu/diaries - 获取日记列表');
  console.log('   [chongyu] POST /api/chongyu/emotions/save - 保存情绪记录');
  console.log('   [chongyu] GET  /api/chongyu/stats - 查看统计信息');
  console.log('   [chongyu] POST /api/chongyu/ai/sticker/generate - 生成贴纸');
  console.log('   [chongyu] POST /api/chongyu/ai/diary/generate - 生成日记文字');
  console.log('');
  console.log('⚙️  配置:');
  console.log(`   数据库文件: ${DB_FILE_NAME}`);
  console.log(`   上传目录: ${UPLOAD_DIR}`);
  console.log(`   日志级别: ${LOG_LEVEL}`);
  console.log('');
});
