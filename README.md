# FinSight AI Demo

Project demo interaktif untuk **FinSight AI - Smart Personal Finance & Expense Intelligence Assistant**.

Stack:
- Flutter/Dart untuk UI demo.
- Node.js API lokal untuk simulasi RAG.
- Prisma schema untuk MySQL (`backend/prisma/schema.prisma`).
- Data RAG lokal dari dokumen FAQ, policy expense, dan sample transaksi.

## Cara Demo Cepat

Terminal 1:

```powershell
cd "D:\Bilaa's File\Blok B\Artificial Intelligence\FInSight AI\finsight_ai_demo\backend"
npm start
```

Terminal 2:

```powershell
cd "D:\Bilaa's File\Blok B\Artificial Intelligence\FInSight AI\finsight_ai_demo"
flutter run -d windows
```

## Endpoint API

- `GET /health`
- `GET /chunks`
- `GET /demo-questions`
- `POST /rag/query`

Payload contoh:

```json
{
  "question": "Apakah klaim makan klien senilai Rp 500.000 ini sesuai policy?",
  "userSegment": "b2b",
  "docType": "auto",
  "topK": 3
}
```

## Mode Prisma MySQL

1. Buat database MySQL `finsight_ai`.
2. Copy `.env.example` menjadi `.env`, lalu sesuaikan `DATABASE_URL`.
3. Jalankan:

```powershell
npm install
npm run prisma:generate
npm run prisma:push
npm run prisma:seed
```

API demo tetap bisa berjalan tanpa MySQL karena memakai `data/chunks.json` sebagai fallback lokal.
