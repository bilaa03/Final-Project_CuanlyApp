import 'dotenv/config';
import mysql from 'mysql2/promise';

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error('DATABASE_URL belum dikonfigurasi di backend/.env');
}

const url = new URL(databaseUrl);
const databaseName = url.pathname.replace(/^\//, '');

if (!databaseName) {
  throw new Error('DATABASE_URL harus menyertakan nama database, misalnya /cuanly');
}

let connection;

try {
  connection = await mysql.createConnection({
    host: url.hostname,
    port: Number(url.port || 3306),
    user: decodeURIComponent(url.username),
    password: decodeURIComponent(url.password),
    multipleStatements: false,
  });

  await connection.query(`CREATE DATABASE IF NOT EXISTS \`${databaseName.replaceAll('`', '``')}\``);
  console.log(`Database "${databaseName}" is ready.`);
} catch (error) {
  if (error.code === 'ECONNREFUSED') {
    console.error(
      `Cannot connect to MySQL at ${url.hostname}:${url.port || 3306}. ` +
        'Start MySQL first or update DATABASE_URL to the active host and port.'
    );
    process.exitCode = 1;
  } else {
    throw error;
  }
} finally {
  await connection?.end();
}
