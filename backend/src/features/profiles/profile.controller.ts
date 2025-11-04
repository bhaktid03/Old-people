import { Request, Response } from "express";
import { getProfile, upsertProfile } from "./profile.repo.js";
import { logger } from "../../services/logger.js";

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
 *           format: uri
 *           description: HTTPS URL of the user's profile image
 *         language:
 *           type: string
 *           description: ISO 639-1 code, e.g., 'hi', 'en'
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
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
 *               $ref: '#/components/schemas/Profile'
 *       404:
 *         description: Not found
 */
export async function getProfileHandler(req: Request, res: Response) {
  const userId = String(req.params.userId);
  const profile = await getProfile(userId);
  if (!profile) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(profile);
}

/**
 * @swagger
 * /api/v1/profiles/{userId}:
 *   put:
 *     summary: Create or update a user's profile
 *     description: Stores display name and an HTTPS image URL. Upload your image elsewhere first and pass its HTTPS URL here.
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
 *               $ref: '#/components/schemas/Profile'
 */
export async function upsertProfileHandler(req: Request, res: Response) {
  const userId = String(req.params.userId);
  const { displayName, imageUrl, language } = req.body as { displayName?: string; imageUrl?: string; language?: string };

  if (imageUrl && !isHttpsUrl(String(imageUrl))) {
    return res.status(400).json({ ok: false, error: "imageUrl must be a valid HTTPS URL" });
  }

  const profile = await upsertProfile(userId, { displayName, imageUrl, language } as any);
  logger.info({ userId }, "profile_upserted");
  res.json(profile);
}


