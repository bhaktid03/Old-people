import { Request, Response } from "express";
import { ObjectId } from "mongodb";
import { getAudioBucket, getVideoBucket, getImageBucket } from "../../config/gridfs.js";

type UploadedSummary = { type: "image" | "audio" | "video"; fileId: string; contentType: string; sizeBytes: number };

/**
 * @swagger
 * /api/v1/media-v2/upload:
 *   post:
 *     summary: Upload any combination of images, audio, and videos
 *     description: "Accepts multipart/form-data with arrays: images[], audio[], videos[]. Returns fileIds and metadata."
 *     tags: [MediaV2]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               images:
 *                 type: array
 *                 items: { type: string, format: binary }
 *               audio:
 *                 type: array
 *                 items: { type: string, format: binary }
 *               videos:
 *                 type: array
 *                 items: { type: string, format: binary }
 *     responses:
 *       200:
 *         description: Upload successful
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 files:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       type: { type: string, enum: [image,audio,video] }
 *                       fileId: { type: string }
 *                       contentType: { type: string }
 *                       sizeBytes: { type: number }
 */
export async function uploadAnyHandler(req: Request, res: Response) {
  const files = (req as any).files as Record<string, Express.Multer.File[]> | undefined;
  const out: UploadedSummary[] = [];
  if (!files || (Object.keys(files).length === 0)) return res.status(400).json({ error: "no files provided" });

  const saveOne = (file: Express.Multer.File, kind: "image" | "audio" | "video") => new Promise<UploadedSummary>((resolve, reject) => {
    const bucket = kind === "image" ? getImageBucket() : kind === "audio" ? getAudioBucket() : getVideoBucket();
    const uploadStream = bucket.openUploadStream(file.originalname || kind, {
      contentType: file.mimetype,
      metadata: { sizeBytes: file.size, kind },
    });
    uploadStream.on("error", (e) => reject(e));
    uploadStream.on("finish", () => resolve({ type: kind, fileId: String(uploadStream.id), contentType: file.mimetype, sizeBytes: file.size }));
    uploadStream.end(file.buffer);
  });

  try {
    const promises: Promise<UploadedSummary>[] = [];
    (files.images || []).forEach((f) => promises.push(saveOne(f, "image")));
    (files.audio || []).forEach((f) => promises.push(saveOne(f, "audio")));
    (files.videos || []).forEach((f) => promises.push(saveOne(f, "video")));
    const uploaded = await Promise.all(promises);
    uploaded.forEach((u) => out.push(u));
    return res.json({ files: out });
  } catch (e: any) {
    return res.status(500).json({ error: e?.message || "upload failed" });
  }
}

/**
 * @swagger
 * /api/v1/media-v2/{type}/{fileId}/stream:
 *   get:
 *     summary: Stream media (image/audio/video) by type and fileId
 *     tags: [MediaV2]
 *     parameters:
 *       - in: path
 *         name: type
 *         schema: { type: string, enum: [image,audio,video] }
 *         required: true
 *       - in: path
 *         name: fileId
 *         schema: { type: string }
 *         required: true
 *     responses:
 *       200: { description: Streamed }
 *       404: { description: Not found }
 */
export async function streamByTypeHandler(req: Request, res: Response) {
  const { type, fileId } = req.params as { type: "image" | "audio" | "video"; fileId: string };
  if (!fileId || !type) return res.status(400).json({ error: "type and fileId required" });

  const bucket = type === "image" ? getImageBucket() : type === "audio" ? getAudioBucket() : getVideoBucket();
  const objId = new ObjectId(fileId);
  const meta = await bucket.s.db.collection(bucket.s.options.bucketName + ".files").findOne({ _id: objId });
  if (!meta) return res.status(404).json({ error: "file not found" });

  const total = Number((meta as any).length || (meta as any).chunkSize || 0);
  const defaultType = type === "image" ? "image/jpeg" : type === "audio" ? "audio/mpeg" : "video/mp4";
  const contentType = (meta as any).contentType || defaultType;
  res.setHeader("Accept-Ranges", "bytes");
  res.setHeader("Content-Type", contentType);

  const range = req.headers.range;
  if (range && type !== "image" && total > 0) {
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

  if (total > 0) res.setHeader("Content-Length", String(total));
  const stream = bucket.openDownloadStream(objId);
  stream.on("error", () => res.end());
  return stream.pipe(res);
}


