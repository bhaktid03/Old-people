import { createApp } from "./app.js";
import { connectMongo } from "./config/mongo.js";
import { loadEnv } from "./config/env.js";
import { ensureThoughtsIndexes } from "./features/thoughts/thoughts.repo.js";

async function main() {
  const env = loadEnv();
  
  // Try to connect to MongoDB, but allow server to start even if it fails
  try {
    await connectMongo(env.MONGODB_URI, env.DB_NAME);
    // Initialize database indexes
    await ensureThoughtsIndexes();
  } catch (error) {
    console.error("⚠️  MongoDB connection failed. Server will start but database features won't work.");
    console.error("   Fix MongoDB connection to enable full functionality.");
    console.error("   See backend/FIX_MONGODB.md for troubleshooting.");
  }
  
  const app = createApp();
  const port = Number(env.PORT || 4000);
  app.listen(port, () => {
    // eslint-disable-next-line no-console
    console.log(`✅ Server listening on :${port}`);
    console.log(`   Health check: http://localhost:${port}/healthz`);
  });
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});

