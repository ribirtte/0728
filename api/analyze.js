const ZODIAC_SIGNS = [
  { key: 'capricorn', name: '\uC5FC\uC18C\uC790\uB9AC', glyph: '\u2651', start: [12, 22], end: [1, 19], element: '\uD761', color: '#b78a5a', lucky: [4, 8, 14, 22, 31, 45] },
  { key: 'aquarius', name: '\uBB3C\uBCD1\uC790\uB9AC', glyph: '\u2652', start: [1, 20], end: [2, 18], element: '\uBC14\uB78C', color: '#4f84c4', lucky: [3, 7, 16, 21, 29, 41] },
  { key: 'pisces', name: '\uBB3C\uACE0\uAE30\uC790\uB9AC', glyph: '\u2653', start: [2, 19], end: [3, 20], element: '\uBB3C', color: '#6a8dd8', lucky: [2, 6, 12, 18, 27, 39] },
  { key: 'aries', name: '\uC591\uC790\uB9AC', glyph: '\u2648', start: [3, 21], end: [4, 19], element: '\uBD88', color: '#d95b5b', lucky: [1, 9, 15, 23, 30, 44] },
  { key: 'taurus', name: '\uD669\uC18C\uC790\uB9AC', glyph: '\u2649', start: [4, 20], end: [5, 20], element: '\uD761', color: '#5e9c5f', lucky: [5, 10, 17, 24, 33, 42] },
  { key: 'gemini', name: '\uC30D\uB465\uC774\uC790\uB9AC', glyph: '\u264A', start: [5, 21], end: [6, 20], element: '\uBC14\uB78C', color: '#7b6bd6', lucky: [6, 11, 19, 25, 34, 43] },
  { key: 'cancer', name: '\uAC8C\uC790\uB9AC', glyph: '\u264B', start: [6, 21], end: [7, 22], element: '\uBB3C', color: '#7a98d8', lucky: [2, 13, 20, 28, 35, 40] },
  { key: 'leo', name: '\uC0AC\uC790\uC790\uB9AC', glyph: '\u264C', start: [7, 23], end: [8, 22], element: '\uBD88', color: '#e0a13a', lucky: [8, 14, 18, 26, 32, 45] },
  { key: 'virgo', name: '\uCC98\uB140\uC790\uB9AC', glyph: '\u264D', start: [8, 23], end: [9, 22], element: '\uD761', color: '#5b84c4', lucky: [3, 12, 16, 24, 37, 41] },
  { key: 'libra', name: '\uCC9C\uCE6D\uC790\uB9AC', glyph: '\u264E', start: [9, 23], end: [10, 22], element: '\uBC14\uB78C', color: '#a76ad8', lucky: [7, 10, 19, 29, 36, 44] },
  { key: 'scorpio', name: '\uC804\uAC08\uC790\uB9AC', glyph: '\u264F', start: [10, 23], end: [11, 22], element: '\uBB3C', color: '#b44f63', lucky: [1, 8, 15, 22, 30, 39] },
  { key: 'sagittarius', name: '\uAD81\uC218\uC790\uB9AC', glyph: '\u2650', start: [11, 23], end: [12, 21], element: '\uBD88', color: '#c66f31', lucky: [4, 9, 18, 27, 33, 42] }
];

const CONSTELLATIONS = {
  aries: [[30, 95], [60, 55], [110, 42], [160, 60], [185, 94]],
  taurus: [[22, 90], [56, 50], [98, 36], [138, 48], [176, 88], [120, 112]],
  gemini: [[40, 24], [40, 106], [76, 42], [76, 88], [116, 28], [116, 102], [160, 44], [160, 90]],
  cancer: [[30, 78], [60, 48], [96, 64], [132, 34], [160, 74], [184, 54]],
  leo: [[24, 88], [58, 54], [96, 68], [126, 32], [160, 40], [184, 82]],
  virgo: [[22, 30], [52, 60], [78, 34], [106, 78], [132, 44], [166, 98], [184, 58]],
  libra: [[28, 76], [62, 44], [96, 74], [132, 44], [170, 76]],
  scorpio: [[24, 52], [52, 32], [86, 52], [116, 24], [142, 54], [172, 82]],
  sagittarius: [[26, 98], [52, 68], [80, 90], [104, 54], [132, 72], [160, 36], [186, 62]],
  capricorn: [[26, 76], [58, 42], [90, 72], [118, 40], [150, 80], [182, 54]],
  aquarius: [[22, 38], [54, 54], [86, 34], [118, 52], [148, 30], [180, 46], [60, 92], [156, 90]],
  pisces: [[30, 42], [56, 26], [82, 58], [106, 34], [130, 74], [160, 50], [184, 82]]
};

function parseBirthDate(value) {
  if (!value) return null;
  const date = new Date(`${value}T12:00:00Z`);
  return Number.isNaN(date.getTime()) ? null : date;
}

function getZodiacByDate(month, day) {
  const value = month * 100 + day;
  for (const sign of ZODIAC_SIGNS) {
    const start = sign.start[0] * 100 + sign.start[1];
    const end = sign.end[0] * 100 + sign.end[1];
    if (start <= end) {
      if (value >= start && value <= end) return sign;
    } else if (value >= start || value <= end) {
      return sign;
    }
  }
  return ZODIAC_SIGNS[0];
}

function uniqueSortedNumbers(numbers) {
  return [...new Set(numbers)]
    .filter((n) => Number.isInteger(n) && n >= 1 && n <= 45)
    .slice(0, 6)
    .sort((a, b) => a - b);
}

function deriveNumbers(date, sign) {
  const month = date.getMonth() + 1;
  const day = date.getDate();
  const year = date.getFullYear();
  const yearSum = String(year).split('').reduce((sum, digit) => sum + Number(digit), 0);

  const candidate1 = ((month * day) % 45) + 1;
  const candidate2 = ((month + day + yearSum) % 45) + 1;
  const candidate3 = sign.lucky[(month + day) % sign.lucky.length];
  const candidate4 = sign.lucky[(month * 2 + day) % sign.lucky.length];
  const candidate5 = year % 45 || 45;
  const candidate6 = (((month + yearSum) * day) % 45) + 1;

  const numbers = uniqueSortedNumbers([candidate1, candidate2, candidate3, candidate4, candidate5, candidate6]);
  while (numbers.length < 6) {
    const seed = numbers.reduce((sum, n) => sum + n, 0) + yearSum;
    let next = (seed % 45) + 1;
    if (numbers.includes(next)) {
      next = ((next + 7 - 1) % 45) + 1;
    }
    if (!numbers.includes(next)) numbers.push(next);
  }

  return numbers.sort((a, b) => a - b);
}

function buildConstellationSvg(sign) {
  const points = CONSTELLATIONS[sign.key] || CONSTELLATIONS.aries;
  const path = points.map(([x, y]) => `${x},${y}`).join(' ');
  const dots = points.map(([x, y]) => `<circle cx="${x}" cy="${y}" r="3.8" fill="${sign.color}" />`).join('');
  return `
    <svg viewBox="0 0 200 120" role="img" aria-label="${sign.name} constellation">
      <rect width="200" height="120" fill="#eef4ff"></rect>
      <polyline points="${path}" fill="none" stroke="${sign.color}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"></polyline>
      ${dots}
    </svg>
  `;
}

function getHiggsfieldCredentials(payload = {}) {
  const apiKey =
    (typeof payload.higgsfieldApiKey === 'string' && payload.higgsfieldApiKey.trim()) ||
    (typeof payload.higgsfieldKey1 === 'string' && payload.higgsfieldKey1.trim()) ||
    '';
  const apiSecret =
    (typeof payload.higgsfieldApiSecret === 'string' && payload.higgsfieldApiSecret.trim()) ||
    (typeof payload.higgsfieldKey2 === 'string' && payload.higgsfieldKey2.trim()) ||
    '';

  return { apiKey, apiSecret };
}

function buildHiggsfieldPrompt({ sign, numbers, birthDate, name, question }) {
  const namePart = name ? `for ${name}` : 'for the user';
  const questionPart = question ? `The user question is: ${question}.` : 'No additional user question was provided.';
  return [
    `Create a premium vertical zodiac card ${namePart}.`,
    'Follow the Soul 2 editorial style with premium fashion-card energy.',
    'Use a creamy ivory, gold, and warm amber palette with a polished casino-luxury feel.',
    `Theme the artwork around the zodiac sign ${sign.name} (${sign.glyph}) and a refined constellation motif.`,
    'Center a cute but elegant mascot-like emblem inspired by the zodiac, with glossy highlights and soft depth.',
    'Make it look like a collectible fortune card, clean composition, subtle sparkles, circular halo framing, and editorial lighting.',
    'Portrait orientation, high detail, no watermark, no extra logos, no UI mockup, no collage.',
    'Avoid long readable text inside the image; keep the design visually strong on its own.',
    `Birthdate: ${birthDate}. Lucky numbers: ${numbers.join(', ')}.`,
    questionPart
  ].join(' ');
}

function findFirstImageUrl(value, seen = new Set()) {
  if (!value || typeof value !== 'object' || seen.has(value)) {
    return null;
  }

  seen.add(value);

  const directKeys = ['url', 'image_url', 'imageUrl', 'resultImageUrl', 'result_image_url', 'output_url', 'outputUrl'];
  for (const key of directKeys) {
    const candidate = value[key];
    if (typeof candidate === 'string' && /^https?:\/\//i.test(candidate)) {
      return candidate;
    }
  }

  if (Array.isArray(value.images)) {
    for (const image of value.images) {
      const url = findFirstImageUrl(image, seen);
      if (url) return url;
    }
  }

  if (Array.isArray(value.results)) {
    for (const result of value.results) {
      const url = findFirstImageUrl(result, seen);
      if (url) return url;
    }
  }

  if (value.results && typeof value.results === 'object') {
    const url = findFirstImageUrl(value.results, seen);
    if (url) return url;
  }

  if (value.raw && typeof value.raw === 'object') {
    const url = findFirstImageUrl(value.raw, seen);
    if (url) return url;
  }

  if (value.data && typeof value.data === 'object') {
    const url = findFirstImageUrl(value.data, seen);
    if (url) return url;
  }

  for (const key of Object.keys(value)) {
    const child = value[key];
    if (child && typeof child === 'object') {
      const url = findFirstImageUrl(child, seen);
      if (url) return url;
    }
  }

  return null;
}

function getHiggsfieldStatus(value) {
  if (!value || typeof value !== 'object') return '';

  const direct = [value.status, value.state, value.phase]
    .find((item) => typeof item === 'string' && item.trim());
  if (direct) return direct.trim().toLowerCase();

  if (value.data && typeof value.data === 'object') {
    const nested = getHiggsfieldStatus(value.data);
    if (nested) return nested;
  }

  return '';
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function fetchWithTimeout(url, options = {}, timeoutMs = 15000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, {
      ...options,
      signal: controller.signal
    });
  } finally {
    clearTimeout(timer);
  }
}

async function callHiggsfieldCard({ sign, numbers, birthDate, name, question, credentialsPayload = {} }) {
  const { apiKey, apiSecret } = getHiggsfieldCredentials(credentialsPayload);
  if (!apiKey || !apiSecret) {
    return {
      skipped: true,
      error: 'Higgsfield API key/secret missing',
      imageUrl: null
    };
  }

  const prompt = buildHiggsfieldPrompt({ sign, numbers, birthDate, name, question });
  const requestHeaders = {
    Authorization: `Key ${apiKey}:${apiSecret}`,
    Accept: 'application/json',
    'Content-Type': 'application/json'
  };

  const submitResponse = await fetchWithTimeout('https://platform.higgsfield.ai/v1/text2image/soul', {
    method: 'POST',
    headers: requestHeaders,
    body: JSON.stringify({
      prompt,
      width_and_height: '1536x2048',
      quality: 'HD',
      batch_size: 1,
      enhance_prompt: false
    })
  }, 20000);

  const submitText = await submitResponse.text();
  let submitJson = null;
  try {
    submitJson = submitText ? JSON.parse(submitText) : null;
  } catch {
    submitJson = null;
  }

  if (!submitResponse.ok) {
    const detail = (submitJson && (submitJson.error || submitJson.message)) || submitText || 'Unknown Higgsfield submit error';
    throw new Error(`Higgsfield request failed with status ${submitResponse.status}: ${detail}`);
  }

  const requestId = submitJson?.request_id || submitJson?.requestId || submitJson?.id || null;
  const statusUrl = submitJson?.status_url || submitJson?.statusUrl || (requestId ? `https://platform.higgsfield.ai/requests/${requestId}/status` : null);

  let current = submitJson || {};
  let imageUrl = findFirstImageUrl(current);
  let status = getHiggsfieldStatus(current) || 'queued';

  const deadline = Date.now() + 45000;
  while (!imageUrl && status !== 'failed' && status !== 'nsfw' && status !== 'canceled' && Date.now() < deadline && statusUrl) {
    await sleep(2000);
    const pollResponse = await fetchWithTimeout(statusUrl, {
      method: 'GET',
      headers: requestHeaders
    }, 10000);

    const pollText = await pollResponse.text();
    let pollJson = null;
    try {
      pollJson = pollText ? JSON.parse(pollText) : null;
    } catch {
      pollJson = null;
    }

    if (!pollResponse.ok) {
      const detail = (pollJson && (pollJson.error || pollJson.message)) || pollText || 'Unknown Higgsfield status error';
      throw new Error(`Higgsfield status polling failed with status ${pollResponse.status}: ${detail}`);
    }

    current = pollJson || {};
    imageUrl = findFirstImageUrl(current);
    status = getHiggsfieldStatus(current) || status;
  }

  if (!imageUrl) {
    const message = status === 'queued' || status === 'in_progress'
      ? 'Soul2 generation timed out before an image was produced. The account may not have Soul2 access yet, or the model may still be unavailable.'
      : `Soul2 generation finished with status "${status || 'unknown'}" but no image URL was returned.`;
    throw new Error(message);
  }

  return {
    skipped: false,
    requestId,
    statusUrl,
    status,
    imageUrl,
    raw: current
  };
}

function getOpenAIConfig() {
  return {
    apiKey: process.env.OPENAI_API_KEY || '',
    model: process.env.OPENAI_MODEL || 'gpt-5.4-mini'
  };
}

async function callOpenAI({ model, birthDate, zodiacKey, numbers, question }) {
  const { apiKey } = getOpenAIConfig();
  if (!apiKey) {
    return 'OpenAI API key is missing. Showing local analysis only.';
  }

  const response = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model,
      instructions:
        'You are a Korean-language zodiac recommendation chatbot. Be concise and friendly. Explain the chosen lucky numbers in a natural way. Avoid mystical overclaiming. Format: 1. Zodiac name 2. Lucky numbers 3. Reason in 2-4 sentences 4. One short closing line',
      input: [
        `Birthdate: ${birthDate}`,
        `Zodiac key: ${zodiacKey}`,
        `Lucky numbers: ${numbers.join(', ')}`,
        `User question: ${question || ''}`
      ].join('\n'),
      reasoning: { effort: 'low' },
      text: { verbosity: 'medium' },
      store: false
    })
  });

  if (!response.ok) {
    throw new Error(`OpenAI request failed with status ${response.status}`);
  }

  const data = await response.json();
  if (typeof data.output_text === 'string' && data.output_text.trim()) {
    return data.output_text.trim();
  }

  if (Array.isArray(data.output)) {
    const parts = [];
    for (const item of data.output) {
      if (item.type === 'message' && Array.isArray(item.content)) {
        for (const content of item.content) {
          if (typeof content.text === 'string') parts.push(content.text);
        }
      }
    }
    if (parts.length) return parts.join('\n').trim();
  }

  return 'OpenAI response could not be read.';
}

async function saveToSupabase(payload) {
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !supabaseServiceKey) {
    return { skipped: true };
  }

  const response = await fetch(`${supabaseUrl.replace(/\/$/, '')}/rest/v1/lotto_draws`, {
    method: 'POST',
    headers: {
      apikey: supabaseServiceKey,
      Authorization: `Bearer ${supabaseServiceKey}`,
      'Content-Type': 'application/json',
      Prefer: 'return=representation'
    },
    body: JSON.stringify(payload)
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Supabase insert failed: ${response.status} ${text}`);
  }

  return response.json();
}

function setCors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

module.exports = async function handler(req, res) {
  setCors(res);

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const payload = req.body || {};
  if (!payload.birthDate) {
    res.status(400).json({ error: 'birthDate is required' });
    return;
  }

  const date = parseBirthDate(payload.birthDate);
  if (!date) {
    res.status(400).json({ error: 'Invalid birthDate' });
    return;
  }

  const sign = getZodiacByDate(date.getUTCMonth() + 1, date.getUTCDate());
  const numbers = deriveNumbers(date, sign);
  const model = process.env.OPENAI_MODEL || 'gpt-5.4-mini';

  const [higgsfieldResult, openAiResult] = await Promise.allSettled([
    callHiggsfieldCard({
      sign,
      numbers,
      birthDate: payload.birthDate,
      name: payload.name || '',
      question: payload.question || '',
      credentialsPayload: payload
    }),
    callOpenAI({
      model,
      birthDate: payload.birthDate,
      zodiacKey: sign.key,
      numbers,
      question: payload.question
    })
  ]);

  let explanation;
  if (openAiResult.status === 'fulfilled') {
    explanation = openAiResult.value;
  } else {
    const error = openAiResult.reason;
    explanation = [
      `${sign.name}`,
      `Lucky numbers: ${numbers.join(', ')}`,
      'The numbers were derived from the birthdate pattern and the zodiac\'s recurring lucky set, then deduplicated and sorted for readability.',
      'OpenAI was not reachable from this server, so I returned a safe local explanation instead.',
      error?.message ? `Debug: ${error.message}` : ''
    ].filter(Boolean).join('\n');
  }

  const higgsfield = higgsfieldResult.status === 'fulfilled'
    ? higgsfieldResult.value
    : {
        skipped: false,
        imageUrl: null,
        status: 'failed',
        error: higgsfieldResult.reason?.message || 'Unknown Higgsfield error'
      };

  const record = {
    birth_date: payload.birthDate,
    name: payload.name || null,
    question: payload.question || null,
    zodiac_key: sign.key,
    zodiac_name: sign.name,
    lucky_numbers: numbers,
    explanation,
    constellation_svg: buildConstellationSvg(sign),
    model
  };

  try {
    await saveToSupabase(record);
  } catch (error) {
    res.status(500).json({ error: error.message });
    return;
  }

  res.status(200).json({
    profile: {
      birthDate: payload.birthDate,
      signKey: sign.key,
      signName: sign.name,
      numbers,
      constellationSvg: buildConstellationSvg(sign),
      higgsfieldStatus: higgsfield.status,
      higgsfieldRequestId: higgsfield.requestId || null,
      cardImageUrl: higgsfield.imageUrl || null,
      cardImageError: higgsfield.error || null
    },
    explanation
  });
};
