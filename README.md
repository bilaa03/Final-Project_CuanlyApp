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
cd "D:\...\finsight_ai_demo\backend"
npm start
```

Terminal 2:

```powershell
cd "D:\...\finsight_ai_demo\backend"
flutter run -d windows
```

## Endpoint API

- `GET /health`
- `GET /chunks`
- `GET /demo-questions`
- `POST /rag/query`
