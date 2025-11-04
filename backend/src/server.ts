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
  app.listen(port, () => {
    // eslint-disable-next-line no-console
    console.log(`server listening on :${port}`);
  });
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});

