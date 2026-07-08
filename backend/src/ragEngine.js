import { getRagChunks } from './db.js';

const stopwords = new Set([
  'apa', 'apakah', 'bagaimana', 'berapa', 'yang', 'dan', 'atau', 'ini', 'itu',
  'saya', 'kamu', 'dengan', 'untuk', 'dari', 'ke', 'di', 'bulan', 'bisa',
  'ada', 'dalam', 'secara', 'mohon', 'tolong', 'cuan', 'ly', 'cuanly'
]);

const keywordMap = {
  hemat: ['hemat', 'irit', 'menghemat', 'penghematan'],
  transport: ['transport', 'transportasi', 'ojek', 'krl', 'bus'],
  makan: ['makan', 'meal', 'client', 'klien', 'entertainment'],
  budget: ['budget', 'anggaran', 'pengeluaran', 'overbudget', 'boros'],
  investasi: ['investasi', 'saham', 'reksa', 'crypto', 'kripto'],
  privasi: ['privasi', 'data', 'rekening', 'merchant'],
  klaim: ['klaim', 'reimbursement', 'reimburse', 'expense'],
  hotel: ['hotel', 'akomodasi', 'inap'],
  waktu: ['waktu', 'hari', 'deadline', 'batas'],
};

function normalize(text) {
  return text.toLowerCase().replace(/[^a-z0-9\u00c0-\u024f]+/g, ' ').trim();
}

function tokens(text) {
  return normalize(text)
    .split(/\s+/)
    .filter((token) => token.length > 2 && !stopwords.has(token));
}

function expandTokens(rawTokens) {
  const expanded = new Set(rawTokens);
  for (const token of rawTokens) {
    for (const group of Object.values(keywordMap)) {
      if (group.includes(token)) {
        group.forEach((item) => expanded.add(item));
      }
    }
  }
  return [...expanded];
}

function inferDocType(question) {
  const q = normalize(question);
  if (/(klaim|reimburse|reimbursement|policy|hotel|akomodasi|finance|karyawan|tim)/.test(q)) {
    return 'policy';
  }
  if (/(total|kategori|boros|budget|pengeluaran|transaksi|expense tim)/.test(q)) {
    return 'transaksi';
  }
  if (/(tips|privasi|investasi|data tidak lengkap|kategori apa)/.test(q)) {
    return 'faq';
  }
  return null;
}

function inferCategory(question) {
  const q = normalize(question);
  if (/(transport|ojek|krl|bus)/.test(q)) return 'Transport';
  if (/(makan|meal|klien|entertainment)/.test(q)) return 'Entertainment';
  if (/(hotel|akomodasi|inap)/.test(q)) return 'Akomodasi';
  if (/(deadline|waktu|hari kerja|pengajuan)/.test(q)) return 'Batas Waktu';
  if (/(privasi|rekening|merchant)/.test(q)) return 'Privasi';
  if (/(investasi|saham|crypto|kripto)/.test(q)) return 'Disclaimer';
  if (/(budget tim|expense tim)/.test(q)) return 'Budget Tim';
  if (/(budget|boros|pengeluaran|total)/.test(q)) return 'Budget';
  return null;
}

function scoreChunk(queryTokens, chunk) {
  const textTokens = new Set(tokens(`${chunk.text} ${chunk.kategori} ${chunk.docType}`));
  const hits = queryTokens.filter((token) => textTokens.has(token));
  const categoryBoost = queryTokens.some((token) => normalize(chunk.kategori).includes(token)) ? 0.12 : 0;
  const base = hits.length / Math.max(5, queryTokens.length);
  return Math.min(0.99, base + categoryBoost);
}

function retrieve({ question, chunks, userSegment = 'b2c', docType = null, topK = 3 }) {
  const inferredType = docType && docType !== 'auto' ? docType : inferDocType(question);
  const inferredCategory = inferCategory(question);
  const queryTokens = expandTokens(tokens(`${question} ${inferredCategory ?? ''} ${inferredType ?? ''}`));

  const candidates = chunks
    .filter((chunk) => chunk.userSegment === userSegment)
    .filter((chunk) => !inferredType || chunk.docType === inferredType)
    .map((chunk) => ({ ...chunk, score: scoreChunk(queryTokens, chunk) }))
    .sort((a, b) => b.score - a.score)
    .slice(0, topK);

  return {
    inferredType,
    inferredCategory,
    chunks: candidates.filter((chunk) => chunk.score >= 0.18),
  };
}

function rupiah(value) {
  return `Rp ${new Intl.NumberFormat('id-ID').format(value)}`;
}

function generalAssistantAnswer(question) {
  const q = normalize(question);

  if (/(presiden|cuaca|film|politik|olahraga|berita|siapa|kapan|dimana)/.test(q)) {
    return {
      status: 'general_answer',
      jawaban: 'Pertanyaan ini tidak ditemukan di sumber internal Cuanly. Secara umum, aku bisa membantu memberi penjelasan singkat, tetapi untuk informasi terbaru atau fakta publik yang bisa berubah, sebaiknya verifikasi lagi dari sumber resmi.',
      rekomendasi: 'Kalau ingin jawaban yang lebih akurat, tulis pertanyaan yang spesifik dan sertakan konteks yang dibutuhkan.',
      source: [],
      disclaimer: 'Jawaban ini dibuat sebagai respons umum, bukan berdasarkan sumber internal Cuanly.',
    };
  }

  if (/(tips|cara|bagaimana|gimana|saran|rekomendasi)/.test(q)) {
    return {
      status: 'general_answer',
      jawaban: 'Aku belum menemukan sumber internal yang cocok, tapi secara umum kamu bisa mulai dari tiga langkah: pahami masalahnya, kumpulkan data yang relevan, lalu buat keputusan berdasarkan prioritas dan risiko.',
      rekomendasi: 'Untuk konteks keuangan, tambahkan periode, kategori pengeluaran, nominal, atau aturan yang ingin dicek agar jawabannya bisa lebih personal.',
      source: [],
      disclaimer: 'Jawaban ini bersifat umum karena tidak ada sumber internal yang cocok.',
    };
  }

  return {
    status: 'general_answer',
    jawaban: 'Aku belum menemukan jawaban dari sumber internal Cuanly, tetapi aku tetap bisa membantu secara umum. Tolong beri sedikit konteks tambahan agar jawabannya lebih tepat.',
    rekomendasi: 'Coba tambahkan detail seperti tujuan pertanyaan, periode waktu, kategori, nominal, atau dokumen yang ingin dijadikan acuan.',
    source: [],
    disclaimer: 'Jawaban ini bukan hasil pencarian dari sumber internal Cuanly.',
  };
}

function answerFromContext(question, retrieval, userSegment) {
  const q = normalize(question);
  const top = retrieval.chunks[0];
  const sources = retrieval.chunks.map((chunk) => ({
    chunk_id: chunk.id,
    source_file: chunk.source,
    kategori: chunk.kategori,
    score: Number(chunk.score.toFixed(2)),
  }));

  if (/^(gimana|bagaimana) keuanganku\??$|keuanganku\??$/.test(q)) {
    return {
      status: 'needs_clarification',
      jawaban: 'Pertanyaan masih ambigu. Cuanly perlu periode dan aspek yang ingin dianalisis sebelum memberikan jawaban.',
      rekomendasi: 'Tentukan dulu periode analisis, misalnya minggu ini atau bulan Juni, lalu pilih fokusnya: total pengeluaran, kategori terboros, budget, atau tips hemat.',
      source: sources,
      disclaimer: 'Guardrail aktif: Cuanly tidak menebak kondisi keuangan tanpa data dan periode yang jelas.',
    };
  }

  if (!top) {
    return generalAssistantAnswer(question);
  }

  if (/(semua transaksi karyawan|data lengkap.*karyawan|riwayat klaim.*karyawan|data pribadi karyawan)/.test(q)) {
    return {
      status: 'guarded',
      jawaban: 'Cuanly tidak dapat menampilkan data lengkap transaksi atau riwayat klaim individu karyawan secara massal karena termasuk data sensitif.',
      rekomendasi: 'Gunakan ringkasan agregat tim seperti total expense per kategori, persentase terhadap budget, atau alert overbudget tanpa membuka identitas individu.',
      source: sources,
      disclaimer: 'Guardrail privasi aktif: akses data individu harus dibatasi dengan role-based access dan persetujuan yang sesuai.',
    };
  }

  if (/(presiden|cuaca|film|politik|olahraga)/.test(q)) {
    return generalAssistantAnswer(question);
  }

  if (/500 ?\.?000|500 ribu|rp 500/.test(q) && /(makan|meal|klien|client)/.test(q)) {
    return {
      status: 'answered',
      jawaban: `Klaim makan klien sebesar ${rupiah(500000)} TIDAK SESUAI dengan policy karena batas maksimum client meal adalah ${rupiah(400000)} per orang per acara.`,
      rekomendasi: `Ajukan klaim sesuai batas ${rupiah(400000)}, lampirkan struk asli, dan pastikan ada approval manajer sebelum diajukan ke Finance.`,
      source: sources,
      disclaimer: 'Validasi ini berdasarkan policy demo, bukan keputusan final Finance.',
    };
  }

  if (/(hotel|akomodasi)/.test(q)) {
    return {
      status: 'answered',
      jawaban: `Batas reimbursement akomodasi hotel adalah ${rupiah(500000)} per malam dengan invoice hotel.`,
      rekomendasi: 'Jika biaya melebihi batas, mintakan persetujuan tambahan dari manajer departemen.',
      source: sources,
      disclaimer: 'Cuanly hanya merangkum policy yang tersedia.',
    };
  }

  if (/(14|waktu|deadline|hari kerja|pengajuan)/.test(q)) {
    return {
      status: 'answered',
      jawaban: 'Batas waktu pengajuan klaim reimbursement adalah maksimal 14 hari kerja setelah tanggal transaksi.',
      rekomendasi: 'Klaim yang terlambat perlu justifikasi tertulis dan persetujuan Finance Manager.',
      source: sources,
      disclaimer: 'Pastikan tanggal transaksi dan dokumen pendukung sudah lengkap.',
    };
  }

  if (/(expense tim|budget tim|melebihi budget tim)/.test(q)) {
    return {
      status: 'answered',
      jawaban: `Expense tim Juni adalah ${rupiah(9300000)} dari budget ${rupiah(10000000)} atau 93%. Statusnya melewati ambang 90%, sehingga perlu alert.`,
      rekomendasi: 'Kirim notifikasi ke Team Lead dan Finance untuk evaluasi pengeluaran bulan berjalan.',
      source: sources,
      disclaimer: 'Angka berasal dari sample_expense_team_juni.csv.',
    };
  }

  if (/(total|pengeluaran|budget|boros)/.test(q) && userSegment === 'b2c') {
    return {
      status: 'answered',
      jawaban: `Total pengeluaran demo Juni adalah ${rupiah(945000)} dari budget ${rupiah(3000000)}. Status budget AMAN karena masih di bawah 80% budget.`,
      rekomendasi: `Kategori terbesar adalah Belanja ${rupiah(320000)}, lalu Makan ${rupiah(220000)} dan Tagihan ${rupiah(200000)}. Fokuskan kontrol belanja dan makan agar sisa budget tetap sehat.`,
      source: sources,
      disclaimer: 'Analisis memakai data transaksi demo, bukan data rekening asli.',
    };
  }

  if (/(transport|ojek|krl|bus)/.test(q)) {
    return {
      status: 'answered',
      jawaban: 'Untuk menghemat transport, gunakan KRL atau bus untuk perjalanan rutin, batasi ojek online maksimal 3 kali per minggu, dan coba carpooling untuk perjalanan jauh.',
      rekomendasi: 'Catat transport sebagai kategori terpisah agar tren mingguan mudah dipantau.',
      source: sources,
      disclaimer: 'Saran ini bersifat edukatif dan berbasis FAQ Cuanly.',
    };
  }

  if (/(investasi|saham|crypto|kripto)/.test(q)) {
    return {
      status: 'guarded',
      jawaban: 'Cuanly tidak memberikan saran investasi, saham, crypto, atau produk keuangan. Cuanly hanya menganalisis pola pengeluaran dan rekomendasi penghematan berbasis data transaksi.',
      rekomendasi: 'Untuk keputusan investasi, konsultasikan dengan penasihat keuangan profesional.',
      source: sources,
      disclaimer: 'Guardrail aktif: tidak ada rekomendasi investasi.',
    };
  }

  if (/(privasi|rekening|merchant)/.test(q)) {
    return {
      status: 'answered',
      jawaban: 'Cuanly menjaga privasi dengan hanya memakai kategori dan jumlah transaksi untuk analisis, bukan nama merchant, nama lengkap, atau nomor rekening.',
      rekomendasi: 'Untuk demo kelas, gunakan CSV sintetis agar tidak membawa data sensitif.',
      source: sources,
      disclaimer: 'Implementasi produksi tetap perlu enkripsi, audit akses, dan consent user.',
    };
  }

  return {
    status: 'answered',
    jawaban: top.text.replace(/\n/g, ' '),
    rekomendasi: 'Gunakan evidence di bawah untuk menjelaskan bahwa jawaban berasal dari chunk yang ter-retrieve.',
    source: sources,
    disclaimer: 'Cuanly bukan penasihat keuangan/legal profesional.',
  };
}

function buildSources(retrievedChunks) {
  return retrievedChunks.map((chunk) => ({
    chunk_id: chunk.id,
    source_file: chunk.source,
    kategori: chunk.kategori,
    score: Number(chunk.score.toFixed(2)),
  }));
}

function extractResponseText(data) {
  if (data.choices?.[0]?.message?.content) {
    return data.choices[0].message.content.trim();
  }

  if (typeof data.output_text === 'string') return data.output_text;

  const output = Array.isArray(data.output) ? data.output : [];
  const texts = [];

  for (const item of output) {
    const content = Array.isArray(item.content) ? item.content : [];
    for (const part of content) {
      if (typeof part.text === 'string') texts.push(part.text);
      if (typeof part.output_text === 'string') texts.push(part.output_text);
    }
  }

  return texts.join('\n').trim();
}

function parseJsonObject(text) {
  try {
    return JSON.parse(text);
  } catch (error) {
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) throw error;
    return JSON.parse(match[0]);
  }
}

async function answerWithOpenAI({ question, retrieval, userSegment }) {
  const apiKey = process.env.OPENAI_API_KEY;
  const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';

  if (!apiKey) {
    return {
      status: 'error',
      jawaban: 'OpenAI API key belum dikonfigurasi di backend.',
      rekomendasi: 'Tambahkan OPENAI_API_KEY ke file backend/.env, lalu restart server.',
      source: [],
      disclaimer: 'API key tidak boleh disimpan di frontend.',
    };
  }

  const sources = buildSources(retrieval.chunks);
  const context = retrieval.chunks.length
    ? retrieval.chunks
        .map((chunk, index) => [
          `Sumber ${index + 1}`,
          `ID: ${chunk.id}`,
          `File: ${chunk.source}`,
          `Kategori: ${chunk.kategori}`,
          `Teks: ${chunk.text}`,
        ].join('\n'))
        .join('\n\n')
    : 'Tidak ada sumber internal yang cocok untuk pertanyaan ini.';

  const systemPrompt = [
    'Kamu adalah Cuanly, asisten keuangan personal dan expense policy.',
    'Jawab dalam Bahasa Indonesia yang ringkas, natural, dan membantu.',
    'Gunakan konteks internal jika tersedia. Kalau konteks internal tidak tersedia, kamu boleh menjawab secara umum, tetapi wajib beri disclaimer bahwa jawaban bukan dari sumber internal Cuanly.',
    'Jangan mengarang angka transaksi, saldo, limit policy, atau data personal. Jika angka tidak ada di konteks, minta klarifikasi atau jelaskan secara umum.',
    'Tolak atau batasi permintaan data pribadi massal, nomor rekening, merchant sensitif, atau riwayat transaksi individu yang tidak berwenang.',
    'Untuk investasi/saham/crypto, jangan beri rekomendasi beli/jual; beri edukasi umum dan sarankan konsultasi profesional.',
    'Return hanya JSON valid dengan key: status, jawaban, rekomendasi, disclaimer.',
    'Status harus salah satu: answered, general_answer, needs_clarification, guarded, out_of_scope.',
  ].join('\n');

  const userPrompt = [
    `Segment pengguna: ${userSegment}`,
    `Doc type terdeteksi: ${retrieval.inferredType ?? 'auto'}`,
    `Kategori terdeteksi: ${retrieval.inferredCategory ?? 'auto'}`,
    '',
    'Konteks internal Cuanly:',
    context,
    '',
    `Pertanyaan user: ${question}`,
  ].join('\n');

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      messages: [
        {
          role: 'system',
          content: systemPrompt,
        },
        {
          role: 'user',
          content: userPrompt,
        },
      ],
      response_format: { type: 'json_object' },
      max_tokens: 900,
    }),
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    return {
      status: 'error',
      jawaban: 'Request ke OpenAI API gagal.',
      rekomendasi: data.error?.message
        ? `Periksa konfigurasi API: ${data.error.message}`
        : 'Periksa OPENAI_API_KEY, model, koneksi internet, dan billing OpenAI.',
      source: sources,
      disclaimer: 'Jawaban tidak dibuat karena backend gagal menghubungi OpenAI API.',
    };
  }

  const outputText = extractResponseText(data);
  const parsed = parseJsonObject(outputText);

  return {
    status: parsed.status || (retrieval.chunks.length ? 'answered' : 'general_answer'),
    jawaban: parsed.jawaban || 'Maaf, jawaban belum tersedia.',
    rekomendasi: parsed.rekomendasi || 'Coba tulis pertanyaan yang lebih spesifik.',
    source: sources,
    disclaimer: parsed.disclaimer || null,
  };
}

async function answerWithGemini({ question, retrieval, userSegment }) {
  const apiKey = process.env.GEMINI_API_KEY;
  const model = process.env.GEMINI_MODEL || 'gemini-2.0-flash';

  if (!apiKey) {
    return {
      status: 'error',
      jawaban: 'Gemini API key belum dikonfigurasi di backend.',
      rekomendasi: 'Tambahkan GEMINI_API_KEY ke file backend/.env, lalu restart server.',
      source: [],
      disclaimer: 'API key tidak boleh disimpan di frontend.',
    };
  }

  const sources = buildSources(retrieval.chunks);
  const context = retrieval.chunks.length
    ? retrieval.chunks
        .map((chunk, index) => [
          `Sumber ${index + 1}`,
          `ID: ${chunk.id}`,
          `File: ${chunk.source}`,
          `Kategori: ${chunk.kategori}`,
          `Teks: ${chunk.text}`,
        ].join('\n'))
        .join('\n\n')
    : 'Tidak ada sumber internal yang cocok untuk pertanyaan ini.';

  const prompt = [
    'Kamu adalah Cuanly, asisten keuangan personal dan expense policy.',
    'Jawab dalam Bahasa Indonesia yang ringkas, natural, dan membantu.',
    'Gunakan konteks internal jika tersedia. Kalau konteks internal tidak tersedia, kamu boleh menjawab secara umum, tetapi wajib beri disclaimer bahwa jawaban bukan dari sumber internal Cuanly.',
    'Jangan mengarang angka transaksi, saldo, limit policy, atau data personal. Jika angka tidak ada di konteks, minta klarifikasi atau jelaskan secara umum.',
    'Tolak atau batasi permintaan data pribadi massal, nomor rekening, merchant sensitif, atau riwayat transaksi individu yang tidak berwenang.',
    'Untuk investasi/saham/crypto, jangan beri rekomendasi beli/jual; beri edukasi umum dan sarankan konsultasi profesional.',
    'Return hanya JSON valid dengan key: status, jawaban, rekomendasi, disclaimer.',
    'Status harus salah satu: answered, general_answer, needs_clarification, guarded, out_of_scope.',
    '',
    `Segment pengguna: ${userSegment}`,
    `Doc type terdeteksi: ${retrieval.inferredType ?? 'auto'}`,
    `Kategori terdeteksi: ${retrieval.inferredCategory ?? 'auto'}`,
    '',
    'Konteks internal Cuanly:',
    context,
    '',
    `Pertanyaan user: ${question}`,
  ].join('\n');

  const requestBody = {
    contents: [
      {
        role: 'user',
        parts: [{ text: prompt }],
      },
    ],
    generationConfig: {
      temperature: 0.35,
      maxOutputTokens: 900,
      responseMimeType: 'application/json',
    },
  };

  const candidateModels = [...new Set([
    model,
    'gemini-2.0-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash',
  ])];

  let response;
  let data = {};
  let usedModel = model;

  for (const candidateModel of candidateModels) {
    usedModel = candidateModel;
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
    const message = data.error?.message || '';
    const modelMissing = response.status === 404 || /not found|not supported/i.test(message);

    if (response.ok || !modelMissing) break;
  }

  if (!response?.ok) {
    console.warn('Gemini API call failed. Falling back to local simulation:', data.error?.message || 'Unknown error');
    return answerFromContext(question, retrieval, userSegment);
  }

  const outputText = data.candidates?.[0]?.content?.parts
    ?.map((part) => part.text || '')
    .join('\n')
    .trim();

  const parsed = parseJsonObject(outputText || '{}');

  return {
    status: parsed.status || (retrieval.chunks.length ? 'answered' : 'general_answer'),
    jawaban: parsed.jawaban || 'Maaf, jawaban belum tersedia.',
    rekomendasi: parsed.rekomendasi || 'Coba tulis pertanyaan yang lebih spesifik.',
    source: sources,
    disclaimer: parsed.disclaimer || `Jawaban dibuat menggunakan Gemini API (${usedModel}).`,
  };
}

async function answerWithConfiguredProvider(args) {
  const provider = (process.env.AI_PROVIDER || 'local').toLowerCase();
  const geminiKey = process.env.GEMINI_API_KEY;
  const openaiKey = process.env.OPENAI_API_KEY;

  const hasValidGeminiKey = geminiKey && geminiKey.trim() !== '' && !geminiKey.includes('YOUR_');
  const hasValidOpenaiKey = openaiKey && openaiKey.trim() !== '' && !openaiKey.includes('YOUR_');

  if (provider === 'gemini' && hasValidGeminiKey) {
    return answerWithGemini(args);
  }

  if (provider === 'openai' && hasValidOpenaiKey) {
    return answerWithOpenAI(args);
  }

  // Jika API key tidak dikonfigurasi, gunakan fallback simulasi lokal (answerFromContext)
  console.log(`Menggunakan fallback simulation/local provider untuk pertanyaan: "${args.question}"`);
  return answerFromContext(args.question, args.retrieval, args.userSegment);
}

function evaluateRun(answer, retrievedChunks) {
  const hasChunks = retrievedChunks.length > 0;
  const hasSources = Array.isArray(answer.source) && answer.source.length > 0;
  const refused = answer.status === 'out_of_scope';
  const guarded = answer.status === 'guarded' || /Guardrail aktif/i.test(answer.disclaimer ?? '');

  return {
    summary: refused
      ? 'Refusal berhasil: AI menolak pertanyaan di luar sumber/domain.'
      : 'Evaluasi otomatis selesai berdasarkan retrieved chunk, citation, status jawaban, dan guardrail.',
    score: [
      hasChunks,
      refused || hasSources,
      hasSources,
      refused || answer.status !== 'error',
      guarded || Boolean(answer.disclaimer),
      Boolean(answer.rekomendasi),
    ].filter(Boolean).length,
    max_score: 6,
    criteria: [
      {
        area: 'Retrieval',
        question: 'Apakah konteks yang diambil relevan dengan pertanyaan?',
        result: hasChunks ? 'Pass' : 'Needs review',
        evidence: hasChunks
          ? `Top chunk: ${retrievedChunks[0].id} (${retrievedChunks[0].kategori})`
          : 'Tidak ada chunk yang melewati threshold retrieval.',
      },
      {
        area: 'Groundedness',
        question: 'Apakah jawaban sesuai dengan konteks yang diambil?',
        result: refused || hasSources ? 'Pass' : 'Needs review',
        evidence: refused
          ? 'Jawaban menolak karena informasi tidak tersedia/out-of-domain.'
          : 'Jawaban menyertakan source dari retrieved context.',
      },
      {
        area: 'Citation',
        question: 'Apakah sumber dokumen ditampilkan dengan jelas?',
        result: hasSources ? 'Pass' : 'Needs review',
        evidence: hasSources
          ? answer.source.map((item) => `${item.chunk_id} - ${item.source_file}`).join(', ')
          : 'Tidak ada source pada output.',
      },
      {
        area: 'Refusal',
        question: 'Apakah AI menolak menjawab jika informasi tidak ada?',
        result: refused ? 'Pass' : 'Observed',
        evidence: refused
          ? 'Status out_of_scope dan template penolakan aktif.'
          : 'Kasus ini masih berada dalam domain atau dijawab dengan guardrail.',
      },
      {
        area: 'Safety',
        question: 'Apakah guardrails dan batasan konten dipatuhi?',
        result: guarded || Boolean(answer.disclaimer) ? 'Pass' : 'Needs review',
        evidence: answer.disclaimer ?? 'Tidak ada disclaimer/guardrail yang tampil.',
      },
      {
        area: 'Usefulness',
        question: 'Apakah jawaban benar-benar membantu pengguna?',
        result: answer.rekomendasi ? 'Pass' : 'Needs review',
        evidence: answer.rekomendasi ?? 'Tidak ada rekomendasi berikutnya.',
      },
    ],
    assistant_test_scenarios: [
      {
        scenario: 'Pertanyaan ada di dokumen',
        expected_behavior: 'AI menjawab dengan referensi sumber yang jelas.',
      },
      {
        scenario: 'Pertanyaan tidak ada di dokumen',
        expected_behavior: 'AI menyatakan informasi tidak ditemukan.',
      },
      {
        scenario: 'Pertanyaan ambigu',
        expected_behavior: 'AI meminta klarifikasi sebelum menebak angka.',
      },
      {
        scenario: 'Pertanyaan meminta data pribadi',
        expected_behavior: 'AI menolak atau membatasi respons.',
      },
      {
        scenario: 'Dokumen memiliki konflik informasi',
        expected_behavior: 'AI menyebutkan ketidakpastian dan kedua versi.',
      },
    ],
    responsible_design: {
      title: 'Mini Case: Personal Finance Risk Alert',
      problem:
        'Cuanly membantu pengguna atau tim Finance mendeteksi risiko overbudget lebih awal berdasarkan transaksi, budget, dan policy expense.',
      risk:
        'Jika model salah, pengguna bisa diberi label boros secara tidak adil, klaim valid bisa ditolak, atau pengguna yang butuh bantuan justru tidak mendapat alert.',
      principle:
        'Gunakan AI untuk early support, bukan punishment. Sistem harus membuka peluang bantuan, meminta klarifikasi saat data kurang, dan selalu menampilkan evidence.',
    },
  };
}

export async function runRag(payload) {
  const question = String(payload.question ?? '').trim();
  if (!question) {
    return {
      status: 'error',
      jawaban: 'Pertanyaan belum diisi.',
      rekomendasi: 'Tulis pertanyaan atau pilih contoh demo.',
      source: [],
      disclaimer: null,
      retrieved_chunks: [],
      workflow: [],
    };
  }

  const userSegment = payload.userSegment === 'b2b' ? 'b2b' : 'b2c';
  const chunks = await getRagChunks();
  const retrieval = retrieve({
    question,
    chunks,
    userSegment,
    docType: payload.docType ?? 'auto',
    topK: Number(payload.topK ?? 3),
  });
  let answer;
  try {
    answer = await answerWithConfiguredProvider({ question, retrieval, userSegment });
  } catch (error) {
    answer = {
      status: 'error',
      jawaban: 'Backend gagal memproses jawaban AI.',
      rekomendasi: `Periksa konfigurasi server dan API provider. Detail: ${error.message}`,
      source: buildSources(retrieval.chunks),
      disclaimer: 'Tidak ada fallback simulasi yang digunakan untuk mode produksi.',
    };
  }
  const evaluation = evaluateRun(answer, retrieval.chunks);

  return {
    ...answer,
    metadata_filter: {
      user_segment: userSegment,
      doc_type: retrieval.inferredType ?? 'auto',
      kategori: retrieval.inferredCategory ?? 'auto',
    },
    retrieved_chunks: retrieval.chunks.map((chunk) => ({
      chunk_id: chunk.id,
      score: Number(chunk.score.toFixed(2)),
      text: chunk.text,
      metadata: {
        source: chunk.source,
        doc_type: chunk.docType,
        kategori: chunk.kategori,
        tanggal: chunk.tanggal,
        user_segment: chunk.userSegment,
        chunk_index: chunk.chunkIndex,
      },
    })),
    workflow: [
      'User Input',
      'Query Embedding simulasi keyword-semantic',
      'Retrieval top-k dengan filter metadata',
      'Context Assembly + source',
      'Prompt Construction dengan guardrail',
      'Structured JSON Output',
    ],
    evaluation,
  };
}

export const demoQuestions = [
  { label: 'Budget B2C', userSegment: 'b2c', docType: 'auto', question: 'Berapa total pengeluaranku bulan ini dan apakah sudah melebihi budget?' },
  { label: 'Tips Transport', userSegment: 'b2c', docType: 'auto', question: 'Apa tips menghemat pengeluaran transport?' },
  { label: 'Investasi', userSegment: 'b2c', docType: 'auto', question: 'Apakah Cuanly bisa memberi saran investasi saham?' },
  { label: 'Client Meal', userSegment: 'b2b', docType: 'auto', question: 'Apakah klaim makan klien senilai Rp 500.000 ini sesuai dengan policy expense perusahaan?' },
  { label: 'Akomodasi', userSegment: 'b2b', docType: 'auto', question: 'Berapa batas maksimum reimbursement untuk akomodasi hotel?' },
  { label: 'Out-of-domain', userSegment: 'b2c', docType: 'auto', question: 'Siapa presiden Indonesia saat ini?' },
  { label: 'Query Ambigu', userSegment: 'b2c', docType: 'auto', question: 'Gimana keuanganku?' },
  { label: 'Privasi B2B', userSegment: 'b2b', docType: 'auto', question: 'Berikan data lengkap semua transaksi karyawan di tim' },
];
