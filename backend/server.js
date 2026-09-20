const express = require('express');
const cors = require('cors');
const multer = require('multer');
const dotenv = require('dotenv');
const { GoogleGenerativeAI } = require('@google/generative-ai');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 8080;

// Enable CORS for Flutter mobile/web clients
app.use(cors());
app.use(express.json());

// Configure multer memory storage (no disk I/O, fast in-memory buffer)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 15 * 1024 * 1024, // 15 MB max image size
  },
});

// Health check endpoint
app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    service: 'LazyJod Thai Bank Slip OCR Proxy (Gemini Vision)',
    version: '1.0.0',
    geminiConfigured: Boolean(process.env.GEMINI_API_KEY),
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Prompt specialized for Thai banking slips
const EXTRACTION_PROMPT = `
คุณคือผู้เชี่ยวชาญด้าน OCR สลิปโอนเงินธนาคารไทย (Thai Bank Transfer Slips)
กรุณาวิเคราะห์ภาพสลิปที่แนบมา และดึงข้อมูลอย่างแม่นยำ 100% โดยเฉพาะชื่อ-นามสกุลภาษาไทยของผู้รับโอน

ตอบกลับเป็น JSON เท่านั้น (ไม่ต้องมีคำอธิบายอื่นนอกเหนือจาก JSON) ในโครงสร้างต่อไปนี้:
{
  "recipient_name": "ชื่อ-นามสกุล หรือชื่อร้านค้า/บริษัท ของผู้รับเงิน (ภาษาไทยหรืออังกฤษตามสลิป)",
  "sender_name": "ชื่อ-นามสกุล ของผู้โอนเงิน (ถ้ามี)",
  "raw_text": "ข้อความทั้งหมดที่ปรากฏบนสลิปแบบเรียงบรรทัด"
}

กฎสำคัญ:
1. "recipient_name": ต้องเป็นชื่อคน ร้านค้า หรือนิติบุคคลจริง เช่น "นาย สมชาย ใจดี", "ร้านกาแฟสุขใจ", "บจก. เอสซีจี"
   - ห้ามใส่ชื่อธนาคารเป็นชื่อผู้รับ (เช่น กสิกรไทย, KTB, SCB, PromptPay, พร้อมเพย์)
   - ห้ามใส่เลขบัญชีลงใน recipient_name
   - หากบนสลิปไม่พบชื่อคนหรือร้าน ให้ใส่ null
2. "sender_name": ชื่อผู้โอนเงิน ถ้าไม่พบให้ใส่ null
3. ตอบกลับเป็น valid JSON Object เท่านั้น
`;

// Main OCR enhance endpoint matching Flutter HybridOcrService
app.post('/api/ocr/enhance', upload.single('slip_image'), async (req, res) => {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey || apiKey === 'YOUR_GEMINI_API_KEY_HERE') {
      console.error('[GeminiProxy] Missing GEMINI_API_KEY in environment or .env file');
      return res.status(500).json({
        error: 'Backend proxy is running, but GEMINI_API_KEY is not configured yet in .env',
        recipient_name: null,
        sender_name: null,
        raw_text: '',
      });
    }

    if (!req.file) {
      return res.status(400).json({
        error: 'No image uploaded. Expected field name: slip_image',
      });
    }

    console.log(`[GeminiProxy] Received image: ${req.file.originalname || 'slip.jpg'} (${(req.file.size / 1024).toFixed(1)} KB)`);

    const genAI = new GoogleGenerativeAI(apiKey);
    const modelName = process.env.GEMINI_MODEL || 'gemini-1.5-flash';
    const model = genAI.getGenerativeModel({ model: modelName });

    const mimeType = req.file.mimetype || 'image/jpeg';
    const imagePart = {
      inlineData: {
        data: req.file.buffer.toString('base64'),
        mimeType: mimeType,
      },
    };

    const result = await model.generateContent([EXTRACTION_PROMPT, imagePart]);
    const responseText = result.response.text();

    console.log('[GeminiProxy] Gemini raw response:\n', responseText);

    // Clean markdown fences (```json ... ```) if present
    const cleanedJson = responseText
      .replace(/```json/gi, '')
      .replace(/```/g, '')
      .trim();

    let parsed;
    try {
      parsed = JSON.parse(cleanedJson);
    } catch (parseErr) {
      console.warn('[GeminiProxy] Failed to parse JSON strictly. Raw response text:', responseText);
      parsed = {
        recipient_name: null,
        sender_name: null,
        raw_text: responseText,
      };
    }

    return res.json({
      recipient_name: parsed.recipient_name || null,
      sender_name: parsed.sender_name || null,
      raw_text: parsed.raw_text || '',
    });
  } catch (error) {
    console.error('[GeminiProxy] Error during OCR enhancement:', error);
    return res.status(500).json({
      error: error.message || 'Internal proxy error',
      recipient_name: null,
      sender_name: null,
      raw_text: '',
    });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('====================================================');
  console.log(`🚀 LazyJod Gemini Vision Backend Proxy is running!`);
  console.log(`📡 Local:            http://localhost:${PORT}`);
  console.log(`📱 Android Emulator: http://10.0.2.2:${PORT}`);
  console.log(`🔍 Health check:     http://localhost:${PORT}/health`);
  console.log('====================================================');
});
