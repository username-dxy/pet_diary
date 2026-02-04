const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const GEMINI_API_BASE_URL =
  process.env.GEMINI_API_BASE_URL || 'https://generativelanguage.googleapis.com/v1beta';
const GEMINI_IMAGE_MODEL = process.env.GEMINI_IMAGE_MODEL || 'gemini-2.5-flash-image';
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';

function inferMimeType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.png') return 'image/png';
  if (ext === '.webp') return 'image/webp';
  if (ext === '.heic') return 'image/heic';
  return 'image/jpeg';
}

function extractInlineImage(parts) {
  for (const part of parts) {
    if (part.inline_data && part.inline_data.data) {
      return part.inline_data;
    }
    if (part.inlineData && part.inlineData.data) {
      return part.inlineData;
    }
  }
  return null;
}

async function generateStickerImage({ imagePath, prompt, host, protocol }) {
  if (!GEMINI_API_KEY) {
    throw new Error('Missing GEMINI_API_KEY');
  }

  const imageBuffer = fs.readFileSync(imagePath);
  const base64Data = imageBuffer.toString('base64');
  const mimeType = inferMimeType(imagePath);

  const endpoint = `${GEMINI_API_BASE_URL}/models/${GEMINI_IMAGE_MODEL}:generateContent`;
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

  const payload = await response.json();
  if (!response.ok) {
    const errorMessage = payload?.error?.message || 'Gemini image request failed';
    throw new Error(errorMessage);
  }

  const parts = payload?.candidates?.[0]?.content?.parts || [];
  const inlineImage = extractInlineImage(parts);
  if (!inlineImage) {
    throw new Error('Gemini image response missing inline image data');
  }

  const responseMimeType = inlineImage.mime_type || inlineImage.mimeType || 'image/png';
  const ext = responseMimeType.split('/')[1] || 'png';
  const buffer = Buffer.from(inlineImage.data, 'base64');

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
