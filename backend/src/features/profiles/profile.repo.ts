import { getDb } from "../../config/mongo.js";

export type ProfileDoc = {
  _id: string; // userId (phone)
  displayName?: string;
  imageUrl?: string; // HTTPS URL
  language?: string; // ISO 639-1, e.g. 'hi', 'bn', 'gu'
  createdAt: Date;
  updatedAt: Date;
};

const COLLECTION = "profiles";

export async function getProfile(userId: string): Promise<ProfileDoc | null> {
  const db = getDb();
  return await db.collection<ProfileDoc>(COLLECTION).findOne({ _id: userId });
}

export async function upsertProfile(userId: string, update: Partial<ProfileDoc>): Promise<ProfileDoc> {
  const db = getDb();
  const now = new Date();
  const toSetOnInsert = { _id: userId, createdAt: now } as Partial<ProfileDoc>;
  const toSet = { ...update, updatedAt: now } as Partial<ProfileDoc>;
  const res = await db.collection<ProfileDoc>(COLLECTION).findOneAndUpdate(
    { _id: userId },
    { $setOnInsert: toSetOnInsert, $set: toSet },
    { upsert: true, returnDocument: "after" }
  );
  // @ts-expect-error mongodb type
  return (res && res.value) as ProfileDoc;
}

export async function getUserLanguage(userId: string): Promise<string | null> {
  const db = getDb();
  const doc = await db.collection<ProfileDoc>(COLLECTION).findOne({ _id: userId }, { projection: { language: 1 } });
  return (doc as any)?.language ?? null;
}





