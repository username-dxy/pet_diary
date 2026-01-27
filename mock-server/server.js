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
      }
    }
  });
});

// ==================== 宠物 API ====================

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

// ==================== 照片上传 API ====================

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

// ==================== 日记 API ====================

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
  res.status(500).json({
    success: false,
    message: error.message || '服务器内部错误'
  });
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
  console.log(`   日记: ${database.diaries.length}`);
  console.log('');
  console.log('💡 API端点:');
  console.log('   POST /api/v1/pets/profile - 同步宠物档案');
  console.log('   POST /api/v1/upload/profile-photo - 上传头像');
  console.log('   POST /api/v1/upload/photo - 上传照片');
  console.log('   POST /api/v1/diaries - 创建日记');
  console.log('   GET  /api/v1/diaries - 获取日记列表');
  console.log('   GET  /api/v1/stats - 查看统计信息');
  console.log('');
  console.log('⚙️  配置:');
  console.log(`   数据库文件: ${DB_FILE_NAME}`);
  console.log(`   上传目录: ${UPLOAD_DIR}`);
  console.log(`   日志级别: ${LOG_LEVEL}`);
  console.log('');
});
