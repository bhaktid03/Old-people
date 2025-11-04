import { getDb } from "../../config/mongo.js";

export type ProfileDoc = {
  _id: string; // userId
  language?: string; // ISO 639-1, e.g. 'hi', 'bn', 'gu'
};

export async function getUserLanguage(userId: string): Promise<string | null> {
  const db = getDb();
  const doc = await db.collection<ProfileDoc>("profiles").findOne({ _id: userId }, { projection: { language: 1 } });
  return doc?.language ?? null;
}


