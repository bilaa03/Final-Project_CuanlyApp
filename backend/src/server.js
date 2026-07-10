import 'dotenv/config';
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { runRag, demoQuestions } from './ragEngine.js';
import { closePrisma, getPrisma, getRagChunks, isPrismaConfigured, getUsers, createUser, getWallets, createWallet, getTransactions, createTransaction, transferWalletBalance } from './db.js';
import { extractReceiptData } from './ocrService.js';

const port = Number(process.env.PORT ?? 8787);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PUBLIC_DIR = path.join(__dirname, '..', 'public');

const app = express();

app.use(express.json({ limit: '10mb' }));
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.json({ ok: true });
  next();
});
app.use(express.static(PUBLIC_DIR));

app.get('/health', async (req, res, next) => {
  try {
    res.json({
      ok: true,
      app: 'Cuanly RAG API',
      framework: 'express',
      database: isPrismaConfigured() ? 'prisma' : 'local-json-fallback',
    });
  } catch (error) {
    next(error);
  }
});

app.get('/chunks', async (req, res, next) => {
  try {
    const chunks = await getRagChunks();
    res.json({ count: chunks.length, chunks });
  } catch (error) {
    next(error);
  }
});

app.get('/demo-questions', (req, res) => {
  res.json({ questions: demoQuestions });
});

app.post('/auth/register', async (req, res, next) => {
  try {
    const { name, email, password } = req.body ?? {};
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Nama, email, dan password wajib diisi.' });
    }
    const users = await getUsers();
    if (users.some((u) => u.email === email)) {
      return res.status(400).json({ error: 'Email sudah terdaftar.' });
    }
    const newUser = await createUser(name, email, password);
    res.json({ ok: true, user: { name: newUser.name, email: newUser.email } });
  } catch (error) {
    next(error);
  }
});

app.post('/auth/login', async (req, res, next) => {
  try {
    const { email, password } = req.body ?? {};
    if (!email || !password) {
      return res.status(400).json({ error: 'Email dan password wajib diisi.' });
    }
    const users = await getUsers();
    const user = users.find((u) => u.email === email && u.password === password);
    if (!user) {
      return res.status(401).json({ error: 'Email atau password tidak sesuai.' });
    }
    res.json({ ok: true, user: { name: user.name, email: user.email } });
  } catch (error) {
    next(error);
  }
});

app.get('/financial/data', async (req, res, next) => {
  try {
    const { email } = req.query ?? {};
    if (!email) {
      return res.status(400).json({ error: 'Email parameter is required' });
    }
    const wallets = await getWallets(email);
    const transactions = await getTransactions(email);
    res.json({ wallets, transactions });
  } catch (error) {
    next(error);
  }
});

app.post('/financial/wallet', async (req, res, next) => {
  try {
    const { email, name, balance, cardNumber, designType } = req.body ?? {};
    if (!email || !name || balance === undefined || !cardNumber || !designType) {
      return res.status(400).json({ error: 'All wallet fields are required' });
    }
    const wallet = await createWallet(email, name, Number(balance), cardNumber, designType);
    res.json({ ok: true, wallet });
  } catch (error) {
    next(error);
  }
});

app.post('/financial/transaction', async (req, res, next) => {
  try {
    const { email, id, title, category, date, amount, isExpense, walletName } = req.body ?? {};
    if (!email || !id || !title || !category || !date || amount === undefined || isExpense === undefined || !walletName) {
      return res.status(400).json({ error: 'All transaction fields are required' });
    }
    const tx = await createTransaction(email, id, title, category, date, Number(amount), Boolean(isExpense), walletName);
    res.json({ ok: true, transaction: tx });
  } catch (error) {
    next(error);
  }
});

app.post('/financial/transfer', async (req, res, next) => {
  try {
    const { email, fromWallet, toWallet, amount } = req.body ?? {};
    if (!email || !fromWallet || !toWallet || !amount) {
      return res.status(400).json({ error: 'All transfer fields are required' });
    }
    const result = await transferWalletBalance(email, fromWallet, toWallet, Number(amount));
    res.json({ ok: true, result });
  } catch (error) {
    next(error);
  }
});

app.post('/financial/ocr', async (req, res, next) => {
  try {
    const { image, mimeType } = req.body ?? {};
    if (!image) {
      return res.status(400).json({ error: 'Image parameter is required' });
    }
    const result = await extractReceiptData(image, mimeType);
    res.json({ ok: true, data: result });
  } catch (error) {
    next(error);
  }
});

app.get('/financial/ocr/key', (req, res) => {
  res.json({
    ok: true,
    apiKey: process.env.GEMINI_API_KEY || '',
  });
});

app.post('/rag/query', async (req, res, next) => {
  try {
    res.json(await runRag(req.body ?? {}));
  } catch (error) {
    next(error);
  }
});

app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    paths: ['/health', '/chunks', '/demo-questions', '/rag/query'],
  });
});

app.use((error, req, res, next) => {
  res.status(500).json({ error: error.message });
});

if (isPrismaConfigured()) {
  await getPrisma();
}

const server = app.listen(port, () => {
  console.log(`Cuanly API running on http://localhost:${port}`);
});

process.on('SIGINT', async () => {
  await closePrisma();
  server.close(() => process.exit(0));
});

