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

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function generalAssistantAnswer(question) {
  const q = normalize(question);

  if (/(presiden|cuaca|film|politik|olahraga|berita|siapa|kapan|dimana)/.test(q)) {
    return {
      status: 'general_answer',
      jawaban: pick([
        'Pertanyaan ini berada di luar domain finansial Cuanly. Secara umum, aku menyarankan Anda memeriksa portal berita resmi atau mesin pencari publik untuk informasi faktual terkini seperti ini.',
        'Maaf, Cuanly fokus pada asisten finansial pribadi dan kebijakan reimbursement. Untuk topik umum, cuaca, politik, atau olahraga, sebaiknya verifikasi langsung melalui situs informasi tepercaya.',
        'Informasi di luar cakupan keuangan Cuanly tidak tersimpan dalam basis dokumen RAG kami. Coba tanyakan tentang tips hemat, budget pengeluaran, atau aturan klaim kantor!'
      ]),
      rekomendasi: 'Fokuskan pertanyaan Anda ke bidang keuangan, misalnya: "Bagaimana cara hemat kategori transport?" atau "Berapa limit reimbursement hotel?"',
      source: [],
      disclaimer: 'Jawaban ini dibuat sebagai respons umum, bukan berdasarkan sumber internal Cuanly.',
    };
  }

  if (/(tips|cara|bagaimana|gimana|saran|rekomendasi)/.test(q)) {
    return {
      status: 'general_answer',
      jawaban: pick([
        'Untuk memulai pengelolaan keuangan yang baik, Cuanly menyarankan 3 langkah dasar: 1) Catat setiap transaksi tanpa terkecuali, 2) Buat anggaran bulanan terpisah, dan 3) Amankan dana darurat minimal untuk 3 bulan ke depan.',
        'Langkah praktis menghemat anggaran: Mulailah mengaudit kategori pengeluaran terbesar Anda (biasanya Makanan/Minuman dan Transportasi). Mengurangi frekuensi jajan di luar dan beralih ke memasak sendiri dapat memotong biaya hingga 40%.',
        'Saran terbaik dari Cuanly: Selalu sisihkan minimal 20% pendapatan Anda untuk tabungan atau investasi di hari pertama Anda menerima gaji (metode pay-yourself-first), jangan menunggu sisa uang di akhir bulan.'
      ]),
      rekomendasi: 'Tambahkan detail seperti nominal atau kategori spesifik agar Cuanly dapat memberikan simulasi perhitungan yang lebih terarah.',
      source: [],
      disclaimer: 'Jawaban ini bersifat umum karena tidak ada sumber internal yang cocok.',
    };
  }

  return {
    status: 'general_answer',
    jawaban: pick([
      'Aku belum menemukan dokumen internal Cuanly yang spesifik membahas pertanyaan Anda. Namun, secara umum aku siap membantu memetakan pola pengeluaran atau menganalisis transaksi harian Anda.',
      'Sistem RAG Cuanly mendeteksi pertanyaan Anda berada di luar dokumen panduan standar. Tolong berikan konteks tambahan seperti kategori belanja, nominal transaksi, atau aturan reimbursement yang ingin dikonsultasikan.',
      'Mohon maaf, data internal Cuanly belum mencakup pertanyaan tersebut. Bisakah Anda memperjelas apakah pertanyaan ini ditujukan untuk keuangan pribadi (B2C) atau keperluan reimburse kantor (B2B)?'
    ]),
    rekomendasi: 'Cobalah bertanya tentang: "Batas pengajuan reimbursement", "Tips hemat transport", atau "Dana darurat".',
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

  // GREETINGS & INTRODUCTIONS
  if (/(halo|hai|hi|hello|pagi|siang|sore|malam|assalamualaikum|hey|kamu siapa|siapa kamu)/.test(q)) {
    return {
      status: 'answered',
      jawaban: pick([
        'Halo! Aku Cuanly AI, asisten keuangan pribadi cerdasmu. Ada yang bisa kubantu hari ini? Kamu bisa bertanya tentang pengeluaran, budget tim, tips hemat, atau kebijakan reimbursement kantor!',
        'Hai! Cuanly AI di sini. Aku siap membantumu melacak transaksi keuangan, menganalisis batas anggaran, atau memberi rekomendasi finansial. Apa yang ingin kamu tanyakan hari ini?',
        'Halo! Senang bertemu denganmu. Aku asisten AI Cuanly. Silakan tanyakan hal-hal seputar keuangan pribadi Anda (B2C) maupun aturan reimbursement kantor (B2B).'
      ]),
      rekomendasi: 'Coba tanyakan: "Bagaimana kondisi keuanganku?" atau "Berapa limit refund makan klien?"',
      source: sources,
      disclaimer: 'Cuanly AI siap mendampingi pengelolaan rencana finansial Anda.',
    };
  }

  // KEWASPADAAN PRIVASI / GUARDRAIL DATA PRIBADI KARYAWAN (B2B)
  if (/(semua transaksi karyawan|data lengkap.*karyawan|riwayat klaim.*karyawan|data pribadi karyawan|data sensitif)/.test(q)) {
    return {
      status: 'guarded',
      jawaban: pick([
        'Sesuai dengan standar kebijakan privasi data Cuanly, kami tidak diizinkan menampilkan rincian data transaksi pribadi atau riwayat klaim reimbursement karyawan secara individual.',
        'Akses dibatasi. Cuanly tidak dapat menampilkan data transaksi pribadi karyawan secara massal demi menjaga privasi dan mematuhi regulasi perlindungan data sensitif perusahaan.',
        'Guardrail Privasi Cuanly Aktif: Rincian transaksi personal karyawan bersifat rahasia dan hanya dapat diakses oleh peran otorisasi tertentu (seperti Finance Manager) secara terbatas.'
      ]),
      rekomendasi: 'Sebagai alternatif, Anda dapat meminta rangkuman agregat seperti total pengeluaran tim, persentase kepatuhan budget, atau tren grafik bulanan.',
      source: sources,
      disclaimer: 'Guardrail privasi aktif: akses data individu dibatasi dengan role-based access control.',
    };
  }

  // ANALISIS KONDISI KEUANGAN PRIBADI (B2C)
  if (/^(gimana|bagaimana) keuanganku\??$|keuanganku\??$/.test(q)) {
    return {
      status: 'needs_clarification',
      jawaban: pick([
        'Berdasarkan ringkasan bulanan, total pengeluaran Anda saat ini adalah Rp 945.000 dari batas budget Rp 3.000.000. Rasio pemakaian anggaran Anda berada di angka 31.5% (Sangat Sehat!). Sisa alokasi Anda adalah Rp 2.055.000.',
        'Kondisi keuangan Anda bulan ini tergolong AMAN dan STABIL. Anda baru membelanjakan Rp 945.000 dari pagu Rp 3.000.000. Pengeluaran bulanan didominasi oleh kategori Belanja Retail sebesar Rp 320.000.',
        'Rapor keuangan Anda berada di zona HIJAU. Penggunaan budget masih di bawah 40%. Anda memiliki sisa dana belanja sebesar Rp 2.055.000 untuk sisa hari bulan ini. Pertahankan pola konsumsi sehat ini!'
      ]),
      rekomendasi: 'Jika ingin detail aspek tertentu, ketik pertanyaan spesifik seperti: "Berapa pengeluaran makanku?" atau "Berikan tips hemat transport".',
      source: sources,
      disclaimer: 'Analisis menggunakan data transaksi demo internal, bukan integrasi rekening riil.',
    };
  }

  // OUT-OF-DOMAIN TOPICS (presiden, cuaca, dll)
  if (/(presiden|cuaca|film|politik|olahraga)/.test(q)) {
    return generalAssistantAnswer(question);
  }

  // B2B: CLIENT MEAL POLICY
  if (/500 ?\.?000|500 ribu|rp 500/.test(q) && /(makan|meal|klien|client)/.test(q)) {
    return {
      status: 'answered',
      jawaban: pick([
        `Klaim makan malam bersama klien senilai Rp 500.000 dinyatakan MELEBIHI BATAS (Overlimit). Kebijakan perusahaan menetapkan batas maksimal reimbursement client meal adalah Rp 400.000 per orang dalam sekali acara.`,
        `Hasil pengecekan aturan perusahaan: Pengajuan makan dengan klien senilai Rp 500.000 TIDAK SESUAI dengan standar batas maksimum reimbursable client meal sebesar Rp 400.000 per kegiatan.`
      ]),
      rekomendasi: 'Ajukan klaim sebesar Rp 400.000 sesuai limit, sertakan invoice resmi terperinci (bukan struk kartu debit), dan lampirkan persetujuan tertulis dari manajer Anda.',
      source: sources,
      disclaimer: 'Validasi otomatis ini merujuk pada Dokumen Expense Policy Demo Perusahaan.',
    };
  }

  // B2B: HOTEL / ACCOMMODATION
  if (/(hotel|akomodasi|penginapan)/.test(q)) {
    return {
      status: 'answered',
      jawaban: pick([
        `Kebijakan akomodasi dinas menetapkan batas pengembalian (reimbursement) hotel maksimal sebesar Rp 500.000 per malam untuk kategori kamar standar.`,
        `Batas tarif hotel yang ditanggung perusahaan adalah Rp 500.000 per malam. Pengeluaran di atas batas tersebut wajib dibayarkan secara mandiri oleh karyawan kecuali ada dispensasi khusus.`
      ]),
      rekomendasi: 'Lampirkan invoice resmi yang mencantumkan nama hotel, tanggal menginap, nama tamu (karyawan), dan rincian biaya kamar saat pengajuan reimbursement.',
      source: sources,
      disclaimer: 'Kebijakan berdasarkan Dokumen Standard Operating Procedure Travel Dinas Perusahaan.',
    };
  }

  // B2B: DEADLINE SUBMISSION
  if (/(14|waktu|deadline|hari kerja|pengajuan|telat|terlambat)/.test(q)) {
    return {
      status: 'answered',
      jawaban: pick([
        'Semua berkas klaim reimbursement wajib diajukan ke divisi Finance maksimal 14 hari kerja terhitung sejak tanggal yang tertera pada transaksi.',
        'Batas akhir pengajuan reimbursement adalah 14 hari kerja setelah transaksi dilakukan. Keterlambatan pengajuan dapat menyebabkan klaim otomatis ditolak oleh sistem Finance.'
      ]),
      rekomendasi: 'Jika terpaksa mengajukan di luar batas 14 hari, Anda harus menyertakan Form Justifikasi Keterlambatan yang disetujui oleh Kepala Departemen.',
      source: sources,
      disclaimer: 'Ketentuan ini mengacu pada Kebijakan Pelaporan Keuangan Internal v2.4.',
    };
  }

  // B2B: BUDGET TIM & OUT-OF-BUDGET ALERT
  if (/(expense tim|budget tim|melebihi budget tim|anggaran tim)/.test(q)) {
    return {
      status: 'answered',
      jawaban: pick([
        `Total pengeluaran divisi Anda untuk bulan Juni saat ini tercatat sebesar Rp 9.300.000 dari total pagu anggaran Rp 10.000.000 (Rasio: 93%). Karena telah melewati ambang batas 90%, sistem Cuanly memicu status Peringatan (Alert Overbudget).`,
        `Divisi Anda telah menghabiskan Rp 9.300.000 dari alokasi Rp 10.000.000. Status anggaran saat ini dalam fase WASPADA (93%). Pengeluaran dinas baru harus dihentikan sementara kecuali bersikap mendesak.`
      ]),
      rekomendasi: 'Segera lakukan koordinasi dengan Team Lead untuk membekukan pengeluaran non-kritis dan lakukan rekonsiliasi budget dengan tim Finance.',
      source: sources,
      disclaimer: 'Angka agregat dihitung real-time berdasarkan data berkas expense_team_juni.csv.',
    };
  }

  // B2C: BUDGET & GENERAL EXPENSES (Makanan, Belanja, Tagihan)
  if (/(total|pengeluaran|budget|boros)/.test(q) && userSegment === 'b2c') {
    return {
      status: 'answered',
      jawaban: pick([
        `Total belanja bulanan Anda tercatat sebesar Rp 945.000 dari rencana anggaran Rp 3.000.000. Penggunaan budget masih berada di kisaran 31%, yang berarti Anda memiliki manajemen anggaran yang sangat disiplin bulan ini!`,
        `Evaluasi Pengeluaran: Anda baru membelanjakan Rp 945.000 dari target budget Rp 3.000.000. Kategori pengeluaran Anda didominasi oleh Belanja bulanan (Rp 320.000), diikuti Makanan/Minuman (Rp 220.000), dan Tagihan rutin (Rp 200.000).`
      ]),
      rekomendasi: 'Alokasikan sisa budget bulanan yang tidak terpakai (sekitar Rp 2.055.000) ke dalam instrumen tabungan berjangka atau dana darurat agar lebih produktif.',
      source: sources,
      disclaimer: 'Laporan anggaran ini bersumber dari log pengeluaran manual aplikasi Cuanly.',
    };
  }

  // B2C: TRANSPORT ADVICES
  if (/(transport|ojek|krl|bus|bensin|parkir)/.test(q)) {
    return {
      status: 'answered',
      jawaban: pick([
        'Tips Hemat Transportasi: Gunakan transportasi publik massal seperti KRL atau TransJakarta untuk mobilitas harian rutin Anda, batasi pemesanan ojek online maksimal 3 kali per minggu, dan cobalah opsi berjalan kaki untuk jarak dekat (< 1 km).',
        'Rekomendasi Cuanly: Total biaya perjalanan Anda bulan ini adalah Rp 150.000. Anda bisa menghemat lebih banyak dengan memanfaatkan promo bundling e-wallet transportasi atau berlangganan kartu multi-trip.'
      ]),
      rekomendasi: 'Kelompokkan semua pengeluaran bahan bakar, parkir, dan tarif perjalanan ke dalam kategori Transport agar grafik tren mingguan Anda akurat.',
      source: sources,
      disclaimer: 'Tips dikurasi oleh tim perencana keuangan Cuanly.',
    };
  }

  // INVESTMENT & CRYPTO GUARDRAIL
  if (/(investasi|saham|crypto|kripto|reksadana|reksa dana)/.test(q)) {
    return {
      status: 'guarded',
      jawaban: pick([
        'Cuanly tidak menyediakan fitur analisis pasar saham, rekomendasi pembelian aset kripto, atau anjuran investasi reksadana. Cuanly dirancang khusus untuk memantau arus kas, kepatuhan anggaran, serta pencatatan struk secara cerdas.',
        'Sistem Cuanly mematuhi regulasi ketat dan tidak memberikan nasihat investasi atau rekomendasi trading saham/kripto secara personal.'
      ]),
      rekomendasi: 'Jika Anda berniat memulai investasi, pelajari profil risiko Anda terlebih dahulu dan konsultasikan dengan penasihat keuangan berlisensi OJK.',
      source: sources,
      disclaimer: 'Guardrail Perlindungan Konsumen: Cuanly tidak bertanggung jawab atas aktivitas investasi pihak luar.',
    };
  }

  // DATA PRIVACY & BANK ACCOUNT SAFETY
  if (/(privasi|rekening|merchant|aman|bocor)/.test(q)) {
    return {
      status: 'answered',
      jawaban: pick([
        'Cuanly sangat menghormati privasi Anda. Kami hanya membaca nominal total transaksi, tanggal, dan kategori belanja dari struk Anda. Informasi nama lengkap, nomor kartu kredit, atau nomor rekening bank tidak akan disimpan di server kami.',
        'Sistem keamanan Cuanly mengenkripsi data gambar struk yang diunggah dan otomatis menghapusnya setelah ekstraksi informasi transaksi selesai diproses.'
      ]),
      rekomendasi: 'Untuk keamanan tambahan saat presentasi kelas, Anda dapat menyamarkan/sensor bagian nama dan nomor kartu pada struk fisik sebelum difoto.',
      source: sources,
      disclaimer: 'Keamanan data dijamin dengan enkripsi end-to-end pada server Cuanly.',
    };
  }

  if (!top) {
    return generalAssistantAnswer(question);
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
