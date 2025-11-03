import { buildApp } from './app.js';
import { env } from './config/env.js';
import { logger } from './services/logger.js';

async function main() {
  try {
    const app = await buildApp();
    app.listen(env.port, () => {
      logger.info({ port: env.port }, 'API server listening');
    });
  } catch (err) {
    logger.error({ err }, 'Failed to start server');
    process.exit(1);
  }
}

void main();


