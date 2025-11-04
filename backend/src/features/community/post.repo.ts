import { getDb } from "../../config/mongo.js";
import type { CommentDoc, PostDoc } from "./post.types.js";

const POSTS = "community_posts";
const COMMENTS = "community_comments";

export async function createPost(doc: Omit<PostDoc, "createdAt" | "updatedAt" | "commentsCount" | "likeUserIds">): Promise<PostDoc> {
  const db = getDb();
  const now = new Date();
  const toInsert: PostDoc = { ...doc, likeUserIds: [], commentsCount: 0, createdAt: now, updatedAt: now } as PostDoc;
  await db.collection<PostDoc>(POSTS).insertOne(toInsert as any);
  return toInsert;
}

export async function getPost(postId: string): Promise<PostDoc | null> {
  const db = getDb();
  return await db.collection<PostDoc>(POSTS).findOne({ _id: postId, deletedAt: { $exists: false } as any });
}

export async function listPosts(sort: "recent" | "trending" = "recent", limit = 20): Promise<PostDoc[]> {
  const db = getDb();
  const sortSpec = sort === "trending" ? { commentsCount: -1, updatedAt: -1 } : { createdAt: -1 };
  const cursor = db.collection<PostDoc>(POSTS).find({ deletedAt: { $exists: false } as any }, { limit, sort: sortSpec });
  return await cursor.toArray();
}

export async function softDeletePost(postId: string): Promise<boolean> {
  const db = getDb();
  const res = await db.collection<PostDoc>(POSTS).updateOne({ _id: postId }, { $set: { deletedAt: new Date(), updatedAt: new Date() } });
  return res.modifiedCount === 1;
}

export async function likePost(postId: string, userId: string): Promise<PostDoc | null> {
  const db = getDb();
  const res = await db.collection<PostDoc>(POSTS).findOneAndUpdate(
    { _id: postId },
    { $addToSet: { likeUserIds: userId }, $set: { updatedAt: new Date() } },
    { returnDocument: "after" }
  );
  return (res && (res as any).value) || null;
}

export async function unlikePost(postId: string, userId: string): Promise<PostDoc | null> {
  const db = getDb();
  const res = await db.collection<PostDoc>(POSTS).findOneAndUpdate(
    { _id: postId },
    { $pull: { likeUserIds: userId }, $set: { updatedAt: new Date() } },
    { returnDocument: "after" }
  );
  return (res && (res as any).value) || null;
}

export async function addComment(doc: Omit<CommentDoc, "createdAt" | "updatedAt">): Promise<CommentDoc> {
  const db = getDb();
  const now = new Date();
  const toInsert: CommentDoc = { ...doc, createdAt: now, updatedAt: now } as CommentDoc;
  await db.collection<CommentDoc>(COMMENTS).insertOne(toInsert as any);
  await db.collection<PostDoc>(POSTS).updateOne({ _id: doc.postId }, { $inc: { commentsCount: 1 }, $set: { updatedAt: now } });
  return toInsert;
}

export async function listComments(postId: string, limit = 50): Promise<CommentDoc[]> {
  const db = getDb();
  const cursor = db.collection<CommentDoc>(COMMENTS).find({ postId }, { limit, sort: { createdAt: -1 } });
  return await cursor.toArray();
}

export async function deleteComment(commentId: string): Promise<boolean> {
  const db = getDb();
  const comment = await db.collection<CommentDoc>(COMMENTS).findOneAndDelete({ _id: commentId });
  const deleted = !!(comment && (comment as any).value);
  if (deleted) {
    const c = (comment as any).value as CommentDoc;
    await db.collection<PostDoc>(POSTS).updateOne({ _id: c.postId }, { $inc: { commentsCount: -1 }, $set: { updatedAt: new Date() } });
  }
  return deleted;
}


