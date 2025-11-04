import { Request, Response } from "express";
import { addMembers, createConversation, deleteMessageForUser, editMessage, getConversationById, getMessageById, listMessages, listUserConversations, removeMembers, sendMessage, softDeleteMessageForAll, updateConversation, upsertReceipt } from "./conversation.repo.js";
import type { ConversationDoc, MessageDoc } from "./conversation.types.js";

/**
 * @swagger
 * tags:
 *   - name: Chats
 *     description: Conversation management
 *   - name: Messages
 *     description: Message actions
 *   - name: Presence
 *     description: Online/last seen state
 */

/**
 * @swagger
 * /api/v1/chats/conversations:
 *   post:
 *     summary: Create a conversation (solo or group)
 *     tags: [Chats]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Conversation'
 *     responses:
 *       201:
 *         description: Created
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Conversation'
 */
export async function createConversationHandler(req: Request, res: Response) {
  const body = req.body as Partial<ConversationDoc>;
  if (!body?._id || !body?.type || !Array.isArray(body?.memberIds) || body.memberIds.length < 2) {
    return res.status(400).json({ ok: false, error: "_id, type and at least 2 memberIds required" });
  }
  const created = await createConversation({
    _id: body._id,
    type: body.type,
    memberIds: body.memberIds,
    adminIds: body.adminIds,
    name: body.name,
    avatarUrl: body.avatarUrl,
  } as any);
  res.status(201).json(created);
}

/**
 * @swagger
 * /api/v1/chats/conversations:
 *   get:
 *     summary: List conversations for a user
 *     tags: [Chats]
 *     parameters:
 *       - in: query
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *     responses:
 *       200:
 *         description: OK
 */
export async function listConversationsHandler(req: Request, res: Response) {
  const userId = String(req.query.userId || "");
  if (!userId) return res.status(400).json({ ok: false, error: "userId query is required" });
  const data = await listUserConversations(userId, req.query.limit ? Number(req.query.limit) : 50);
  res.json({ data });
}

/**
 * @swagger
 * /api/v1/chats/conversations/{id}:
 *   get:
 *     summary: Get conversation by ID
 *     tags: [Chats]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: OK
 */
export async function getConversationHandler(req: Request, res: Response) {
  const conv = await getConversationById(req.params.id);
  if (!conv) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(conv);
}

export async function updateConversationHandler(req: Request, res: Response) {
  const updated = await updateConversation(req.params.id, req.body as Partial<ConversationDoc>);
  if (!updated) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(updated);
}

export async function addMembersHandler(req: Request, res: Response) {
  const { memberIds } = req.body as { memberIds: string[] };
  if (!Array.isArray(memberIds) || memberIds.length === 0) return res.status(400).json({ ok: false, error: "memberIds required" });
  const updated = await addMembers(req.params.id, memberIds);
  if (!updated) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(updated);
}

export async function removeMembersHandler(req: Request, res: Response) {
  const { memberIds } = req.body as { memberIds: string[] };
  if (!Array.isArray(memberIds) || memberIds.length === 0) return res.status(400).json({ ok: false, error: "memberIds required" });
  const updated = await removeMembers(req.params.id, memberIds);
  if (!updated) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(updated);
}

/**
 * @swagger
 * /api/v1/chats/conversations/{id}/messages:
 *   get:
 *     summary: List messages in a conversation
 *     tags: [Messages]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *       - in: query
 *         name: before
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: OK
 */
export async function listMessagesHandler(req: Request, res: Response) {
  const { id } = req.params; // conversationId
  const limit = req.query.limit ? Number(req.query.limit) : 50;
  const before = req.query.before ? String(req.query.before) : undefined;
  const data = await listMessages(id, limit, before);
  res.json({ data });
}

/**
 * @swagger
 * /api/v1/chats/conversations/{id}/messages:
 *   post:
 *     summary: Send a message
 *     tags: [Messages]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Message'
 *     responses:
 *       201:
 *         description: Created
 */
export async function sendMessageHandler(req: Request, res: Response) {
  const body = req.body as Partial<MessageDoc>;
  if (!body?._id || !body?.conversationId || !body?.senderId || !body?.type) {
    return res.status(400).json({ ok: false, error: "_id, conversationId, senderId, type required" });
  }
  const created = await sendMessage({
    _id: body._id,
    conversationId: body.conversationId,
    senderId: body.senderId,
    type: body.type,
    text: body.text,
    mediaUrl: body.mediaUrl,
    mediaMimeType: body.mediaMimeType,
    voiceDurationMs: body.voiceDurationMs,
    receipts: body.receipts || [],
  } as any);
  res.status(201).json(created);
}

export async function editMessageHandler(req: Request, res: Response) {
  const { text } = req.body as { text: string };
  if (!text) return res.status(400).json({ ok: false, error: "text required" });
  const updated = await editMessage(req.params.messageId, text);
  if (!updated) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(updated);
}

export async function deleteMessageAllHandler(req: Request, res: Response) {
  const updated = await softDeleteMessageForAll(req.params.messageId);
  if (!updated) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(updated);
}

export async function deleteMessageForUserHandler(req: Request, res: Response) {
  const { userId } = req.body as { userId: string };
  if (!userId) return res.status(400).json({ ok: false, error: "userId required" });
  const updated = await deleteMessageForUser(req.params.messageId, userId);
  if (!updated) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(updated);
}

/**
 * @swagger
 * /api/v1/chats/messages/{messageId}/receipt:
 *   post:
 *     summary: Update delivery/read receipts
 *     tags: [Messages]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userId: { type: string }
 *               delivered: { type: boolean }
 *               seen: { type: boolean }
 *     responses:
 *       200:
 *         description: OK
 */
export async function receiptHandler(req: Request, res: Response) {
  const { userId, delivered, seen } = req.body as { userId: string; delivered?: boolean; seen?: boolean };
  if (!userId) return res.status(400).json({ ok: false, error: "userId required" });
  const now = new Date();
  const updates: any = {};
  if (delivered) updates.deliveredAt = now;
  if (seen) updates.seenAt = now;
  const updated = await upsertReceipt(req.params.messageId, userId, updates);
  if (!updated) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(updated);
}

export async function getMessageHandler(req: Request, res: Response) {
  const msg = await getMessageById(req.params.messageId);
  if (!msg) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(msg);
}


