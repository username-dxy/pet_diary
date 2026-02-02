const express = require('express');
const multer = require('multer');
const cors = require('cors');
const bodyParser = require('body-parser');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const path = require('path');

// 加载环境变量（如果存在 .env 文件）
require('dotenv').config();

const app = express();

// 从环境变量读取配置，提供默认值
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';
const DB_FILE_NAME = process.env.DB_FILE || 'db.json';
const UPLOAD_DIR = process.env.UPLOAD_DIR || 'uploads';
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';
const VERBOSE = process.env.VERBOSE === 'true';

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
    const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg', 'image/heic'];
    if (allowedTypes.includes(file.mimetype)) {
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

// 内部 pet → api.md 格式映射
function mapPetToApi(pet) {
  const speciesMap = { cat: 2, dog: 1 };
  const genderMap = { male: 1, female: 2, unknown: 0 };
  return {
    petId: pet.id,
    type: speciesMap[pet.species] || 0,
    gender: genderMap[pet.gender] || 0,
    birthday: pet.birthday || '',
    ownerTitle: pet.ownerNickname || '',
    avatar: pet.profilePhotoPath || '',
    nickName: pet.name || '',
    character: pet.personality || '',
    description: pet.breed || '',
  };
}

// 内部 diary → api.md diary list item 格式映射
function mapDiaryToListItem(diary) {
  return {
    diaryId: diary.id,
    date: diary.date || '',
    title: diary.title || (diary.content ? diary.content.substring(0, 20) : ''),
    avatar: diary.imagePath || '',
    emotion: diary.emotion || 0,
  };
}

// 获取星期几 (日=0, 一=1, ..., 六=6)
function getWeekDay(dateStr) {
  const d = new Date(dateStr);
  return d.getDay();
}

// 内部 diary → api.md calendar day item 格式映射
function mapDiaryToCalendarDay(diary) {
  return {
    diaryId: diary.id,
    date: diary.date || '',
    weekDay: getWeekDay(diary.date),
    title: diary.title || (diary.content ? diary.content.substring(0, 20) : ''),
    avatar: diary.imagePath || '',
    emotion: diary.emotion || 0,
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
app.use('/api/chongyu', tokenMiddleware);

// ==================== 路由定义 ====================

// 根路径
app.get('/', (req, res) => {
  res.json({
    message: 'Pet Diary Mock Server',
    version: '1.0.0',
    endpoints: {
      pets: {
        'POST /api/v1/pets/profile': '同步宠物档案',
        'GET /api/v1/pets/:petId/profile': '获取宠物档案',
      },
      photos: {
        'POST /api/v1/upload/profile-photo': '上传头像照片',
        'POST /api/v1/upload/photo': '上传普通照片',
        'GET /api/v1/photos/:photoId': '获取照片信息',
      },
      diaries: {
        'POST /api/v1/diaries': '创建日记',
        'GET /api/v1/diaries': '获取日记列表',
        'GET /api/v1/diaries/:diaryId': '获取日记详情',
      },
      stats: {
        'GET /api/v1/stats': '获取服务器统计信息',
      },
      chongyu: {
        'GET /api/chongyu/pet/list': '查询宠物列表',
        'GET /api/chongyu/pet/detail': '查询宠物/日记详情',
        'POST /api/chongyu/image/list/upload': '批量上传相册图片',
        'GET /api/chongyu/diary/list': '查询日记列表',
        'GET /api/chongyu/diary/calendar': '查询日历情绪',
        'GET /api/chongyu/diary/7days': '查询前7天情绪',
        'GET /api/chongyu/pet/photos': '查询宠物照片',
      }
    }
  });
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
      avatar: diary.imagePath || '',
      emotion: diary.emotion || 0,
      content: diary.content || '',
      imageList: imageList,
    }));
  }

  // 否则返回宠物详情
  const pet = database.pets.find(p => p.id === petId);
  if (!pet) {
    return res.status(404).json(errorResponse('宠物不存在', 404));
  }

  if (VERBOSE) console.log('🐾 查询宠物详情:', petId);

  const detail = mapPetToApi(pet);
  res.json(successResponse(detail));
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

// 查询日记列表
app.get('/api/chongyu/diary/list', (req, res) => {
  const { petId } = req.query;

  if (!petId) {
    return res.status(400).json(errorResponse('缺少 petId 参数', 400));
  }

  const diaries = database.diaries
    .filter(d => d.petId === petId)
    .sort((a, b) => new Date(b.date) - new Date(a.date));

  const diaryList = diaries.map(mapDiaryToListItem);

  if (VERBOSE) console.log(`📋 查询日记列表: petId=${petId}, count=${diaryList.length}`);

  res.json(successResponse({ diaryList }));
});

// 查询日历情绪
app.get('/api/chongyu/diary/calendar', (req, res) => {
  const { petId, yearMonth } = req.query;

  if (!petId || !yearMonth) {
    return res.status(400).json(errorResponse('缺少 petId 或 yearMonth 参数', 400));
  }

  // yearMonth 格式: 202601
  const ym = String(yearMonth);
  const year = parseInt(ym.substring(0, 4), 10);
  const month = parseInt(ym.substring(4, 6), 10);

  const diaries = database.diaries.filter(d => {
    if (d.petId !== petId) return false;
    const dDate = new Date(d.date);
    return dDate.getFullYear() === year && (dDate.getMonth() + 1) === month;
  });

  const dayList = diaries
    .sort((a, b) => new Date(a.date) - new Date(b.date))
    .map(mapDiaryToCalendarDay);

  if (VERBOSE) console.log(`📅 查询日历: petId=${petId}, yearMonth=${yearMonth}, days=${dayList.length}`);

  res.json(successResponse({ dayList }));
});

// 查询前7天情绪
app.get('/api/chongyu/diary/7days', (req, res) => {
  const { petId, date } = req.query;

  if (!petId || !date) {
    return res.status(400).json(errorResponse('缺少 petId 或 date 参数', 400));
  }

  // date 格式: 20260130
  const ds = String(date);
  const year = parseInt(ds.substring(0, 4), 10);
  const month = parseInt(ds.substring(4, 6), 10) - 1;
  const day = parseInt(ds.substring(6, 8), 10);
  const endDate = new Date(year, month, day);
  const startDate = new Date(year, month, day - 6); // 含当天共7天

  const diaries = database.diaries.filter(d => {
    if (d.petId !== petId) return false;
    const dDate = new Date(d.date);
    return dDate >= startDate && dDate <= endDate;
  });

  const dayList = diaries
    .sort((a, b) => new Date(a.date) - new Date(b.date))
    .map(mapDiaryToCalendarDay);

  if (VERBOSE) console.log(`📆 查询7天: petId=${petId}, date=${date}, days=${dayList.length}`);

  res.json(successResponse({ dayList }));
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

  res.json(successResponse({ photoList: photos }));
});

// ==================== 宠物 API (v1, 保留向后兼容) ====================

// 同步宠物档案
app.post('/api/v1/pets/profile', (req, res) => {
  if (VERBOSE) console.log('📝 收到宠物档案同步请求:', req.body);

  const pet = req.body;
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
app.get('/api/v1/pets/:petId/profile', (req, res) => {
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

// ==================== 照片上传 API (v1) ====================

// 上传头像照片
app.post('/api/v1/upload/profile-photo', upload.single('photo'), (req, res) => {
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
app.post('/api/v1/upload/photo', upload.single('photo'), (req, res) => {
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
app.get('/api/v1/photos/:photoId', (req, res) => {
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

// ==================== 日记 API (v1) ====================

// 创建日记
app.post('/api/v1/diaries', (req, res) => {
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
app.get('/api/v1/diaries', (req, res) => {
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
app.get('/api/v1/diaries/:diaryId', (req, res) => {
  const { diaryId } = req.params;
  const diary = database.diaries.find(d => d.id === diaryId);

  if (diary) {
    res.json({
      success: true,
      data: diary
    });
  } else {
    res.status(404).json({
      success: false,
      message: '日记不存在'
    });
  }
});

// ==================== 统计 API ====================

// 获取服务器统计信息
app.get('/api/v1/stats', (req, res) => {
  res.json({
    success: true,
    data: {
      pets: database.pets.length,
      photos: database.photos.length,
      pet_photos: (database.pet_photos || []).length,
      diaries: database.diaries.length,
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
  console.log('');
  console.log('💡 API端点:');
  console.log('   [v1] POST /api/v1/pets/profile - 同步宠物档案');
  console.log('   [v1] POST /api/v1/upload/profile-photo - 上传头像');
  console.log('   [v1] POST /api/v1/upload/photo - 上传照片');
  console.log('   [v1] POST /api/v1/diaries - 创建日记');
  console.log('   [v1] GET  /api/v1/diaries - 获取日记列表');
  console.log('   [v1] GET  /api/v1/stats - 查看统计信息');
  console.log('');
  console.log('   [chongyu] GET  /api/chongyu/pet/list - 宠物列表');
  console.log('   [chongyu] GET  /api/chongyu/pet/detail - 宠物/日记详情');
  console.log('   [chongyu] POST /api/chongyu/image/list/upload - 批量上传图片');
  console.log('   [chongyu] GET  /api/chongyu/diary/list - 日记列表');
  console.log('   [chongyu] GET  /api/chongyu/diary/calendar - 日历情绪');
  console.log('   [chongyu] GET  /api/chongyu/diary/7days - 前7天情绪');
  console.log('   [chongyu] GET  /api/chongyu/pet/photos - 宠物照片');
  console.log('');
  console.log('⚙️  配置:');
  console.log(`   数据库文件: ${DB_FILE_NAME}`);
  console.log(`   上传目录: ${UPLOAD_DIR}`);
  console.log(`   日志级别: ${LOG_LEVEL}`);
  console.log('');
});
