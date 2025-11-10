import { MongoClient, Db } from "mongodb";

let client: MongoClient | null = null;
let db: Db | null = null;

export async function connectMongo(uri: string, dbName: string) {
  client = new MongoClient(uri, { serverSelectionTimeoutMS: 10000 });
  await client.connect();
  db = client.db(dbName);
  return db;
}

export function getDb(): Db {
  if (!db) throw new Error("Mongo DB not initialized");
  return db;
}

export function isMongoConnected(): boolean {
  return !!db;
}

export async function pingMongo(): Promise<boolean> {
  try {
    if (!db) return false;
    // The ping command is cheap and does not require auth beyond the connection
    await db.command({ ping: 1 });
    return true;
  } catch {
    return false;
  }
}

