import { getDb } from "../../config/mongo.js";
import type { V2PostDoc } from "./postV2.types.js";

const POSTS_V2 = "community_posts_v2";

export async function createV2Post(doc: Omit<V2PostDoc, "createdAt" | "updatedAt">): Promise<V2PostDoc> {
  const db = getDb();
  const now = new Date();
  const toInsert: V2PostDoc = { ...doc, createdAt: now, updatedAt: now } as V2PostDoc;
  await db.collection<V2PostDoc>(POSTS_V2).insertOne(toInsert as any);
  return toInsert;
}

export async function getV2Post(id: string): Promise<V2PostDoc | null> {
  const db = getDb();
  return await db.collection<V2PostDoc>(POSTS_V2).findOne({ _id: id, deletedAt: { $exists: false } as any });
}

export async function listV2Posts(limit = 20): Promise<V2PostDoc[]> {
  const db = getDb();
  const cursor = db.collection<V2PostDoc>(POSTS_V2).find({ deletedAt: { $exists: false } as any }, { limit, sort: { createdAt: -1 } });
  return await cursor.toArray();
}


