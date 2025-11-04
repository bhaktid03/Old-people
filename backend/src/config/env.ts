import dotenv from "dotenv";

export type Env = {
  PORT: string | undefined;
  MONGODB_URI: string;
  DB_NAME: string;
};

export function loadEnv(): Env {
  dotenv.config();

  const {
    PORT,
    MONGODB_URI,
    DB_NAME: DB_NAME_RAW,
    MONGODB_DB,
  } = process.env as Record<string, string>;

  const DB_NAME = DB_NAME_RAW || MONGODB_DB;
  if (!MONGODB_URI) throw new Error("MONGODB_URI is required");
  if (!DB_NAME) throw new Error("DB_NAME is required");

  return {
    PORT,
    MONGODB_URI,
    DB_NAME,
  };
}

