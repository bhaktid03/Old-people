import { Request, Response } from "express";
import { createV2Post, getV2Post, listV2Posts } from "./postV2.repo.js";
import type { V2AuthorSnapshot, V2MediaItem } from "./postV2.types.js";
import { getProfile } from "../profiles/profile.repo.js";
import { getAudioBucket, getImageBucket, getVideoBucket } from "../../config/gridfs.js";
import { ObjectId } from "mongodb";

function makeStreamUrl(type: "image" | "audio" | "video", fileId: string) {
  return `/api/v1/media-v2/${type}/${fileId}/stream`;
}

/**
 * @swagger
 * tags:
 *   - name: CommunityV2
 *     description: Community V2 posts supporting any combination of text, photo, audio, and video
 */

/**
 * @swagger
 * /api/v1/community-v2/posts:
 *   post:
 *     summary: Create a V2 post with any combination of text, images, audio, and videos
 *     description: "Multipart form with fields: text (string), images[] (binary), audio[] (binary), videos[] (binary)"
 *     tags: [CommunityV2]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               userId: { type: string }
 *               text: { type: string }
 *               images: { type: array, items: { type: string, format: binary } }
 *               audio: { type: array, items: { type: string, format: binary } }
 *               videos: { type: array, items: { type: string, format: binary } }
 *     responses:
 *       201:
 *         description: Created. The response includes the backend-generated post id in the `_id` field.
 */
export async function createV2PostHandler(req: Request, res: Response) {
  const body = req.body as any;
  const files = (req as any).files as Record<string, Express.Multer.File[]> | undefined;
  const { userId } = body;
  if (!userId) return res.status(400).json({ ok: false, error: "userId is required" });
  const generatedId = new ObjectId().toString();

  const profile = await getProfile(userId);
  const author: V2AuthorSnapshot = { userId, displayName: profile?.displayName, imageUrl: profile?.imageUrl };

  const mediaItems: V2MediaItem[] = [];

  const saveOne = (file: Express.Multer.File, kind: "image" | "audio" | "video") => new Promise<V2MediaItem>((resolve, reject) => {
    const bucket = kind === "image" ? getImageBucket() : kind === "audio" ? getAudioBucket() : getVideoBucket();
    const uploadStream = bucket.openUploadStream(file.originalname || kind, {
      contentType: file.mimetype,
      metadata: { sizeBytes: file.size, kind, source: "community-v2" },
    });
    uploadStream.on("error", (e) => reject(e));
    uploadStream.on("finish", () => {
      const fileId = String(uploadStream.id);
      resolve({ type: kind, fileId, contentType: file.mimetype, streamUrl: makeStreamUrl(kind, fileId) });
    });
    uploadStream.end(file.buffer);
  });

  try {
    const promises: Promise<V2MediaItem>[] = [];
    (files?.images || []).forEach((f) => promises.push(saveOne(f, "image")));
    (files?.audio || []).forEach((f) => promises.push(saveOne(f, "audio")));
    (files?.videos || []).forEach((f) => promises.push(saveOne(f, "video")));
    const uploaded = await Promise.all(promises);
    uploaded.forEach((m) => mediaItems.push(m));
  } catch (e: any) {
    return res.status(500).json({ ok: false, error: e?.message || "media upload failed" });
  }

  const doc = await createV2Post({ _id: generatedId, author, text: body.text, media: mediaItems } as any);
  return res.status(201).json(doc);
}

/**
 * @swagger
 * /api/v1/community-v2/posts:
 *   get:
 *     summary: List V2 posts
 *     tags: [CommunityV2]
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200: { description: OK }
 */
export async function listV2PostsHandler(req: Request, res: Response) {
  const limit = req.query.limit ? Math.min(Number(req.query.limit), 50) : 20;
  const data = await listV2Posts(limit);
  res.json({ data });
}

/**
 * @swagger
 * /api/v1/community-v2/posts/{postId}:
 *   get:
 *     summary: Get a V2 post
 *     tags: [CommunityV2]
 */
export async function getV2PostHandler(req: Request, res: Response) {
  const post = await getV2Post(req.params.postId);
  if (!post) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(post);
}


