import { ObjectId } from "mongodb";
import { getDb } from "../../config/mongo.js";
import { CommunityThoughtDoc, CreateCommunityThoughtInput } from "./community.types.js";

export async function createCommunityThought(input: CreateCommunityThoughtInput): Promise<CommunityThoughtDoc> {
  const db = getDb();
  const now = new Date();
  
  const doc: CommunityThoughtDoc = {
    _id: new ObjectId().toString(),
    communityId: input.communityId,
    userId: input.userId,
    contentType: input.contentType,
    content: input.content,
    respectUserIds: [],
    createdAt: now,
    updatedAt: now,
  };

  await db.collection<CommunityThoughtDoc>("community_thoughts").insertOne(doc);
  return doc;
}

export async function getCommunityThoughtById(thoughtId: string): Promise<CommunityThoughtDoc | null> {
  const db = getDb();
  return await db.collection<CommunityThoughtDoc>("community_thoughts").findOne({ _id: thoughtId });
}

export async function getCommunityThoughtsByCommunityId(
  communityId: string,
  options?: { limit?: number; skip?: number }
): Promise<CommunityThoughtDoc[]> {
  const db = getDb();
  const limit = options?.limit ?? 20;
  const skip = options?.skip ?? 0;

  return await db
    .collection<CommunityThoughtDoc>("community_thoughts")
    .find({ communityId })
    .sort({ createdAt: -1 }) // Most recent first
    .skip(skip)
    .limit(limit)
    .toArray();
}

export async function getCommunityThoughtsByUserId(
  userId: string,
  options?: { limit?: number; skip?: number }
): Promise<CommunityThoughtDoc[]> {
  const db = getDb();
  const limit = options?.limit ?? 20;
  const skip = options?.skip ?? 0;

  return await db
    .collection<CommunityThoughtDoc>("community_thoughts")
    .find({ userId })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .toArray();
}

export async function getAllCommunityThoughts(
  options?: { limit?: number; skip?: number }
): Promise<CommunityThoughtDoc[]> {
  const db = getDb();
  const limit = options?.limit ?? 20;
  const skip = options?.skip ?? 0;

  return await db
    .collection<CommunityThoughtDoc>("community_thoughts")
    .find({})
    .sort({ createdAt: -1 }) // Most recent first
    .skip(skip)
    .limit(limit)
    .toArray();
}

export async function deleteCommunityThought(thoughtId: string, userId: string): Promise<boolean> {
  const db = getDb();
  const result = await db
    .collection<CommunityThoughtDoc>("community_thoughts")
    .deleteOne({ _id: thoughtId, userId }); // Only allow deletion by owner

  return result.deletedCount > 0;
}

export async function updateCommunityThought(
  thoughtId: string,
  userId: string,
  updates: Partial<Pick<CommunityThoughtDoc, "content">>
): Promise<CommunityThoughtDoc | null> {
  const db = getDb();
  const now = new Date();

  const result = await db
    .collection<CommunityThoughtDoc>("community_thoughts")
    .findOneAndUpdate(
      { _id: thoughtId, userId }, // Only allow update by owner
      { $set: { ...updates, updatedAt: now } },
      { returnDocument: "after" }
    );

  return result ?? null;
}

export async function attachMediaToCommunityThought(
  thoughtId: string,
  kind: "audio" | "video",
  fileId: string
): Promise<void> {
  const db = getDb();
  const now = new Date();
  const field = kind === "audio" ? "content.audioFileId" : "content.videoFileId";
  await db
    .collection<CommunityThoughtDoc>("community_thoughts")
    .updateOne({ _id: thoughtId }, { $set: { [field]: fileId, updatedAt: now } });
}

export async function addRespect(thoughtId: string, userId: string): Promise<CommunityThoughtDoc | null> {
  const db = getDb();
  const now = new Date();
  const result = await db
    .collection<CommunityThoughtDoc>("community_thoughts")
    .findOneAndUpdate(
      { _id: thoughtId },
      { $addToSet: { respectUserIds: userId }, $set: { updatedAt: now } },
      { returnDocument: "after" }
    );
  return result ?? null;
}

export async function removeRespect(thoughtId: string, userId: string): Promise<CommunityThoughtDoc | null> {
  const db = getDb();
  const now = new Date();
  const result = await db
    .collection<CommunityThoughtDoc>("community_thoughts")
    .findOneAndUpdate(
      { _id: thoughtId },
      { $pull: { respectUserIds: userId }, $set: { updatedAt: now } },
      { returnDocument: "after" }
    );
  return result ?? null;
}

// Initialize indexes on collection
export async function ensureCommunityThoughtsIndexes(): Promise<void> {
  const db = getDb();
  const collection = db.collection<CommunityThoughtDoc>("community_thoughts");

  // Index for querying thoughts by communityId
  await collection.createIndex({ communityId: 1, createdAt: -1 });
  
  // Index for querying thoughts by userId
  await collection.createIndex({ userId: 1, createdAt: -1 });
  
  // Index for communityId and userId combination
  await collection.createIndex({ communityId: 1, userId: 1 });
}

