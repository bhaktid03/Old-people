import { Request, Response } from "express";
import { ObjectId } from "mongodb";
import { getAudioBucket, getVideoBucket } from "../../config/gridfs.js";
import { attachMediaToThought, getThoughtById } from "../thoughts/thoughts.repo.js";

/**
 * @swagger
 * /api/v1/media/audio:
 *   post:
 *     summary: Upload an audio file
 *     tags: [Media]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required: [file]
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *               thoughtId:
 *                 type: string
 *                 description: Optional thoughtId to attach this audio to
 *           examples:
 *             sampleMp3:
 *               summary: Upload a local MP3 file
 *               description: Select a local audio file in the 'file' field
 *     responses:
 *       200:
 *         description: Uploaded
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/MediaUploadResponse'
 */
export async function handleUploadAudio(req: Request, res: Response) {
  const file = (req as any).file as Express.Multer.File | undefined;
  if (!file) return res.status(400).json({ error: "file is required" });
  const thoughtId = (req.body?.thoughtId as string | undefined) || undefined;

  const bucket = getAudioBucket();
  const uploadStream = bucket.openUploadStream(file.originalname || "audio", {
    contentType: file.mimetype || "audio/mpeg",
    metadata: { sizeBytes: file.size },
  });
  uploadStream.end(file.buffer);
  uploadStream.on("error", (err) => res.status(500).json({ error: err.message }));
  uploadStream.on("finish", async () => {
    const fileId = String(uploadStream.id);
    if (thoughtId) {
      try { await attachMediaToThought(thoughtId, "audio", fileId); } catch {}
    }
    return res.json({ fileId, contentType: file.mimetype, sizeBytes: file.size, thoughtId });
  });
}

/**
 * @swagger
 * /api/v1/media/video:
 *   post:
 *     summary: Upload a video file
 *     tags: [Media]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required: [file]
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *               thoughtId:
 *                 type: string
 *                 description: Optional thoughtId to attach this video to
 *           examples:
 *             sampleMp4:
 *               summary: Upload a local MP4 file
 *               description: Select a local video file in the 'file' field
 *     responses:
 *       200:
 *         description: Uploaded
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/MediaUploadResponse'
 */
export async function handleUploadVideo(req: Request, res: Response) {
  const file = (req as any).file as Express.Multer.File | undefined;
  if (!file) return res.status(400).json({ error: "file is required" });
  const thoughtId = (req.body?.thoughtId as string | undefined) || undefined;

  const bucket = getVideoBucket();
  const uploadStream = bucket.openUploadStream(file.originalname || "video", {
    contentType: file.mimetype || "video/mp4",
    metadata: { sizeBytes: file.size },
  });
  uploadStream.end(file.buffer);
  uploadStream.on("error", (err) => res.status(500).json({ error: err.message }));
  uploadStream.on("finish", async () => {
    const fileId = String(uploadStream.id);
    if (thoughtId) {
      try { await attachMediaToThought(thoughtId, "video", fileId); } catch {}
    }
    return res.json({ fileId, contentType: file.mimetype, sizeBytes: file.size, thoughtId });
  });
}

/**
 * @swagger
 * /api/v1/media/{fileId}/stream:
 *   get:
 *     summary: Stream a media file from GridFS
 *     tags: [Media]
 *     parameters:
 *       - in: path
 *         name: fileId
 *         schema: { type: string }
 *         required: true
 *     responses:
 *       200:
 *         description: Stream started
 *       404:
 *         description: File not found
 */
export async function handleStreamMedia(req: Request, res: Response) {
  const { fileId } = req.params;
  if (!fileId) return res.status(400).json({ error: "fileId is required" });

  // Try audio bucket first, then video
  const tryStream = (bucketGetter: () => ReturnType<typeof getAudioBucket>) => {
    try {
      const _id = new ObjectId(fileId);
      const files = (bucketGetter() as any).s.db.collection((bucketGetter() as any).s.options.bucketName + ".files");
      return files.findOne({ _id });
    } catch {
      return null;
    }
  };

  const audioBucket = getAudioBucket();
  const videoBucket = getVideoBucket();
  const objId = new ObjectId(fileId);

  const audioMeta = await audioBucket.s.db.collection(audioBucket.s.options.bucketName + ".files").findOne({ _id: objId });
  const videoMeta = !audioMeta ? await videoBucket.s.db.collection(videoBucket.s.options.bucketName + ".files").findOne({ _id: objId }) : null;
  const meta = audioMeta || videoMeta;
  const bucket = audioMeta ? audioBucket : videoMeta ? videoBucket : null;

  if (!bucket || !meta) return res.status(404).json({ error: "file not found" });

  const total = Number(meta.length || meta.chunkSize); // fallback
  const contentType = meta.contentType || (bucket === audioBucket ? "audio/mpeg" : "video/mp4");
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
}

/**
 * @swagger
 * /api/v1/media/by-thought/{thoughtId}/stream:
 *   get:
 *     summary: Stream media attached to a thought
 *     description: Finds the file attached to the given thought and streams it.
 *     tags: [Media]
 *     parameters:
 *       - in: path
 *         name: thoughtId
 *         schema: { type: string }
 *         required: true
 *     responses:
 *       200:
 *         description: Stream started
 *       404:
 *         description: Thought or media not found
 */
export async function handleStreamMediaByThought(req: Request, res: Response) {
  const { thoughtId } = req.params;
  if (!thoughtId) return res.status(400).json({ error: "thoughtId is required" });

  const thought = await getThoughtById(thoughtId);
  if (!thought) return res.status(404).json({ error: "thought not found" });

  const fileId = (thought.content as any).audioFileId || (thought.content as any).videoFileId || null;
  if (!fileId) return res.status(404).json({ error: "media not attached to this thought" });

  // Stream directly (200) to avoid Swagger redirect issues
  let meta: any | null = null;
  const audioBucket = getAudioBucket();
  const videoBucket = getVideoBucket();
  const objId = new ObjectId(fileId);
  meta = await audioBucket.s.db.collection(audioBucket.s.options.bucketName + ".files").findOne({ _id: objId });
  let bucket = audioBucket;
  if (!meta) {
    meta = await videoBucket.s.db.collection(videoBucket.s.options.bucketName + ".files").findOne({ _id: objId });
    bucket = videoBucket;
  }
  if (!meta) return res.status(404).json({ error: "file not found" });

  const total = Number(meta.length || meta.chunkSize || 0);
  const contentType = meta.contentType || (bucket === audioBucket ? "audio/mpeg" : "video/mp4");
  res.setHeader("Accept-Ranges", "bytes");
  res.setHeader("Content-Type", contentType);

  const range = req.headers.range;
  if (range && total > 0) {
    const [startStr, endStr] = range.replace(/bytes=/, "").split("-");
    const start = parseInt(startStr, 10);
    const end = endStr ? parseInt(endStr, 10) : total - 1;
    const chunkSize = end - start + 1;
    res.status(206);
    res.setHeader("Content-Range", `bytes ${start}-${end}/${total}`);
    res.setHeader("Content-Length", String(chunkSize));
    const stream = bucket.openDownloadStream(objId, { start, end: end + 1 });
    stream.on("error", () => res.end());
    return stream.pipe(res);
  }

  if (total > 0) {
    res.setHeader("Content-Length", String(total));
  }
  const stream = bucket.openDownloadStream(objId);
  stream.on("error", () => res.end());
  return stream.pipe(res);
}


