import http from 'node:http';
import { runRag, chunks, demoQuestions } from './ragEngine.js';

const port = Number(process.env.PORT ?? 8787);

function sendJson(res, status, body) {
  const data = JSON.stringify(body, null, 2);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  });
  res.end(data);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk;
      if (body.length > 1_000_000) req.destroy();
    });
    req.on('end', () => resolve(body));
    req.on('error', reject);
  });
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === 'OPTIONS') {
      sendJson(res, 200, { ok: true });
      return;
    }

    const url = new URL(req.url ?? '/', `http://${req.headers.host}`);

    if (req.method === 'GET' && url.pathname === '/health') {
      sendJson(res, 200, {
        ok: true,
        app: 'FinSight AI RAG API',
        mode: process.env.USE_PRISMA === 'true' ? 'prisma-mysql' : 'local-json-demo',
      });
      return;
    }

    if (req.method === 'GET' && url.pathname === '/chunks') {
      sendJson(res, 200, { count: chunks.length, chunks });
      return;
    }

    if (req.method === 'GET' && url.pathname === '/demo-questions') {
      sendJson(res, 200, { questions: demoQuestions });
      return;
    }

    if (req.method === 'POST' && url.pathname === '/rag/query') {
      const raw = await readBody(req);
      const payload = raw ? JSON.parse(raw) : {};
      sendJson(res, 200, runRag(payload));
      return;
    }

    sendJson(res, 404, { error: 'Not found', paths: ['/health', '/chunks', '/demo-questions', '/rag/query'] });
  } catch (error) {
    sendJson(res, 500, { error: error.message });
  }
});

server.listen(port, () => {
  console.log(`FinSight AI RAG API running on http://localhost:${port}`);
});
