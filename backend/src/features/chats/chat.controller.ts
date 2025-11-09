import { Request, Response } from "express";
import { ObjectId } from "mongodb";
import { addMembers, createConversation, deleteMessageForUser, editMessage, getConversationById, getMessageById, listMessages, listUserConversations, removeMembers, sendMessage, softDeleteMessageForAll, updateConversation, upsertReceipt } from "./conversation.repo.js";
import type { ConversationDoc, MessageDoc } from "./conversation.types.js";
import { getAudioBucket, getVideoBucket, getMediaBucket } from "../../config/gridfs.js";

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
 *     description: |
 *       Create a new conversation. The conversation ID (`_id`) must be provided in the request body.
 *       This ID will be used in the URL path when sending messages: `/api/v1/chats/conversations/{id}/messages`
 *     tags: [Chats]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Conversation'
 *           example:
 *             _id: "conv_123"
 *             type: "solo"
 *             memberIds: ["+919876543210", "+911234567890"]
 *     responses:
 *       201:
 *         description: Conversation created successfully. The response includes the conversation with the `_id` that can be used in subsequent API calls.
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
  *           example: +919876543210
  *           description: Profile _id (E.164 phone)
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
 *     summary: Send a message (supports both JSON and multipart/form-data with media)
 *     description: |
 *       Send a message to a conversation. The conversation ID is obtained from the URL path parameter.
 *       - Use **application/json** for text-only messages or when mediaUrl is already provided
 *       - Use **multipart/form-data** when uploading media files (images, videos, documents, etc.)
 *       - When using multipart/form-data, include the media file in the "media" field
 *       - **Note:** The conversation ID comes from the URL path (`{id}`), not from the request body
 *       - **Note:** The message ID (`_id`) is auto-generated by the backend if not provided
 *     tags: [Messages]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Conversation ID (obtained from creating a conversation via POST /api/v1/chats/conversations or from listing conversations via GET /api/v1/chats/conversations?userId=...)
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [senderId, type]
 *             properties:
 *               _id:
 *                 type: string
 *                 description: Message ID (optional - will be auto-generated if not provided)
 *               senderId:
 *                 type: string
 *                 description: Profile _id (E.164 phone)
 *                 example: "+919876543210"
 *               type:
 *                 type: string
 *                 enum: [text, image, voice, media]
 *                 description: Message type. Use "media" for any file type
 *               text:
 *                 type: string
 *                 description: Message text (optional for media messages)
 *               mediaUrl:
 *                 type: string
 *                 format: uri
 *                 description: URL to the media file (if already uploaded)
 *               mediaMimeType:
 *                 type: string
 *                 description: MIME type of the media file
 *               voiceDurationMs:
 *                 type: integer
 *                 description: Duration in milliseconds for voice messages
 *               receipts:
 *                 type: array
 *                 items:
 *                   $ref: '#/components/schemas/MessageReceipt'
 *           example:
 *             senderId: "+919876543210"
 *             type: "text"
 *             text: "Hello, how are you?"
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required: [senderId, type]
 *             properties:
 *               _id:
 *                 type: string
 *                 description: Message ID (optional - will be auto-generated if not provided)
 *               senderId:
 *                 type: string
 *                 description: Profile _id (E.164 phone)
 *                 example: "+919876543210"
 *               type:
 *                 type: string
 *                 enum: [text, image, voice, media]
 *                 description: Message type. Use "media" for any file type (images, videos, documents, etc.)
 *               text:
 *                 type: string
 *                 description: Optional message text/caption
 *               media:
 *                 type: string
 *                 format: binary
 *                 description: Media file (any type - image, video, audio, document, etc.)
 *               mediaMimeType:
 *                 type: string
 *                 description: Optional MIME type hint (auto-detected from file if not provided)
 *                 example: "image/jpeg"
 *               voiceDurationMs:
 *                 type: integer
 *                 description: Duration in milliseconds for voice messages
 *               receipts:
 *                 type: string
 *                 description: JSON string array of receipts (optional)
 *           examples:
 *             textWithImage:
 *               summary: Send a text message with an image
 *               value:
 *                 senderId: "+919876543210"
 *                 type: "media"
 *                 text: "Check out this photo!"
 *                 media: "(binary)"
 *                 mediaMimeType: "image/jpeg"
 *             voiceMessage:
 *               summary: Send a voice message
 *               value:
 *                 senderId: "+919876543210"
 *                 type: "voice"
 *                 media: "(binary)"
 *                 mediaMimeType: "audio/mpeg"
 *                 voiceDurationMs: 5000
 *     responses:
 *       201:
 *         description: Message created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Message'
 *       400:
 *         description: Bad request - missing required fields
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Server error during media upload
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
export async function sendMessageHandler(req: Request, res: Response) {
  const file = (req as any).file as Express.Multer.File | undefined;
  const conversationId = req.params.id; // Get conversation ID from URL path parameter
  const body = req.body as Partial<MessageDoc> & { _id?: string; senderId?: string; type?: string; text?: string; mediaMimeType?: string; voiceDurationMs?: number; receipts?: any[] };
  
  if (!conversationId || !body?.senderId || !body?.type) {
    return res.status(400).json({ ok: false, error: "conversationId (from URL), senderId, type required" });
  }

  // Auto-generate message ID if not provided
  const messageId = body._id || new ObjectId().toString();

  // If there's a media file, upload it to GridFS
  if (file) {
    const bucket = getMediaBucket();
    const uploadStream = bucket.openUploadStream(file.originalname || "media", {
      contentType: file.mimetype || body.mediaMimeType || "application/octet-stream",
      metadata: { sizeBytes: file.size },
    });
    uploadStream.end(file.buffer);
    
    uploadStream.on("error", (err) => {
      return res.status(500).json({ ok: false, error: err.message });
    });
    
    uploadStream.on("finish", async () => {
      const fileId = String(uploadStream.id);
      const mediaUrl = `/api/v1/media/${fileId}/stream`;
      
      const created = await sendMessage({
        _id: messageId,
        conversationId,
        senderId: body.senderId!,
        type: body.type!,
        text: body.text,
        mediaUrl,
        mediaMimeType: file.mimetype || body.mediaMimeType,
        voiceDurationMs: body.voiceDurationMs,
        receipts: body.receipts || [],
      } as any);
      res.status(201).json(created);
    });
  } else {
    // No media file, use existing logic
    const created = await sendMessage({
      _id: messageId,
      conversationId,
      senderId: body.senderId!,
      type: body.type!,
      text: body.text,
      mediaUrl: body.mediaUrl,
      mediaMimeType: body.mediaMimeType,
      voiceDurationMs: body.voiceDurationMs,
      receipts: body.receipts || [],
    } as any);
    res.status(201).json(created);
  }
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
  *               userId: { type: string, example: +919876543210, description: Profile _id (E.164 phone) }
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

/**
 * @swagger
 * /api/v1/chats/media/stream:
 *   get:
 *     summary: Get media file by media URL
 *     description: |
 *       Stream a media file from a message's mediaUrl. 
 *       The mediaUrl should be in the format: `/api/v1/media/{fileId}/stream`
 *       This endpoint extracts the fileId from the mediaUrl and streams the file.
 *     tags: [Messages]
 *     parameters:
 *       - in: query
 *         name: mediaUrl
 *         required: true
 *         schema:
 *           type: string
 *         description: Media URL from a message (e.g., /api/v1/media/6910e7deb523b1a429a144a4/stream)
 *         example: "/api/v1/media/6910e7deb523b1a429a144a4/stream"
 *     responses:
 *       200:
 *         description: Media file stream
 *         content:
 *           application/octet-stream:
 *             schema:
 *               type: string
 *               format: binary
 *       206:
 *         description: Partial content (for range requests)
 *       400:
 *         description: Bad request - mediaUrl is required or invalid format
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Media file not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
export async function getMediaByUrlHandler(req: Request, res: Response) {
  const mediaUrl = req.query.mediaUrl as string | undefined;
  
  if (!mediaUrl) {
    return res.status(400).json({ ok: false, error: "mediaUrl query parameter is required" });
  }

  // Extract fileId from mediaUrl format: /api/v1/media/{fileId}/stream
  const urlMatch = mediaUrl.match(/\/api\/v1\/media\/([^\/]+)\/stream/);
  if (!urlMatch || !urlMatch[1]) {
    return res.status(400).json({ ok: false, error: "Invalid mediaUrl format. Expected format: /api/v1/media/{fileId}/stream" });
  }

  const fileId = urlMatch[1];
  
  try {
    const objId = new ObjectId(fileId);
    const audioBucket = getAudioBucket();
    const videoBucket = getVideoBucket();
    const mediaBucket = getMediaBucket();

    // Try to find the file in audio, video, or media buckets
    const audioMeta = await (audioBucket as any).s.db.collection((audioBucket as any).s.options.bucketName + ".files").findOne({ _id: objId });
    const videoMeta = !audioMeta ? await (videoBucket as any).s.db.collection((videoBucket as any).s.options.bucketName + ".files").findOne({ _id: objId }) : null;
    const mediaMeta = !audioMeta && !videoMeta ? await (mediaBucket as any).s.db.collection((mediaBucket as any).s.options.bucketName + ".files").findOne({ _id: objId }) : null;
    
    const meta = audioMeta || videoMeta || mediaMeta;
    const bucket = audioMeta ? audioBucket : videoMeta ? videoBucket : mediaMeta ? mediaBucket : null;

    if (!bucket || !meta) {
      return res.status(404).json({ ok: false, error: "Media file not found" });
    }

    const total = Number(meta.length || meta.chunkSize);
    const contentType = meta.contentType || (bucket === audioBucket ? "audio/mpeg" : bucket === videoBucket ? "video/mp4" : "application/octet-stream");
    
    res.setHeader("Accept-Ranges", "bytes");
    res.setHeader("Content-Type", contentType);

    const range = req.headers.range;
    if (range) {
      const [startStr, endStr] = range.replace(/bytes=/, "").split("-");
      const start = parseInt(startStr, 10);
      const end = endStr ? parseInt(endStr, 10) : total - 1;
      const chunkSize = end - start + 1;
      res.status(206);
      res.setHeader("Content-Range", `bytes ${start}-${end}/${total}`);
      res.setHeader("Content-Length", String(chunkSize));
      const stream = bucket.openDownloadStream(objId, { start, end: end + 1 });
      stream.on("error", () => res.end());
      stream.pipe(res);
    } else {
      res.setHeader("Content-Length", String(total));
      const stream = bucket.openDownloadStream(objId);
      stream.on("error", () => res.end());
      stream.pipe(res);
    }
  } catch (error: any) {
    return res.status(400).json({ ok: false, error: `Invalid file ID: ${error.message}` });
  }
}


