import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const chunks = JSON.parse(
  await fs.readFile(path.join(__dirname, '..', 'data', 'chunks.json'), 'utf8')
);

const stopwords = new Set([
  'apa', 'apakah', 'bagaimana', 'berapa', 'yang', 'dan', 'atau', 'ini', 'itu',
  'saya', 'kamu', 'dengan', 'untuk', 'dari', 'ke', 'di', 'bulan', 'bisa',
  'ada', 'dalam', 'secara', 'mohon', 'tolong', 'fin', 'sight', 'finsight'
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

function retrieve({ question, userSegment = 'b2c', docType = null, topK = 3 }) {
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

function answerFromContext(question, retrieval, userSegment) {
  const q = normalize(question);
  const top = retrieval.chunks[0];
  const sources = retrieval.chunks.map((chunk) => ({
    chunk_id: chunk.id,
    source_file: chunk.source,
    kategori: chunk.kategori,
    score: Number(chunk.score.toFixed(2)),
  }));

  if (!top) {
    return {
      status: 'out_of_scope',
      jawaban: 'Informasi tidak tersedia di dokumen FinSight AI yang ter-retrieve. Silakan pilih segmen B2C/B2B yang sesuai atau tambahkan data transaksi/policy yang relevan.',
      rekomendasi: 'Gunakan pertanyaan seputar budget, transaksi, penghematan, privasi, atau policy reimbursement.',
      source: [],
      disclaimer: 'FinSight AI hanya menjawab berdasarkan sumber data yang tersedia dan tidak menebak angka.',
    };
  }

  if (/(presiden|cuaca|film|politik|olahraga)/.test(q)) {
    return {
      status: 'out_of_scope',
      jawaban: 'Pertanyaan tersebut berada di luar domain FinSight AI. Sistem ini hanya membantu analisis pengeluaran, budget, FAQ keuangan pribadi, dan policy expense perusahaan.',
      rekomendasi: 'Ajukan pertanyaan yang terkait transaksi, budget, reimbursement, atau privasi data keuangan.',
      source: sources,
      disclaimer: 'Guardrail aktif: FinSight AI menolak menjawab topik di luar dokumen sumber.',
    };
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
      disclaimer: 'FinSight AI hanya merangkum policy yang tersedia.',
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
      disclaimer: 'Saran ini bersifat edukatif dan berbasis FAQ FinSight AI.',
    };
  }

  if (/(investasi|saham|crypto|kripto)/.test(q)) {
    return {
      status: 'guarded',
      jawaban: 'FinSight AI tidak memberikan saran investasi, saham, crypto, atau produk keuangan. FinSight AI hanya menganalisis pola pengeluaran dan rekomendasi penghematan berbasis data transaksi.',
      rekomendasi: 'Untuk keputusan investasi, konsultasikan dengan penasihat keuangan profesional.',
      source: sources,
      disclaimer: 'Guardrail aktif: tidak ada rekomendasi investasi.',
    };
  }

  if (/(privasi|rekening|merchant)/.test(q)) {
    return {
      status: 'answered',
      jawaban: 'FinSight AI menjaga privasi dengan hanya memakai kategori dan jumlah transaksi untuk analisis, bukan nama merchant, nama lengkap, atau nomor rekening.',
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
    disclaimer: 'FinSight AI bukan penasihat keuangan/legal profesional.',
  };
}

export function runRag(payload) {
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
  const retrieval = retrieve({
    question,
    userSegment,
    docType: payload.docType ?? 'auto',
    topK: Number(payload.topK ?? 3),
  });
  const answer = answerFromContext(question, retrieval, userSegment);

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
  };
}

export const demoQuestions = [
  { label: 'Budget B2C', userSegment: 'b2c', docType: 'auto', question: 'Berapa total pengeluaranku bulan ini dan apakah sudah melebihi budget?' },
  { label: 'Tips Transport', userSegment: 'b2c', docType: 'auto', question: 'Apa tips menghemat pengeluaran transport?' },
  { label: 'Investasi', userSegment: 'b2c', docType: 'auto', question: 'Apakah FinSight AI bisa memberi saran investasi saham?' },
  { label: 'Client Meal', userSegment: 'b2b', docType: 'auto', question: 'Apakah klaim makan klien senilai Rp 500.000 ini sesuai dengan policy expense perusahaan?' },
  { label: 'Akomodasi', userSegment: 'b2b', docType: 'auto', question: 'Berapa batas maksimum reimbursement untuk akomodasi hotel?' },
  { label: 'Out-of-domain', userSegment: 'b2c', docType: 'auto', question: 'Siapa presiden Indonesia saat ini?' },
];

export { chunks };
