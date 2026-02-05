const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { GoogleGenAI } = require('@google/genai');

const GEMINI_IMAGE_MODEL = process.env.GEMINI_IMAGE_MODEL || 'gemini-2.5-flash-image';
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';

const STICKER_IMAGE_PROVIDER =
  (process.env.STICKER_IMAGE_PROVIDER || 'gemini').toLowerCase().trim();

const SEEDREAM_BASE_URL =
  process.env.SEEDREAM_BASE_URL || 'https://ark.cn-beijing.volces.com/api/v3';
const SEEDREAM_API_KEY = process.env.SEEDREAM_API_KEY || process.env.ARK_API_KEY || '';
const SEEDREAM_MODEL = process.env.SEEDREAM_MODEL || 'doubao-seedream-4-5-251128';
const SEEDREAM_SIZE = process.env.SEEDREAM_SIZE || '2K';
const SEEDREAM_RESPONSE_FORMAT = process.env.SEEDREAM_RESPONSE_FORMAT || 'url';
const SEEDREAM_WATERMARK = process.env.SEEDREAM_WATERMARK === 'true';
const SEEDREAM_TIMEOUT_MS = parseInt(process.env.SEEDREAM_TIMEOUT_MS || '30000', 10);
const SEEDREAM_IMAGE_INPUT = (process.env.SEEDREAM_IMAGE_INPUT || '').toLowerCase().trim();

const client = new GoogleGenAI({ apiKey: GEMINI_API_KEY });

function inferMimeType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.png') return 'image/png';
  if (ext === '.webp') return 'image/webp';
  if (ext === '.heic') return 'image/heic';
  return 'image/jpeg';
}

function extractImageFromInteraction(interaction) {
  const outputs = interaction?.outputs || [];
  for (const output of outputs) {
    if (output?.type === 'image' && output.data) {
      return {
        data: output.data,
        mimeType: output.mime_type || output.mimeType || 'image/png'
      };
    }
  }

  const last = outputs[outputs.length - 1] || {};
  const parts = last.content?.parts || [];
  for (const part of parts) {
    if (part.inlineData && part.inlineData.data) {
      return {
        data: part.inlineData.data,
        mimeType: part.inlineData.mimeType || part.inlineData.mime_type || 'image/png'
      };
    }
    if (part.inline_data && part.inline_data.data) {
      return {
        data: part.inline_data.data,
        mimeType: part.inline_data.mimeType || part.inline_data.mime_type || 'image/png'
      };
    }
  }

  return null;
}

function buildPublicUrl({ imagePath, host, protocol }) {
  const normalized = String(imagePath || '').replace(/\\/g, '/');
  const idx = normalized.indexOf('/uploads/');
  const rel = idx >= 0 ? normalized.substring(idx + 1) : normalized;
  const safeProtocol = protocol || 'http';
  const safeHost = host || 'localhost:3000';
  const pathPart = rel.startsWith('/') ? rel : `/${rel}`;
  return `${safeProtocol}://${safeHost}${pathPart}`;
}

function isPrivateHost(hostname) {
  if (!hostname) return true;
  const lower = hostname.toLowerCase();
  if (lower === 'localhost' || lower === '127.0.0.1' || lower === '0.0.0.0') {
    return true;
  }
  if (lower.startsWith('10.')) return true;
  if (lower.startsWith('192.168.')) return true;
  if (lower.startsWith('172.')) {
    const parts = lower.split('.');
    const second = parseInt(parts[1] || '0', 10);
    if (second >= 16 && second <= 31) return true;
  }
  return false;
}

function shouldUseBase64Input(imageUrl) {
  if (SEEDREAM_IMAGE_INPUT === 'base64') return true;
  if (SEEDREAM_IMAGE_INPUT === 'url') return false;
  try {
    const parsed = new URL(imageUrl);
    return isPrivateHost(parsed.hostname);
  } catch (error) {
    return true;
  }
}

async function generateStickerWithSeedream({ imagePath, prompt, host, protocol }) {
  if (!SEEDREAM_API_KEY) {
    throw new Error('Missing SEEDREAM_API_KEY');
  }

  const imageUrl = buildPublicUrl({ imagePath, host, protocol });
  let imageInput = imageUrl;
  if (shouldUseBase64Input(imageUrl)) {
    const imageBuffer = fs.readFileSync(imagePath);
    const base64Data = imageBuffer.toString('base64');
    const mimeType = inferMimeType(imagePath);
    imageInput = `data:${mimeType};base64,${base64Data}`;
  }
  const endpoint = `${SEEDREAM_BASE_URL.replace(/\/+$/, '')}/images/generations`;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), SEEDREAM_TIMEOUT_MS);

  try {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${SEEDREAM_API_KEY}`
      },
      body: JSON.stringify({
        model: SEEDREAM_MODEL,
        prompt,
        image: imageInput,
        size: SEEDREAM_SIZE,
        response_format: SEEDREAM_RESPONSE_FORMAT,
        watermark: SEEDREAM_WATERMARK
      }),
      signal: controller.signal
    });

    const payload = await response.json();
    if (!response.ok) {
      const msg =
        payload?.error?.message ||
        payload?.message ||
        `Seedream request failed (HTTP ${response.status})`;
      throw new Error(msg);
    }

    const url = payload?.data?.[0]?.url;
    if (!url) {
      throw new Error('Seedream response missing image url');
    }
    return url;
  } finally {
    clearTimeout(timeoutId);
  }
}

async function generateStickerImage({ imagePath, prompt, host, protocol }) {
  if (STICKER_IMAGE_PROVIDER === 'seedream') {
    return generateStickerWithSeedream({ imagePath, prompt, host, protocol });
  }

  if (!GEMINI_API_KEY) {
    throw new Error('Missing GEMINI_API_KEY');
  }

  const imageBuffer = fs.readFileSync(imagePath);
  const base64Data = imageBuffer.toString('base64');
  const mimeType = inferMimeType(imagePath);

  const interaction = await client.interactions.create({
    model: GEMINI_IMAGE_MODEL,
    input: prompt,
    generation_config: {
      image_config: {
        aspect_ratio: process.env.GEMINI_IMAGE_ASPECT_RATIO || '1:1',
        image_size: process.env.GEMINI_IMAGE_SIZE || '2k'
      }
    }
  });

  const image = extractImageFromInteraction(interaction);
  if (!image) {
    throw new Error('Gemini image response missing image data');
  }

  const responseMimeType = image.mimeType || 'image/png';
  const ext = responseMimeType.split('/')[1] || 'png';
  const buffer = Buffer.from(image.data, 'base64');

  const uploadDir = path.join(__dirname, '..', '..', 'uploads', 'stickers');
  if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
  }

  const filename = `${uuidv4()}.${ext}`;
  const filePath = path.join(uploadDir, filename);
  fs.writeFileSync(filePath, buffer);

  const safeHost = host || 'localhost:3000';
  const safeProtocol = protocol || 'http';
  return `${safeProtocol}://${safeHost}/uploads/stickers/${filename}`;
}

module.exports = { generateStickerImage };
