import express from "express";
import cors from "cors";
import helmet from "helmet";
import pinoHttp from "pino-http";
import swaggerUi from "swagger-ui-express";
import { logger } from "./services/logger.js";
import routes from "./routes/index.js";
import { authRouter } from "./routes/auth.routes.js";
import { swaggerSpec } from "./config/swagger.js";

export function createApp() {
  const app = express();
  
  // Configure Helmet with content security policy that allows Swagger UI
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          styleSrc: ["'self'", "'unsafe-inline'", "https://cdn.jsdelivr.net"],
          scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'", "https://cdn.jsdelivr.net"],
          imgSrc: ["'self'", "data:", "https:"],
        },
      },
    })
  );
  
  app.use(cors());
  app.use(express.json({ limit: "1mb" }));
  app.use(pinoHttp({ logger }));

  /**
   * @swagger
   * /healthz:
   *   get:
   *     summary: Health check endpoint
   *     description: Returns the health status of the API server
   *     tags:
   *       - Health
   *     responses:
   *       200:
   *         description: Server is healthy
   *         content:
   *           application/json:
   *             schema:
   *               $ref: '#/components/schemas/HealthCheckResponse'
   */
  app.get("/healthz", (_req, res) => res.json({ ok: true }));

  // Swagger documentation
  app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));

  app.use("/api/v1", routes);
  app.use("/auth", authRouter);

  // Error handler
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  app.use((err: any, _req: any, res: any, _next: any) => {
    logger.error({ err }, "unhandled_error");
    res.status(err?.status || 500).json({ error: err?.message || "Internal Error" });
  });

  return app;
}

export default createApp;

