import express from 'express';
import { connectMongo, getDb } from './config/mongo.js';
import { logger } from './services/logger.js';

export async function buildApp() {
  await connectMongo();

  const app = express();
  app.use(express.json({ limit: '2mb' }));

  app.get('/health', (_req, res) => {
    res.json({ ok: true });
  });

  app.get('/db/ping', async (_req, res) => {
    try {
      const db = getDb();
      const ping = await db.command({ ping: 1 });
      const collections = await db.collections();
      res.json({ ok: true, ping, collections: collections.map(c => c.collectionName) });
    } catch (err) {
      logger.error({ err }, 'DB ping failed');
      res.status(500).json({ ok: false, error: 'DB ping failed' });
    }
  });

  return app;
}


