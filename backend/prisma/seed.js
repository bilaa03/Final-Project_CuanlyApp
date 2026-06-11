import { PrismaClient } from '@prisma/client';
import fs from 'node:fs/promises';

const prisma = new PrismaClient();
const chunks = JSON.parse(await fs.readFile(new URL('../data/chunks.json', import.meta.url), 'utf8'));

for (const chunk of chunks) {
  await prisma.ragChunk.upsert({
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

await prisma.demoQuestion.createMany({
  data: [
    { label: 'Budget B2C', userSegment: 'b2c', docType: 'auto', question: 'Berapa total pengeluaranku bulan ini dan apakah sudah melebihi budget?' },
    { label: 'Tips Transport', userSegment: 'b2c', docType: 'auto', question: 'Apa tips menghemat pengeluaran transport?' },
    { label: 'Client Meal', userSegment: 'b2b', docType: 'auto', question: 'Apakah klaim makan klien senilai Rp 500.000 ini sesuai dengan policy expense perusahaan?' },
  ],
  skipDuplicates: true,
});

console.log(`Seeded ${chunks.length} RAG chunks.`);
await prisma.$disconnect();
