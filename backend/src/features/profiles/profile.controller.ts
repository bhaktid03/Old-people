import { Request, Response } from "express";
import { getProfile, upsertProfile } from "./profile.repo.js";
import { logger } from "../../services/logger.js";
import { getImageBucket } from "../../config/gridfs.js";
import { ObjectId } from "mongodb";

function isHttpsUrl(url: string): boolean {
  try {
    const u = new URL(url);
    return u.protocol === "https:";
  } catch {
    return false;
  }
}

/**
 * @swagger
 * components:
 *   schemas:
 *     Profile:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           description: User ID (phone number in E.164)
 *         displayName:
 *           type: string
 *         imageUrl:
 *           type: string
 *           description: HTTPS URL of the user's profile image or relative stream URL returned from uploads
 *         language:
 *           type: string
 *           description: ISO 639-1 code, e.g., 'hi', 'en'
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *     ErrorResponse:
 *       type: object
 *       properties:
 *         ok:
 *           type: boolean
 *           description: Always false for error responses
 *         error:
 *           type: string
 *           description: Error message describing what went wrong
 *       example:
 *         ok: false
 *         error: "imageUrl query parameter is required"
 *     ProfileResponse:
 *       type: object
 *       properties:
 *         ok:
 *           type: boolean
 *         profile:
 *           $ref: '#/components/schemas/Profile'
 *     ProfileUploadInfo:
 *       type: object
 *       properties:
 *         fileId:
 *           type: string
 *         streamUrl:
 *           type: string
 *           description: Relative URL to stream the uploaded image
 *         contentType:
 *           type: string
 *         sizeBytes:
 *           type: number
 *           format: int64
 *     ProfileUpsertResponse:
 *       allOf:
 *         - $ref: '#/components/schemas/ProfileResponse'
 *         - type: object
 *           properties:
 *             uploadedImage:
 *               $ref: '#/components/schemas/ProfileUploadInfo'
 */

/**
 * @swagger
 * /api/v1/profiles/{userId}:
 *   get:
 *     summary: Get a user's profile
 *     tags: [Profiles]
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: The profile document
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ProfileResponse'
 *             example:
 *               ok: true
 *               profile:
 *                 _id: "user123"
 *                 displayName: "Satvik"
 *                 imageUrl: "https://example.com/path/photo.jpg"
 *                 language: "hi"
 *                 createdAt: "2025-11-07T12:02:45.199Z"
 *                 updatedAt: "2025-11-07T12:02:45.199Z"
 *       404:
 *         description: Not found
 */
export async function getProfileHandler(req: Request, res: Response) {
  const userId = String(req.params.userId);
  const profile = await getProfile(userId);
  if (!profile) return res.status(404).json({ ok: false, error: "Not found" });
  res.json({ ok: true, profile });
}

/**
 * @swagger
 * /api/v1/profiles/image:
 *   get:
 *     summary: Stream a profile image by imageUrl
 *     description: Accepts the imageUrl returned by the profiles API and streams the stored image from GridFS.
 *     tags: [Profiles]
 *     parameters:
 *       - in: query
 *         name: imageUrl
 *         required: true
 *         schema:
 *           type: string
 *         description: Value of the imageUrl field from the profile response.
 *     responses:
 *       200:
 *         description: Profile image stream
 *         content:
 *           image/*:
 *             schema:
 *               type: string
 *               format: binary
 *       400:
 *         description: Invalid imageUrl
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Image not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
export async function getProfileImageByUrlHandler(req: Request, res: Response) {
  const raw = req.query.imageUrl;
  if (!raw) return res.status(400).json({ ok: false, error: "imageUrl query parameter is required" });

  let url: URL;
  try {
    url = new URL(String(raw), `${req.protocol}://${req.get("host")}`);
  } catch {
    return res.status(400).json({ ok: false, error: "imageUrl must be a valid URL" });
  }

  const match = url.pathname.match(/^\/api\/v1\/media-v2\/(image)\/([^/]+)\/stream$/);
  if (!match) return res.status(400).json({ ok: false, error: "imageUrl must reference an uploaded profile image" });

  const [, type, fileId] = match;
  if (type !== "image") return res.status(400).json({ ok: false, error: "Only image URLs are supported" });
  if (!ObjectId.isValid(fileId)) return res.status(400).json({ ok: false, error: "Invalid file id" });

  const bucket = getImageBucket();
  const objId = new ObjectId(fileId);
  // @ts-expect-error mongodb types
  const filesCollection = bucket.s.db.collection(bucket.s.options.bucketName + ".files");
  const meta = await filesCollection.findOne({ _id: objId });
  if (!meta) return res.status(404).json({ ok: false, error: "Image not found" });

  const contentType = (meta as any).contentType || "image/jpeg";
  const total = Number((meta as any).length || 0);
  res.setHeader("Content-Type", contentType);
  if (total > 0) res.setHeader("Content-Length", String(total));

  const stream = bucket.openDownloadStream(objId);
  stream.on("error", (err) => {
    logger.error({ err, fileId }, "profile_image_stream_error");
    if (!res.headersSent) {
      res.status(500).json({ ok: false, error: "Unable to stream image" });
    } else {
      res.end();
    }
  });

  return stream.pipe(res);
}

/**
 * @swagger
 * /api/v1/profiles/{userId}:
 *   put:
 *     summary: Create or update a user's profile
 *     description: Stores display name and profile image. You can either provide an HTTPS image URL in JSON or upload an image file via multipart/form-data (a stream URL will be returned).
 *     tags: [Profiles]
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               displayName:
 *                 type: string
 *               language:
 *                 type: string
 *               image:
 *                 type: string
 *                 format: binary
 *                 description: Profile image file
 *               imageUrl:
 *                 type: string
 *                 format: uri
 *                 description: Provide this instead of file to reuse an existing HTTPS image
 *           encoding:
 *             image:
 *               contentType: image/png, image/jpeg, image/webp
 *           example:
 *             displayName: "Grandma Sita"
 *             language: "hi"
 *             image: (binary image data)
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               displayName:
 *                 type: string
 *               imageUrl:
 *                 type: string
 *                 format: uri
 *               language:
 *                 type: string
 *           example:
 *             displayName: "Grandma Sita"
 *             imageUrl: "https://example.com/path/photo.jpg"
 *             language: "hi"
 *     responses:
 *       200:
 *         description: Upserted profile
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ProfileUpsertResponse'
 *             examples:
 *               withUpload:
 *                 summary: Profile updated with uploaded image
 *                 value:
 *                   ok: true
 *                   profile:
 *                     _id: "user123"
 *                     displayName: "Satvik"
 *                     imageUrl: "/api/v1/media-v2/image/abc123/stream"
 *                     language: "hi"
 *                     createdAt: "2025-11-07T12:02:45.199Z"
 *                     updatedAt: "2025-11-07T12:05:12.001Z"
 *                   uploadedImage:
 *                     fileId: "abc123"
 *                     streamUrl: "/api/v1/media-v2/image/abc123/stream"
 *                     contentType: "image/jpeg"
 *                     sizeBytes: 24576
 *               withoutUpload:
 *                 summary: Profile updated using existing HTTPS image URL
 *                 value:
 *                   ok: true
 *                   profile:
 *                     _id: "user123"
 *                     displayName: "Satvik"
 *                     imageUrl: "https://example.com/path/photo.jpg"
 *                     language: "hi"
 *                     createdAt: "2025-11-07T12:02:45.199Z"
 *                     updatedAt: "2025-11-07T12:05:12.001Z"
 */
export async function upsertProfileHandler(req: Request, res: Response) {
  const userId = String(req.params.userId);
  const { displayName, imageUrl, language } = req.body as { displayName?: string; imageUrl?: string; language?: string };

  const file = (req as any).file as Express.Multer.File | undefined;

  try {
    let finalImageUrl = imageUrl;
    let uploadedId: string | undefined;

    if (file) {
      if (!file.mimetype?.startsWith("image/")) {
        return res.status(400).json({ ok: false, error: "Uploaded file must be an image" });
      }

      // Save to GridFS image bucket
      const bucket = getImageBucket();
      const uploadStream = bucket.openUploadStream(file.originalname || "profile-image", {
        contentType: file.mimetype,
        metadata: { sizeBytes: file.size, source: "profile" },
      });

      uploadedId = await new Promise<string>((resolve, reject) => {
        uploadStream.on("error", (e) => reject(e));
        uploadStream.on("finish", () => resolve(String(uploadStream.id)));
        uploadStream.end(file.buffer);
      });

      finalImageUrl = `/api/v1/media-v2/image/${uploadedId}/stream`;
    }

    if (finalImageUrl && !isHttpsUrl(String(finalImageUrl)) && !String(finalImageUrl).startsWith("/")) {
      return res.status(400).json({ ok: false, error: "imageUrl must be a valid HTTPS URL" });
    }

    const profile = await upsertProfile(userId, { displayName, imageUrl: finalImageUrl, language } as any);
    logger.info({ userId }, "profile_upserted");
    res.json({
      ok: true,
      profile,
      uploadedImage: uploadedId
        ? {
            fileId: uploadedId,
            streamUrl: finalImageUrl,
            contentType: file!.mimetype,
            sizeBytes: file!.size,
          }
        : undefined,
    });
  } catch (e: any) {
    return res.status(500).json({ ok: false, error: e?.message || "profile update failed" });
  }
}


