import 'dotenv/config';
import { closePrisma, readSeedChunks, seedRagChunks } from '../src/db.js';

try {
  const chunks = await readSeedChunks();
  const result = await seedRagChunks(chunks);
  console.log(`Seeded ${chunks.length} RAG chunks with Prisma.`);
  console.log(JSON.stringify(result, null, 2));
} finally {
  await closePrisma();
}
