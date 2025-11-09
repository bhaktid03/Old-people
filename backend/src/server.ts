import { createApp } from "./app.js";
import { connectMongo } from "./config/mongo.js";
import { loadEnv } from "./config/env.js";
import { ensureThoughtsIndexes } from "./features/thoughts/thoughts.repo.js";

async function main() {
  const env = loadEnv();
  await connectMongo(env.MONGODB_URI, env.DB_NAME);
  
  // Initialize database indexes
  await ensureThoughtsIndexes();
  
  const app = createApp();
  const port = Number(env.PORT || 4000);
  const server = app.listen(port, () => {
    // eslint-disable-next-line no-console
    console.log(`server listening on :${port}`);
  });

  server.on('error', (err: NodeJS.ErrnoException) => {
    if (err.code === 'EADDRINUSE') {
      // eslint-disable-next-line no-console
      console.error(`Port ${port} is already in use. Please either:`);
      // eslint-disable-next-line no-console
      console.error(`  1. Stop the process using port ${port}`);
      // eslint-disable-next-line no-console
      console.error(`  2. Set a different PORT in your .env file`);
      process.exit(1);
    } else {
      // eslint-disable-next-line no-console
      console.error('Server error:', err);
      process.exit(1);
    }
  });
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});

