/**
 * Cloudflare Worker for LazyJod Thai Bank Slip OCR Proxy (Gemini Vision)
 *
 * Runs on Cloudflare's global edge network (Bangkok POP) with zero cold start.
 * Free tier includes 100,000 requests/day.
 */

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

// Helper: Convert ArrayBuffer to Base64 in chunks (safe for large buffers in V8)
function arrayBufferToBase64(buffer) {
  let binary = '';
  const bytes = new Uint8Array(buffer);
  const len = bytes.byteLength;
  const chunkSize = 8192;
  for (let i = 0; i < len; i += chunkSize) {
    const chunk = bytes.subarray(i, Math.min(i + chunkSize, len));
    binary += String.fromCharCode.apply(null, chunk);
  }
  return btoa(binary);
}

// CORS Headers helper
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Handle CORS Preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Health check endpoint
    if (url.pathname === '/' || url.pathname === '/health') {
      return new Response(
        JSON.stringify({
          status: 'ok',
          service: 'LazyJod Cloudflare Worker (Gemini Vision Proxy)',
          timestamp: new Date().toISOString(),
          geminiConfigured: Boolean(env.GEMINI_API_KEY),
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }


    // OCR Enhance endpoint
    if (url.pathname === '/api/ocr/enhance' && request.method === 'POST') {
      try {
        const apiKey = env.GEMINI_API_KEY;
        if (!apiKey) {
          return new Response(
            JSON.stringify({
              error: 'GEMINI_API_KEY is not configured in Cloudflare Worker environment variables',
              recipient_name: null,
              sender_name: null,
              raw_text: '',
            }),
            {
              status: 500,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            }
          );
        }

        const formData = await request.formData();
        const file = formData.get('slip_image');

        if (!file || typeof file === 'string') {
          return new Response(
            JSON.stringify({
              error: 'Missing file upload. Expected field: slip_image',
            }),
            {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            }
          );
        }

        const arrayBuffer = await file.arrayBuffer();
        const base64Data = arrayBufferToBase64(arrayBuffer);
        const mimeType = file.type || 'image/jpeg';

        const modelName = env.GEMINI_MODEL || 'gemini-3.6-flash';
        const geminiApiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`;

        const payload = {
          contents: [
            {
              parts: [
                { text: EXTRACTION_PROMPT },
                {
                  inline_data: {
                    mime_type: mimeType,
                    data: base64Data,
                  },
                },
              ],
            },
          ],
          generationConfig: {
            temperature: 0.1,
          },
        };

        const geminiRes = await fetch(geminiApiUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });

        if (!geminiRes.ok) {
          const errText = await geminiRes.text();
          console.error('Gemini API Error:', errText);
          return new Response(
            JSON.stringify({
              error: `Gemini API returned ${geminiRes.status}`,
              details: errText,
              recipient_name: null,
              sender_name: null,
              raw_text: '',
            }),
            {
              status: 502,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            }
          );
        }

        const geminiData = await geminiRes.json();
        const rawTextResponse =
          geminiData?.candidates?.[0]?.content?.parts?.[0]?.text || '';

        // Strip markdown fences
        const cleanedJson = rawTextResponse
          .replace(/```json/gi, '')
          .replace(/```/g, '')
          .trim();

        let parsed = {};
        try {
          parsed = JSON.parse(cleanedJson);
        } catch {
          parsed = {
            recipient_name: null,
            sender_name: null,
            raw_text: rawTextResponse,
          };
        }

        return new Response(
          JSON.stringify({
            recipient_name: parsed.recipient_name || null,
            sender_name: parsed.sender_name || null,
            raw_text: parsed.raw_text || rawTextResponse,
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      } catch (err) {
        console.error('Worker error:', err);
        return new Response(
          JSON.stringify({
            error: err.message || 'Internal worker error',
            recipient_name: null,
            sender_name: null,
            raw_text: '',
          }),
          {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      }
    }

    return new Response('Not Found', {
      status: 404,
      headers: corsHeaders,
    });
  },
};
