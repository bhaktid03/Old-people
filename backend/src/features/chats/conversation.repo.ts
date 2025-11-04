import { getDb } from "../../config/mongo.js";
import type { ConversationDoc, MessageDoc, MessageReceipt } from "./conversation.types.js";

const CONVERSATIONS = "conversations";
const MESSAGES = "messages";

export async function createConversation(doc: Omit<ConversationDoc, "createdAt" | "updatedAt">): Promise<ConversationDoc> {
  const db = getDb();
  const now = new Date();
  const toInsert: ConversationDoc = { ...doc, createdAt: now, updatedAt: now } as ConversationDoc;
  await db.collection<ConversationDoc>(CONVERSATIONS).insertOne(toInsert as any);
  return toInsert;
}

export async function getConversationById(id: string): Promise<ConversationDoc | null> {
  const db = getDb();
  return await db.collection<ConversationDoc>(CONVERSATIONS).findOne({ _id: id });
}

export async function listUserConversations(userId: string, limit = 50): Promise<ConversationDoc[]> {
  const db = getDb();
  const cursor = db.collection<ConversationDoc>(CONVERSATIONS)
    .find({ memberIds: userId }, { limit, sort: { updatedAt: -1 } });
  return await cursor.toArray();
}

export async function updateConversation(id: string, update: Partial<ConversationDoc>): Promise<ConversationDoc | null> {
  const db = getDb();
  const res = await db.collection<ConversationDoc>(CONVERSATIONS)
    .findOneAndUpdate({ _id: id }, { $set: { ...update, updatedAt: new Date() } }, { returnDocument: "after" });
  return (res && (res as any).value) || null;
}

export async function addMembers(conversationId: string, memberIds: string[]): Promise<ConversationDoc | null> {
  const db = getDb();
  const res = await db.collection<ConversationDoc>(CONVERSATIONS)
    .findOneAndUpdate({ _id: conversationId }, { $addToSet: { memberIds: { $each: memberIds } }, $set: { updatedAt: new Date() } }, { returnDocument: "after" });
  return (res && (res as any).value) || null;
}

export async function removeMembers(conversationId: string, memberIds: string[]): Promise<ConversationDoc | null> {
  const db = getDb();
  const res = await db.collection<ConversationDoc>(CONVERSATIONS)
    .findOneAndUpdate({ _id: conversationId }, { $pull: { memberIds: { $in: memberIds } }, $set: { updatedAt: new Date() } }, { returnDocument: "after" });
  return (res && (res as any).value) || null;
}

export async function sendMessage(message: Omit<MessageDoc, "createdAt" | "updatedAt">): Promise<MessageDoc> {
  const db = getDb();
  const now = new Date();
  const toInsert: MessageDoc = { ...message, createdAt: now, updatedAt: now } as MessageDoc;
  await db.collection<MessageDoc>(MESSAGES).insertOne(toInsert as any);
  await db.collection<ConversationDoc>(CONVERSATIONS).updateOne(
    { _id: message.conversationId },
    { $set: { lastMessageId: message._id, lastMessageAt: now, updatedAt: now } }
  );
  return toInsert;
}

export async function listMessages(conversationId: string, limit = 50, before?: string): Promise<MessageDoc[]> {
  const db = getDb();
  const query: any = { conversationId };
  if (before) query._id = { $lt: before };
  const cursor = db.collection<MessageDoc>(MESSAGES)
    .find(query, { limit, sort: { createdAt: -1 } });
  return await cursor.toArray();
}

export async function getMessageById(messageId: string): Promise<MessageDoc | null> {
  const db = getDb();
  return await db.collection<MessageDoc>(MESSAGES).findOne({ _id: messageId });
}

export async function editMessage(messageId: string, text: string): Promise<MessageDoc | null> {
  const db = getDb();
  const res = await db.collection<MessageDoc>(MESSAGES)
    .findOneAndUpdate({ _id: messageId }, { $set: { text, editedAt: new Date(), updatedAt: new Date() } }, { returnDocument: "after" });
  return (res && (res as any).value) || null;
}

export async function softDeleteMessageForAll(messageId: string): Promise<MessageDoc | null> {
  const db = getDb();
  const res = await db.collection<MessageDoc>(MESSAGES)
    .findOneAndUpdate({ _id: messageId }, { $set: { deletedAt: new Date(), updatedAt: new Date() } }, { returnDocument: "after" });
  return (res && (res as any).value) || null;
}

export async function deleteMessageForUser(messageId: string, userId: string): Promise<MessageDoc | null> {
  const db = getDb();
  const res = await db.collection<MessageDoc>(MESSAGES)
    .findOneAndUpdate({ _id: messageId }, { $addToSet: { deletedForUserIds: userId }, $set: { updatedAt: new Date() } }, { returnDocument: "after" });
  return (res && (res as any).value) || null;
}

export async function upsertReceipt(messageId: string, userId: string, updates: Partial<MessageReceipt>): Promise<MessageDoc | null> {
  const db = getDb();
  const message = await db.collection<MessageDoc>(MESSAGES).findOne({ _id: messageId });
  if (!message) return null;
  const receipts = message.receipts || [];
  const idx = receipts.findIndex(r => r.userId === userId);
  if (idx >= 0) {
    receipts[idx] = { ...receipts[idx], ...updates };
  } else {
    receipts.push({ userId, ...updates });
  }
  const res = await db.collection<MessageDoc>(MESSAGES)
    .findOneAndUpdate({ _id: messageId }, { $set: { receipts, updatedAt: new Date() } }, { returnDocument: "after" });
  return (res && (res as any).value) || null;
}


