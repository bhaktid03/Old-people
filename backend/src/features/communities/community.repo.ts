import { ObjectId } from "mongodb";
import { getDb } from "../../config/mongo.js";
import { CommunityDoc } from "./community.types.js";

export async function getAllCommunities(options?: { limit?: number; skip?: number }): Promise<CommunityDoc[]> {
  const db = getDb();
  const limit = options?.limit ?? 100;
  const skip = options?.skip ?? 0;

  return await db
    .collection<CommunityDoc>("communities")
    .find({})
    .sort({ createdAt: -1 }) // Most recent first
    .skip(skip)
    .limit(limit)
    .toArray();
}

export async function getCommunityById(communityId: string): Promise<CommunityDoc | null> {
  const db = getDb();
  return await db.collection<CommunityDoc>("communities").findOne({ _id: communityId });
}

// Initialize indexes on collection
export async function ensureCommunitiesIndexes(): Promise<void> {
  const db = getDb();
  const collection = db.collection<CommunityDoc>("communities");

  // Index for querying communities by creation date
  await collection.createIndex({ createdAt: -1 });
}



