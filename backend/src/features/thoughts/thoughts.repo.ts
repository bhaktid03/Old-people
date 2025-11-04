import { ObjectId } from "mongodb";
import { getDb } from "../../config/mongo.js";
import { ThoughtDoc, CreateThoughtInput } from "./thoughts.types.js";

export async function createThought(input: CreateThoughtInput): Promise<ThoughtDoc> {
  const db = getDb();
  const now = new Date();
  
  const doc: ThoughtDoc = {
    _id: new ObjectId().toString(),
    newsUrl: input.newsUrl,
    userId: input.userId,
    contentType: input.contentType,
    content: input.content,
    respectUserIds: [],
    createdAt: now,
    updatedAt: now,
  };

  await db.collection<ThoughtDoc>("thoughts").insertOne(doc);
  return doc;
}

export async function getThoughtById(thoughtId: string): Promise<ThoughtDoc | null> {
  const db = getDb();
  return await db.collection<ThoughtDoc>("thoughts").findOne({ _id: thoughtId });
}

export async function getThoughtsByNewsUrl(
  newsUrl: string,
  options?: { limit?: number; skip?: number }
): Promise<ThoughtDoc[]> {
  const db = getDb();
  const limit = options?.limit ?? 20;
  const skip = options?.skip ?? 0;

  return await db
    .collection<ThoughtDoc>("thoughts")
    .find({ newsUrl })
    .sort({ createdAt: -1 }) // Most recent first
    .skip(skip)
    .limit(limit)
    .toArray();
}

export async function getThoughtsByUserId(
  userId: string,
  options?: { limit?: number; skip?: number }
): Promise<ThoughtDoc[]> {
  const db = getDb();
  const limit = options?.limit ?? 20;
  const skip = options?.skip ?? 0;

  return await db
    .collection<ThoughtDoc>("thoughts")
    .find({ userId })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .toArray();
}

export async function deleteThought(thoughtId: string, userId: string): Promise<boolean> {
  const db = getDb();
  const result = await db
    .collection<ThoughtDoc>("thoughts")
    .deleteOne({ _id: thoughtId, userId }); // Only allow deletion by owner

  return result.deletedCount > 0;
}

export async function updateThought(
  thoughtId: string,
  userId: string,
  updates: Partial<Pick<ThoughtDoc, "content">>
): Promise<ThoughtDoc | null> {
  const db = getDb();
  const now = new Date();

  const result = await db
    .collection<ThoughtDoc>("thoughts")
    .findOneAndUpdate(
      { _id: thoughtId, userId }, // Only allow update by owner
      { $set: { ...updates, updatedAt: now } },
      { returnDocument: "after" }
    );

  return result ?? null;
}

export async function attachMediaToThought(
  thoughtId: string,
  kind: "audio" | "video",
  fileId: string
): Promise<void> {
  const db = getDb();
  const now = new Date();
  const field = kind === "audio" ? "content.audioFileId" : "content.videoFileId";
  await db
    .collection<ThoughtDoc>("thoughts")
    .updateOne({ _id: thoughtId }, { $set: { [field]: fileId, updatedAt: now } });
}

export async function addRespect(thoughtId: string, userId: string): Promise<ThoughtDoc | null> {
  const db = getDb();
  const now = new Date();
  const result = await db
    .collection<ThoughtDoc>("thoughts")
    .findOneAndUpdate(
      { _id: thoughtId },
      { $addToSet: { respectUserIds: userId }, $set: { updatedAt: now } },
      { returnDocument: "after" }
    );
  return result ?? null;
}

export async function removeRespect(thoughtId: string, userId: string): Promise<ThoughtDoc | null> {
  const db = getDb();
  const now = new Date();
  const result = await db
    .collection<ThoughtDoc>("thoughts")
    .findOneAndUpdate(
      { _id: thoughtId },
      { $pull: { respectUserIds: userId }, $set: { updatedAt: now } },
      { returnDocument: "after" }
    );
  return result ?? null;
}

// Initialize indexes on collection
export async function ensureThoughtsIndexes(): Promise<void> {
  const db = getDb();
  const collection = db.collection<ThoughtDoc>("thoughts");

  // Index for querying thoughts by newsUrl
  await collection.createIndex({ newsUrl: 1, createdAt: -1 });
  
  // Index for querying thoughts by userId
  await collection.createIndex({ userId: 1, createdAt: -1 });
  
  // Index for newsUrl and userId combination
  await collection.createIndex({ newsUrl: 1, userId: 1 });
}

