function buildStickerPrompt({ analysis, pet_features }) {
  return `
A professional 2D vector pet sticker, CLOSE-UP HEADSHOT of a ${pet_features.breed}.
The pet has ${pet_features.primary_color} fur and ${pet_features.markings}.
Showing an extreme ${analysis.emotion} expression, looking at the camera.
High-quality digital illustration, thick clean outlines, bold flat colors,
white border around the character, sticker aesthetic.
Isolated on a pure white background, cute chibi style.
Focus entirely on the head and face.
`.trim();
}

module.exports = { buildStickerPrompt };
