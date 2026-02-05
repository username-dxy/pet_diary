const fs = require('fs');
const path = require('path');
const { GoogleGenAI } = require('@google/genai');

const ARK_API_BASE_URL =
  process.env.ARK_API_BASE_URL || 'https://ark.cn-beijing.volces.com/api/v3';
const ARK_VISION_MODEL =
  process.env.ARK_VISION_MODEL || 'doubao-1-5-vision-pro-32k-250115';
const ARK_API_KEY = process.env.ARK_API_KEY || '';

const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash-image';
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';

const geminiClient = GEMINI_API_KEY ? new GoogleGenAI({ apiKey: GEMINI_API_KEY }) : null;

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

function extractTextFromInteraction(interaction) {
  const outputs = interaction?.outputs || [];
  const last = outputs[outputs.length - 1] || {};
  if (last.text) return last.text;

  const parts = last.content?.parts || [];
  const text = parts.map(p => p.text).filter(Boolean).join('\n');
  if (text) return text;

  return '';
}

async function callArkVision({ base64Data, mimeType }) {
  if (!ARK_API_KEY) {
    return null;
  }

  const dataUrl = `data:${mimeType};base64,${base64Data}`;
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
          content: [
            { type: 'image_url', image_url: { url: dataUrl } },
            { type: 'text', text: buildPrompt() }
          ]
        }
      ]
    })
  });

  const payload = await response.json();
  if (!response.ok) {
    const errorMessage = payload?.error?.message || 'Ark vision request failed';
    throw new Error(errorMessage);
  }

  const text = payload?.choices?.[0]?.message?.content || '';
  return text;
}

async function callGeminiVision({ base64Data, mimeType }) {
  if (!geminiClient) {
    return null;
  }

  const interaction = await geminiClient.interactions.create({
    model: GEMINI_MODEL,
    input: [
      {
        inlineData: {
          mimeType,
          data: base64Data
        }
      },
      { text: buildPrompt() }
    ]
  });

  return extractTextFromInteraction(interaction);
}

async function analyzeEmotion(imagePath) {
  const imageBuffer = fs.readFileSync(imagePath);
  const base64Data = imageBuffer.toString('base64');
  const mimeType = inferMimeType(imagePath);

  const arkText = await callArkVision({ base64Data, mimeType });
  const text = arkText || (await callGeminiVision({ base64Data, mimeType }));
  if (!text) {
    throw new Error('No vision provider available or returned empty content');
  }

  return extractJson(text);
}

module.exports = { analyzeEmotion };
