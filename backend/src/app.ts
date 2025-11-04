import express from "express";
import cors from "cors";
import helmet from "helmet";
import pino from "pino";
import pinoHttp from "pino-http";
import routes from "./routes/index.js";

const logger = pino({ level: process.env.LOG_LEVEL || "info" });

export function createApp() {
  const app = express();
  app.use(helmet());
  app.use(cors());
  app.use(express.json({ limit: "1mb" }));
  app.use(pinoHttp({ logger }));

  app.get("/healthz", (_req, res) => res.json({ ok: true }));

  app.use("/api/v1", routes);

  // Error handler
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  app.use((err: any, _req: any, res: any, _next: any) => {
    logger.error({ err }, "unhandled_error");
    res.status(err?.status || 500).json({ error: err?.message || "Internal Error" });
  });

  return app;
}

export default createApp;

