import { createApp } from "./app.js";
import { connectMongo } from "./config/mongo.js";
import { loadEnv } from "./config/env.js";

async function main() {
  const env = loadEnv();
  const app = createApp();
  const port = Number(env.PORT || 4000);

  app.listen(port, () => {
    // eslint-disable-next-line no-console
    console.log(`server listening on :${port}`);
  });

  // Connect to Mongo in the background so healthz works even if DB is down
  connectMongo(env.MONGODB_URI, env.DB_NAME)
    .then(() => {
      // eslint-disable-next-line no-console
      console.log("MongoDB connected");
    })
    .catch((err) => {
      // eslint-disable-next-line no-console
      console.error("MongoDB connection failed:", err.message || err);
    });
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
});

