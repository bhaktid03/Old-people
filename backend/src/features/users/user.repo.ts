import { getDb } from "../../config/mongo.js";
import type { ModifyResult } from "mongodb";
import { UserDoc } from "./user.types.js";

const COLLECTION = "users";

export async function listUsers(limit: number = 50): Promise<UserDoc[]> {
  const db = getDb();
  const cursor = db.collection<UserDoc>(COLLECTION)
    .find({}, { limit, sort: { createdAt: -1 } });
  return await cursor.toArray();
}

export async function getUserById(userId: string): Promise<UserDoc | null> {
  const db = getDb();
  return await db.collection<UserDoc>(COLLECTION).findOne({ _id: userId });
}

export async function createUser(user: Omit<UserDoc, "createdAt" | "updatedAt">): Promise<UserDoc> {
  const db = getDb();
  const now = new Date();
  const doc: UserDoc = { ...user, createdAt: now, updatedAt: now } as UserDoc;
  await db.collection<UserDoc>(COLLECTION).insertOne(doc as any);
  return doc;
}

export async function updateUser(userId: string, update: Partial<UserDoc>): Promise<UserDoc | null> {
  const db = getDb();
  const toSet = { ...update, updatedAt: new Date() } as any;
  const res = await db.collection<UserDoc>(COLLECTION)
    .findOneAndUpdate({ _id: userId }, { $set: toSet }, { returnDocument: "after" }) as ModifyResult<UserDoc>;
  const value = (res && (res as ModifyResult<UserDoc>).value) ? (res as ModifyResult<UserDoc>).value as UserDoc : null;
  return value;
}

export async function deleteUser(userId: string): Promise<boolean> {
  const db = getDb();
  const res = await db.collection<UserDoc>(COLLECTION).deleteOne({ _id: userId });
  return res.deletedCount === 1;
}


