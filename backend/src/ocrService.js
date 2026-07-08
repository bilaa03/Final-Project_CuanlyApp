import 'dotenv/config';

/**
 * Extracts transaction details from a base64 receipt image using Gemini Multimodal API.
 * @param {string} base64Image Base64 string of the image (without data:image/xx;base64, prefix)
 * @param {string} mimeType The mime type of the image, e.g. "image/jpeg", "image/png"
 * @returns {Promise<{title: string, amount: number, category: string, walletName: string}>}
 */
export async function extractReceiptData(base64Image, mimeType = 'image/jpeg') {
  const apiKey = process.env.GEMINI_API_KEY;
  const model = process.env.GEMINI_MODEL || 'gemini-2.0-flash';

  // Fallback simulator if API Key is missing or default local provider
  if (!apiKey || apiKey.trim() === '' || apiKey.includes('YOUR_') || process.env.AI_PROVIDER === 'local') {
    console.log('Gemini API key is not configured or set to local. Using OCR simulator fallback.');
    return getMockOcrData();
  }

  // Define prompt instructing Gemini to return valid JSON
  const prompt = [
    'Kamu adalah Cuanly OCR Engine.',
    'Tugasmu adalah menganalisis gambar struk/receipt belanja ini dan mengekstrak informasi keuangan berikut:',
    '1. title: Nama toko/merchant atau ringkasan pembelian yang representatif (contoh: "Starbucks Coffee", "Indomaret").',
    '2. amount: Total pengeluaran nominal angka bulat (number) saja tanpa simbol rupiah/titik desimal (contoh: 45000).',
    '3. category: Kategori transaksi. Kamu WAJIB memilih salah satu dari daftar ini saja:',
    '   - "Makanan" (untuk makanan, minuman, kafe, restoran)',
    '   - "Transport" (untuk bensin, parkir, ojek, tol, tiket perjalanan)',
    '   - "Belanja" (untuk belanja bulanan, minimarket, baju, barang retail)',
    '   - "Hiburan" (untuk bioskop, game, rekreasi)',
    '   - "Lainnya" (jika tidak masuk kategori mana pun)',
    '4. walletName: Metode pembayaran yang terdeteksi atau disarankan berdasarkan struk (contoh: "Cash", "GoPay", "Bank Mandiri", "OVO", "ShopeePay").',
    '',
    'PENTING: Kembalikan respon HANYA dalam format JSON valid dengan key: title, amount, category, walletName. Jangan tambahkan penjelasan lain di luar JSON.',
  ].join('\n');

  const requestBody = {
    contents: [
      {
        parts: [
          { text: prompt },
          {
            inlineData: {
              mimeType: mimeType,
              data: base64Image,
            },
          },
        ],
      },
    ],
    generationConfig: {
      temperature: 0.1,
      responseMimeType: 'application/json',
    },
  };

  const candidateModels = [
    model,
    'gemini-2.0-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash',
  ];

  // Try calling Gemini API with fallback models if model is not supported
  let response;
  let data = {};
  for (const candidateModel of candidateModels) {
    try {
      response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(candidateModel)}:generateContent?key=${encodeURIComponent(apiKey)}`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(requestBody),
        }
      );

      data = await response.json().catch(() => ({}));
      if (response.ok) break;
    } catch (err) {
      console.error(`Failed to call Gemini model ${candidateModel}:`, err.message);
    }
  }

  if (!response?.ok) {
    console.error('Gemini API call failed:', data.error?.message || 'Unknown error');
    return getMockOcrData();
  }

  try {
    const textResult = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!textResult) throw new Error('Empty response from Gemini API');

    const parsed = JSON.parse(textResult.trim());
    return {
      title: parsed.title || 'Struk Belanja',
      amount: Number(parsed.amount) || 0,
      category: validateCategory(parsed.category),
      walletName: parsed.walletName || 'Cash',
    };
  } catch (err) {
    console.error('Failed to parse Gemini OCR response:', err.message);
    return getMockOcrData();
  }
}

function validateCategory(cat) {
  const valid = ['Makanan', 'Transport', 'Belanja', 'Hiburan', 'Lainnya'];
  if (valid.includes(cat)) return cat;
  // Map some variations
  if (!cat) return 'Lainnya';
  const c = cat.toLowerCase();
  if (c.includes('makan') || c.includes('minum') || c.includes('cafe') || c.includes('resto')) return 'Makanan';
  if (c.includes('trans') || c.includes('ojek') || c.includes('grab') || c.includes('gojek') || c.includes('bensin') || c.includes('parkir')) return 'Transport';
  if (c.includes('belanja') || c.includes('beli') || c.includes('indo') || c.includes('alfa') || c.includes('super')) return 'Belanja';
  if (c.includes('hibur') || c.includes('game') || c.includes('movie') || c.includes('nonton')) return 'Hiburan';
  return 'Lainnya';
}

function getMockOcrData() {
  return {
    title: 'Starbucks Coffee (Simulated)',
    amount: 58000,
    category: 'Makanan',
    walletName: 'GoPay',
  };
}
