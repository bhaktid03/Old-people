import { Request, Response } from "express";
import { addComment, createPost, deleteComment, getPost, likePost, listComments, listPosts, softDeletePost, unlikePost } from "./post.repo.js";
import type { AuthorSnapshot, CommentDoc, PostDoc } from "./post.types.js";
import { getProfile } from "../profiles/profile.repo.js";

/**
 * @swagger
 * tags:
 *   - name: Community
 *     description: Community wall posts, likes, and comments
 */

/**
 * @swagger
 * /api/v1/community/posts:
 *   post:
 *     summary: Create a post (text and optional media)
 *     tags: [Community]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               _id: { type: string }
 *               userId: { type: string, description: 'Author userId' }
 *               text: { type: string }
 *               media: {
 *                 type: array,
 *                 items: { type: object, properties: { type: { type: string, enum: ['image','video','audio'] }, url: { type: 'string', format: 'uri' }, mimeType: { type: 'string' } } }
 *               }
 *     responses:
 *       201:
 *         description: Created
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/CommunityPost'
 */
export async function createPostHandler(req: Request, res: Response) {
  const { _id, userId, text, media } = req.body as { _id: string; userId: string; text?: string; media?: any[] };
  if (!_id || !userId) return res.status(400).json({ ok: false, error: "_id and userId are required" });
  const profile = await getProfile(userId);
  const author: AuthorSnapshot = { userId, displayName: profile?.displayName, imageUrl: profile?.imageUrl };
  const post = await createPost({ _id, author, text, media } as any);
  res.status(201).json(post);
}

/**
 * @swagger
 * /api/v1/community/posts:
 *   get:
 *     summary: List posts
 *     tags: [Community]
 *     parameters:
 *       - in: query
 *         name: sort
 *         schema: { type: string, enum: [recent,trending], default: recent }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200: { description: OK }
 */
export async function listPostsHandler(req: Request, res: Response) {
  const sort = (req.query.sort as any) === "trending" ? "trending" : "recent";
  const limit = req.query.limit ? Math.min(Number(req.query.limit), 50) : 20;
  const data = await listPosts(sort, limit);
  res.json({ data });
}

/**
 * @swagger
 * /api/v1/community/posts/{postId}:
 *   get:
 *     summary: Get a post
 *     tags: [Community]
 */
export async function getPostHandler(req: Request, res: Response) {
  const post = await getPost(req.params.postId);
  if (!post) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(post);
}

/**
 * @swagger
 * /api/v1/community/posts/{postId}:
 *   delete:
 *     summary: Delete post (soft)
 *     tags: [Community]
 */
export async function deletePostHandler(req: Request, res: Response) {
  const ok = await softDeletePost(req.params.postId);
  if (!ok) return res.status(404).json({ ok: false, error: "Not found" });
  res.status(204).send();
}

/**
 * @swagger
 * /api/v1/community/posts/{postId}/like:
 *   post:
 *     summary: Like a post
 *     tags: [Community]
 *   delete:
 *     summary: Unlike a post
 *     tags: [Community]
 */
export async function likePostHandler(req: Request, res: Response) {
  const { userId } = req.body as { userId: string };
  if (!userId) return res.status(400).json({ ok: false, error: "userId required" });
  const post = await likePost(req.params.postId, userId);
  if (!post) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(post);
}
export async function unlikePostHandler(req: Request, res: Response) {
  const { userId } = req.body as { userId: string };
  if (!userId) return res.status(400).json({ ok: false, error: "userId required" });
  const post = await unlikePost(req.params.postId, userId);
  if (!post) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(post);
}

/**
 * @swagger
 * /api/v1/community/posts/{postId}/comments:
 *   get:
 *     summary: List comments
 *     tags: [Community]
 *   post:
 *     summary: Add a comment
 *     tags: [Community]
 */
export async function listCommentsHandler(req: Request, res: Response) {
  const data = await listComments(req.params.postId, req.query.limit ? Number(req.query.limit) : 50);
  res.json({ data });
}

export async function addCommentHandler(req: Request, res: Response) {
  const { _id, userId, text } = req.body as { _id: string; userId: string; text: string };
  if (!_id || !userId || !text) return res.status(400).json({ ok: false, error: "_id, userId and text required" });
  const profile = await getProfile(userId);
  const author: AuthorSnapshot = { userId, displayName: profile?.displayName, imageUrl: profile?.imageUrl };
  const created = await addComment({ _id, postId: req.params.postId, author, text } as any);
  res.status(201).json(created);
}

/**
 * @swagger
 * /api/v1/community/comments/{commentId}:
 *   delete:
 *     summary: Delete a comment
 *     tags: [Community]
 */
export async function deleteCommentHandler(req: Request, res: Response) {
  const ok = await deleteComment(req.params.commentId);
  if (!ok) return res.status(404).json({ ok: false, error: "Not found" });
  res.status(204).send();
}


