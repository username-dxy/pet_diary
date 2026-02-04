const fs = require('fs');
const path = require('path');

const GEMINI_API_BASE_URL =
  process.env.GEMINI_API_BASE_URL || 'https://generativelanguage.googleapis.com/v1beta';
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash-image';
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';

function inferMimeType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.png') return 'image/png';
  if (ext === '.webp') return 'image/webp';
  if (ext === '.heic') return 'image/heic';
  return 'image/jpeg';
}

function extractJson(text) {
  const trimmed = text.trim();
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    return JSON.parse(trimmed);
  }
  const match = trimmed.match(/\{[\s\S]*\}/);
  if (!match) throw new Error('Gemini response did not contain JSON');
  return JSON.parse(match[0]);
}

function buildPrompt() {
  return [
    'You are a vision model. Analyze the pet photo and return STRICT JSON only.',
    'The JSON must follow this shape:',
    '{',
    '  "analysis": {',
    '    "emotion": "happy|calm|sad|angry|sleepy|curious",',
    '    "confidence": 0.0-1.0,',
    '    "reasoning": "short reason"',
    '  },',
    '  "pet_features": {',
    '    "species": "dog|cat|other",',
    '    "breed": "string",',
    '    "primary_color": "string",',
    '    "markings": "string",',
    '    "eye_color": "string",',
    '    "pose": "string"',
    '  }',
    '}',
    'Do NOT add any other text. JSON only.'
  ].join('\n');
}

async function analyzeEmotion(imagePath) {
  if (!GEMINI_API_KEY) {
    throw new Error('Missing GEMINI_API_KEY');
  }

  const imageBuffer = fs.readFileSync(imagePath);
  const base64Data = imageBuffer.toString('base64');
  const mimeType = inferMimeType(imagePath);

  const endpoint = `${GEMINI_API_BASE_URL}/models/${GEMINI_MODEL}:generateContent`;
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
            { text: buildPrompt() }
          ]
        }
      ]
    })
  });

  const payload = await response.json();
  if (!response.ok) {
    const errorMessage = payload?.error?.message || 'Gemini request failed';
    throw new Error(errorMessage);
  }

  const parts = payload?.candidates?.[0]?.content?.parts || [];
  const text = parts.map(p => p.text).filter(Boolean).join('\n');
  if (!text) {
    throw new Error('Gemini returned empty content');
  }

  return extractJson(text);
}

module.exports = { analyzeEmotion };
