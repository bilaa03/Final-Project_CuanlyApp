import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const localChunksPath = path.join(__dirname, '..', 'data', 'chunks.json');
const localUsersPath = path.join(__dirname, '..', 'data', 'users.json');
const localWalletsPath = path.join(__dirname, '..', 'data', 'wallets.json');
const localTransactionsPath = path.join(__dirname, '..', 'data', 'transactions.json');

let prisma;
let localChunksCache;
let localUsersCache;
let localWalletsCache;
let localTransactionsCache;

export function isPrismaConfigured() {
  return Boolean(process.env.DATABASE_URL);
}

export async function getPrisma() {
  if (!isPrismaConfigured()) return null;
  if (prisma) return prisma;

  const { PrismaClient } = await import('@prisma/client');
  prisma = new PrismaClient();
  return prisma;
}

export async function closePrisma() {
  if (!prisma) return;
  await prisma.$disconnect();
  prisma = null;
}

async function readLocalChunks() {
  if (!localChunksCache) {
    localChunksCache = JSON.parse(await fs.readFile(localChunksPath, 'utf8'));
  }
  return localChunksCache;
}

export async function getRagChunks() {
  const client = await getPrisma();
  if (!client) return readLocalChunks();

  try {
    const chunks = await client.ragChunk.findMany({
      orderBy: [
        { userSegment: 'asc' },
        { docType: 'asc' },
        { chunkIndex: 'asc' },
      ],
    });
    return chunks.length ? chunks : readLocalChunks();
  } catch (error) {
    console.warn('Gagal memuat chunks dari database, menggunakan fallback JSON lokal:', error.message);
    return readLocalChunks();
  }
}

export async function seedRagChunks(chunks) {
  const client = await getPrisma();
  if (!client) throw new Error('DATABASE_URL belum dikonfigurasi.');

  for (const chunk of chunks) {
    await client.ragChunk.upsert({
      where: { id: chunk.id },
      update: {
        text: chunk.text,
        source: chunk.source,
        docType: chunk.docType,
        kategori: chunk.kategori,
        tanggal: chunk.tanggal,
        userSegment: chunk.userSegment,
        chunkIndex: chunk.chunkIndex,
      },
      create: {
        id: chunk.id,
        text: chunk.text,
        source: chunk.source,
        docType: chunk.docType,
        kategori: chunk.kategori,
        tanggal: chunk.tanggal,
        userSegment: chunk.userSegment,
        chunkIndex: chunk.chunkIndex,
      },
    });
  }

  const demoQuestions = [
    {
      label: 'Budget B2C',
      userSegment: 'b2c',
      docType: 'auto',
      question: 'Berapa total pengeluaranku bulan ini dan apakah sudah melebihi budget?',
    },
    {
      label: 'Tips Transport',
      userSegment: 'b2c',
      docType: 'auto',
      question: 'Apa tips menghemat pengeluaran transport?',
    },
    {
      label: 'Client Meal',
      userSegment: 'b2b',
      docType: 'auto',
      question: 'Apakah klaim makan klien senilai Rp 500.000 ini sesuai dengan policy expense perusahaan?',
    },
  ];

  for (const demoQuestion of demoQuestions) {
    const existing = await client.demoQuestion.findFirst({
      where: {
        label: demoQuestion.label,
        userSegment: demoQuestion.userSegment,
      },
    });

    if (!existing) {
      await client.demoQuestion.create({ data: demoQuestion });
    }
  }

  return {
    upserted: chunks.length,
    demoQuestions: demoQuestions.length,
  };
}

export async function readSeedChunks() {
  return JSON.parse(await fs.readFile(localChunksPath, 'utf8'));
}

async function readLocalUsers() {
  if (localUsersCache) return localUsersCache;
  try {
    const data = await fs.readFile(localUsersPath, 'utf8');
    localUsersCache = JSON.parse(data);
  } catch (error) {
    localUsersCache = [
      { name: 'Bilaa', email: 'bilaa@cuanly.ai', password: 'password123' },
      { name: 'Demo', email: 'demo@cuanly.ai', password: 'password123' }
    ];
    await fs.writeFile(localUsersPath, JSON.stringify(localUsersCache, null, 2), 'utf8');
  }
  return localUsersCache;
}

export async function getUsers() {
  const client = await getPrisma();
  if (!client) return readLocalUsers();

  try {
    const users = await client.user.findMany();
    if (users.length === 0) {
      const defaults = await readLocalUsers();
      for (const u of defaults) {
        await client.user.create({ data: u });
      }
      return client.user.findMany();
    }
    return users;
  } catch (error) {
    console.warn('Gagal memuat users dari database, menggunakan fallback JSON lokal:', error.message);
    return readLocalUsers();
  }
}

export async function createUser(name, email, password) {
  const client = await getPrisma();
  if (!client) {
    const users = await readLocalUsers();
    users.push({ name, email, password });
    await fs.writeFile(localUsersPath, JSON.stringify(users, null, 2), 'utf8');
    localUsersCache = users;
    return { name, email };
  }

  try {
    const user = await client.user.create({
      data: { name, email, password }
    });
    return user;
  } catch (error) {
    console.warn('Gagal menyimpan user ke database, menggunakan fallback JSON lokal:', error.message);
    const users = await readLocalUsers();
    users.push({ name, email, password });
    await fs.writeFile(localUsersPath, JSON.stringify(users, null, 2), 'utf8');
    localUsersCache = users;
    return { name, email };
  }
}

// --- FINANCIAL STORAGE FOR WALLETS & TRANSACTIONS ---

function getDefaultWallets(email) {
  if (email === 'bilaa@cuanly.ai' || email === 'demo@cuanly.ai') {
    return [
      { name: 'Bank Mandiri', balance: 3500000, cardNumber: '•••• 8821', designType: 'blue' },
      { name: 'GoPay', balance: 500000, cardNumber: '0812 •••• 9012', designType: 'teal' },
      { name: 'OVO', balance: 200000, cardNumber: '0812 •••• 9012', designType: 'purple' },
      { name: 'Cash', balance: 0, cardNumber: 'Fisik', designType: 'slate' }
    ];
  }
  return [
    { name: 'Cash', balance: 0, cardNumber: 'Fisik', designType: 'slate' }
  ];
}

function getDefaultTransactions(email) {
  if (email === 'bilaa@cuanly.ai' || email === 'demo@cuanly.ai') {
    return [
      {
        id: 't1',
        title: 'Restoran & Coffee Shop',
        category: 'Makanan',
        date: new Date(Date.now() - 45 * 60000).toISOString(),
        amount: 650000,
        isExpense: true,
        walletName: 'Cash'
      },
      {
        id: 't2',
        title: 'Grab Ride',
        category: 'Transport',
        date: new Date(Date.now() - 2 * 24 * 3600000).toISOString(),
        amount: 320000,
        isExpense: true,
        walletName: 'GoPay'
      },
      {
        id: 't3',
        title: 'Belanja Indomaret',
        category: 'Belanja',
        date: new Date(Date.now() - 4 * 3600000).toISOString(),
        amount: 430000,
        isExpense: true,
        walletName: 'Bank Mandiri'
      },
      {
        id: 't4',
        title: 'Gaji Bulanan',
        category: 'Pemasukan',
        date: new Date(Date.now() - 3 * 24 * 3600000).toISOString(),
        amount: 3500000,
        isExpense: false,
        walletName: 'Bank Mandiri'
      }
    ];
  }
  return [];
}

async function readLocalWallets() {
  if (localWalletsCache) return localWalletsCache;
  try {
    const data = await fs.readFile(localWalletsPath, 'utf8');
    localWalletsCache = JSON.parse(data);
  } catch (error) {
    localWalletsCache = [];
    await fs.writeFile(localWalletsPath, JSON.stringify(localWalletsCache, null, 2), 'utf8');
  }
  return localWalletsCache;
}

async function readLocalTransactions() {
  if (localTransactionsCache) return localTransactionsCache;
  try {
    const data = await fs.readFile(localTransactionsPath, 'utf8');
    localTransactionsCache = JSON.parse(data);
  } catch (error) {
    localTransactionsCache = [];
    await fs.writeFile(localTransactionsPath, JSON.stringify(localTransactionsCache, null, 2), 'utf8');
  }
  return localTransactionsCache;
}

export async function getWallets(email) {
  const client = await getPrisma();
  if (!client) {
    const allWallets = await readLocalWallets();
    const userWallets = allWallets.filter(w => w.userEmail === email);
    if (userWallets.length === 0) {
      const defaults = getDefaultWallets(email);
      const seeded = defaults.map(w => ({ ...w, userEmail: email }));
      allWallets.push(...seeded);
      await fs.writeFile(localWalletsPath, JSON.stringify(allWallets, null, 2), 'utf8');
      localWalletsCache = allWallets;
      return seeded;
    }
    return userWallets;
  }

  try {
    const wallets = await client.wallet.findMany({ where: { userEmail: email } });
    if (wallets.length === 0) {
      const defaults = getDefaultWallets(email);
      for (const w of defaults) {
        await client.wallet.create({
          data: {
            userEmail: email,
            name: w.name,
            balance: w.balance,
            cardNumber: w.cardNumber,
            designType: w.designType,
          }
        });
      }
      return client.wallet.findMany({ where: { userEmail: email } });
    }
    return wallets;
  } catch (error) {
    console.warn('Gagal memuat wallets dari database, menggunakan fallback JSON lokal:', error.message);
    const allWallets = await readLocalWallets();
    const userWallets = allWallets.filter(w => w.userEmail === email);
    if (userWallets.length === 0) {
      const defaults = getDefaultWallets(email);
      const seeded = defaults.map(w => ({ ...w, userEmail: email }));
      allWallets.push(...seeded);
      await fs.writeFile(localWalletsPath, JSON.stringify(allWallets, null, 2), 'utf8');
      localWalletsCache = allWallets;
      return seeded;
    }
    return userWallets;
  }
}

export async function createWallet(email, name, balance, cardNumber, designType) {
  const client = await getPrisma();
  if (!client) {
    const allWallets = await readLocalWallets();
    const newWallet = { userEmail: email, name, balance, cardNumber, designType };
    allWallets.push(newWallet);
    await fs.writeFile(localWalletsPath, JSON.stringify(allWallets, null, 2), 'utf8');
    localWalletsCache = allWallets;
    return newWallet;
  }

  try {
    const wallet = await client.wallet.create({
      data: { userEmail: email, name, balance, cardNumber, designType }
    });
    return wallet;
  } catch (error) {
    console.warn('Gagal membuat wallet di database, menggunakan fallback JSON lokal:', error.message);
    const allWallets = await readLocalWallets();
    const newWallet = { userEmail: email, name, balance, cardNumber, designType };
    allWallets.push(newWallet);
    await fs.writeFile(localWalletsPath, JSON.stringify(allWallets, null, 2), 'utf8');
    localWalletsCache = allWallets;
    return newWallet;
  }
}

export async function getTransactions(email) {
  const client = await getPrisma();
  if (!client) {
    const allTxs = await readLocalTransactions();
    const userTxs = allTxs.filter(t => t.userEmail === email);
    if (userTxs.length === 0) {
      const defaults = getDefaultTransactions(email);
      const seeded = defaults.map(t => ({ ...t, userEmail: email }));
      allTxs.push(...seeded);
      await fs.writeFile(localTransactionsPath, JSON.stringify(allTxs, null, 2), 'utf8');
      localTransactionsCache = allTxs;
      return seeded;
    }
    return userTxs;
  }

  try {
    const txs = await client.transaction.findMany({ where: { userEmail: email } });
    if (txs.length === 0) {
      const defaults = getDefaultTransactions(email);
      for (const t of defaults) {
        await client.transaction.create({
          data: {
            id: t.id,
            userEmail: email,
            title: t.title,
            category: t.category,
            date: new Date(t.date),
            amount: t.amount,
            isExpense: t.isExpense,
            walletName: t.walletName,
          }
        });
      }
      return client.transaction.findMany({ where: { userEmail: email } });
    }
    return txs;
  } catch (error) {
    console.warn('Gagal memuat transaksi dari database, menggunakan fallback JSON lokal:', error.message);
    const allTxs = await readLocalTransactions();
    const userTxs = allTxs.filter(t => t.userEmail === email);
    if (userTxs.length === 0) {
      const defaults = getDefaultTransactions(email);
      const seeded = defaults.map(t => ({ ...t, userEmail: email }));
      allTxs.push(...seeded);
      await fs.writeFile(localTransactionsPath, JSON.stringify(allTxs, null, 2), 'utf8');
      localTransactionsCache = allTxs;
      return seeded;
    }
    return userTxs;
  }
}

export async function createTransaction(email, id, title, category, dateStr, amount, isExpense, walletName) {
  const client = await getPrisma();
  const dateObj = new Date(dateStr);

  if (!client) {
    const allTxs = await readLocalTransactions();
    const newTx = { id, userEmail: email, title, category, date: dateStr, amount, isExpense, walletName };
    allTxs.push(newTx);
    await fs.writeFile(localTransactionsPath, JSON.stringify(allTxs, null, 2), 'utf8');
    localTransactionsCache = allTxs;

    const allWallets = await readLocalWallets();
    const walletIdx = allWallets.findIndex(w => w.userEmail === email && w.name === walletName);
    if (walletIdx !== -1) {
      const balanceChange = isExpense ? -amount : amount;
      allWallets[walletIdx].balance += balanceChange;
      await fs.writeFile(localWalletsPath, JSON.stringify(allWallets, null, 2), 'utf8');
      localWalletsCache = allWallets;
    }

    return newTx;
  }

  try {
    const tx = await client.transaction.create({
      data: { id, userEmail: email, title, category, date: dateObj, amount, isExpense, walletName }
    });

    const wallet = await client.wallet.findFirst({
      where: { userEmail: email, name: walletName }
    });
    if (wallet) {
      const balanceChange = isExpense ? -amount : amount;
      await client.wallet.update({
        where: { id: wallet.id },
        data: { balance: wallet.balance + balanceChange }
      });
    }
    return tx;
  } catch (error) {
    console.warn('Gagal membuat transaksi di database, menggunakan fallback JSON lokal:', error.message);
    const allTxs = await readLocalTransactions();
    const newTx = { id, userEmail: email, title, category, date: dateStr, amount, isExpense, walletName };
    allTxs.push(newTx);
    await fs.writeFile(localTransactionsPath, JSON.stringify(allTxs, null, 2), 'utf8');
    localTransactionsCache = allTxs;

    const allWallets = await readLocalWallets();
    const walletIdx = allWallets.findIndex(w => w.userEmail === email && w.name === walletName);
    if (walletIdx !== -1) {
      const balanceChange = isExpense ? -amount : amount;
      allWallets[walletIdx].balance += balanceChange;
      await fs.writeFile(localWalletsPath, JSON.stringify(allWallets, null, 2), 'utf8');
      localWalletsCache = allWallets;
    }
    return newTx;
  }
}
