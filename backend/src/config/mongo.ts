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

