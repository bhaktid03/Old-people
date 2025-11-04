import { Request, Response } from "express";
import {
  createThought,
  getThought,
  getThoughts,
  deleteThought as serviceDeleteThought,
  updateThought as serviceUpdateThought,
} from "./thoughts.service.js";
import { ThoughtType, ThoughtContent } from "./thoughts.types.js";

/**
 * @swagger
 * /api/v1/thoughts:
 *   post:
 *     summary: Create a new thought/comment on a news article
 *     description: Users can share their thoughts on news via text, audio, or video
 *     tags:
 *       - Thoughts
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - newsUrl
 *               - userId
 *               - contentType
 *               - content
 *             properties:
 *               newsUrl:
 *                 type: string
 *                 description: URL of the news article (from NewsItem.url in /api/v1/news)
 *               userId:
 *                 type: string
 *                 description: ID of the user creating the thought
 *               contentType:
 *                 type: string
 *                 enum: [text, audio, video]
 *                 description: Type of content
 *               content:
 *                 type: object
 *                 description: Content object based on contentType
 *           examples:
 *             textExample:
 *               summary: Create a text thought
 *               value:
 *                 newsUrl: "https://indianexpress.com/?post_type=article&p=10344967-10344967/"
 *                 userId: "user_123"
 *                 contentType: "text"
 *                 content:
 *                   type: "text"
 *                   text: "My thought about this article"
 *             audioWithFileId:
 *               summary: Create an audio thought using uploaded fileId (GridFS)
 *               value:
 *                 newsUrl: "https://indianexpress.com/?post_type=article&p=10344967-10344967/"
 *                 userId: "user_123"
 *                 contentType: "audio"
 *                 content:
 *                   type: "audio"
 *                   audioFileId: "66ff1c1e2f1a4d1f9e6b1234"
 *             audioWithUrl:
 *               summary: Create an audio thought using external URL (optional)
 *               value:
 *                 newsUrl: "https://indianexpress.com/?post_type=article&p=10344967-10344967/"
 *                 userId: "user_123"
 *                 contentType: "audio"
 *                 content:
 *                   type: "audio"
 *                   audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
 *             audioCreateFirst:
 *               summary: Create an audio thought first (no file yet)
 *               value:
 *                 newsUrl: "https://indianexpress.com/?post_type=article&p=10344967-10344967/"
 *                 userId: "user_123"
 *                 contentType: "audio"
 *                 content:
 *                   type: "audio"
 *             videoWithFileId:
 *               summary: Create a video thought using uploaded fileId (GridFS)
 *               value:
 *                 newsUrl: "https://indianexpress.com/?post_type=article&p=10344967-10344967/"
 *                 userId: "user_123"
 *                 contentType: "video"
 *                 content:
 *                   type: "video"
 *                   videoFileId: "66ff1c1e2f1a4d1f9e6b5678"
 *             videoWithUrl:
 *               summary: Create a video thought using external URL (optional)
 *               value:
 *                 newsUrl: "https://indianexpress.com/?post_type=article&p=10344967-10344967/"
 *                 userId: "user_123"
 *                 contentType: "video"
 *                 content:
 *                   type: "video"
 *                   videoUrl: "https://example.com/sample.mp4"
 *             videoCreateFirstThenUpload:
 *               summary: Create a video thought first (no file yet)
 *               value:
 *                 newsUrl: "https://indianexpress.com/?post_type=article&p=10344967-10344967/"
 *                 userId: "user_123"
 *                 contentType: "video"
 *                 content:
 *                   type: "video"
 *             audioCreateFirstThenUpload:
 *               summary: Create an audio thought first (no file yet)
 *               value:
 *                 newsUrl: "https://indianexpress.com/?post_type=article&p=10344967-10344967/"
 *                 userId: "user_123"
 *                 contentType: "audio"
 *                 content:
 *                   type: "audio"
 *     responses:
 *       201:
 *         description: Thought created successfully
 *       400:
 *         description: Invalid input
 */
export async function handleCreateThought(req: Request, res: Response) {
  const { newsUrl, userId, contentType, content } = req.body;

  if (!newsUrl || !userId || !contentType || !content) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  // Validate that newsUrl is a valid URL
  try {
    new URL(newsUrl);
  } catch {
    return res.status(400).json({ error: "newsUrl must be a valid URL" });
  }

  if (!["text", "audio", "video"].includes(contentType)) {
    return res.status(400).json({ error: "Invalid contentType. Must be text, audio, or video" });
  }

  // Validate content structure based on type
  if (contentType === "text" && !content.text) {
    return res.status(400).json({ error: "Text content requires 'text' field" });
  }
  // For audio/video allow initial creation without URL/fileId; media can be attached later
  // if (contentType === "audio" && !content.audioUrl) {
  //   return res.status(400).json({ error: "Audio content requires 'audioUrl' field" });
  // }
  // if (contentType === "video" && !content.videoUrl) {
  //   return res.status(400).json({ error: "Video content requires 'videoUrl' field" });
  // }

  try {
    const thought = await createThought({
      newsUrl: String(newsUrl),
      userId: String(userId),
      contentType: contentType as ThoughtType,
      content: content as ThoughtContent,
    });

    return res.status(201).json({ data: thought });
  } catch (error: any) {
    return res.status(400).json({ error: error.message || "Failed to create thought" });
  }
}

/**
 * @swagger
 * /api/v1/thoughts/{id}:
 *   get:
 *     summary: Get a specific thought by ID
 *     tags:
 *       - Thoughts
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Thought found
 *       404:
 *         description: Thought not found
 */
export async function handleGetThought(req: Request, res: Response) {
  const { id } = req.params;

  const thought = await getThought(id);
  if (!thought) {
    return res.status(404).json({ error: "Thought not found" });
  }

  return res.json({ data: thought });
}

/**
 * @swagger
 * /api/v1/thoughts:
 *   get:
 *     summary: Get thoughts/comments
 *     description: Get thoughts by newsUrl or userId
 *     tags:
 *       - Thoughts
 *     parameters:
 *       - in: query
 *         name: newsUrl
 *         schema:
 *           type: string
 *         description: Filter by news article URL
 *       - in: query
 *         name: userId
 *         schema:
 *           type: string
 *         description: Filter by user ID
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Maximum number of thoughts to return
 *       - in: query
 *         name: skip
 *         schema:
 *           type: integer
 *           default: 0
 *         description: Number of thoughts to skip
 *     responses:
 *       200:
 *         description: List of thoughts
 */
export async function handleGetThoughts(req: Request, res: Response) {
  const { newsUrl, userId, limit, skip } = req.query;

  if (!newsUrl && !userId) {
    return res.status(400).json({ error: "Either newsUrl or userId must be provided" });
  }

  try {
    const thoughts = await getThoughts({
      newsUrl: newsUrl ? String(newsUrl) : undefined,
      userId: userId ? String(userId) : undefined,
      limit: limit ? Number(limit) : undefined,
      skip: skip ? Number(skip) : undefined,
    });

    return res.json({ data: thoughts });
  } catch (error: any) {
    return res.status(400).json({ error: error.message || "Failed to fetch thoughts" });
  }
}

/**
 * @swagger
 * /api/v1/thoughts/{id}:
 *   delete:
 *     summary: Delete a thought
 *     description: Only the owner can delete their thought
 *     tags:
 *       - Thoughts
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID of the thought owner
 *     responses:
 *       200:
 *         description: Thought deleted successfully
 *       403:
 *         description: Not authorized to delete this thought
 *       404:
 *         description: Thought not found
 */
export async function handleDeleteThought(req: Request, res: Response) {
  const { id } = req.params;
  const userId = req.query.userId || req.body.userId;

  if (!userId) {
    return res.status(400).json({ error: "userId is required" });
  }

  const deleted = await serviceDeleteThought(id, String(userId));
  if (!deleted) {
    return res.status(404).json({ error: "Thought not found or not authorized" });
  }

  return res.json({ ok: true });
}

/**
 * @swagger
 * /api/v1/thoughts/{id}:
 *   put:
 *     summary: Update a thought
 *     description: Only the owner can update their thought
 *     tags:
 *       - Thoughts
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - userId
 *               - content
 *             properties:
 *               userId:
 *                 type: string
 *               content:
 *                 type: object
 *     responses:
 *       200:
 *         description: Thought updated successfully
 *       403:
 *         description: Not authorized to update this thought
 *       404:
 *         description: Thought not found
 */
export async function handleUpdateThought(req: Request, res: Response) {
  const { id } = req.params;
  const { userId, content } = req.body;

  if (!userId || !content) {
    return res.status(400).json({ error: "userId and content are required" });
  }

  try {
    const thought = await serviceUpdateThought(id, String(userId), { content });
    if (!thought) {
      return res.status(404).json({ error: "Thought not found or not authorized" });
    }

    return res.json({ data: thought });
  } catch (error: any) {
    return res.status(400).json({ error: error.message || "Failed to update thought" });
  }
}

