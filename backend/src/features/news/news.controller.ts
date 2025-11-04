import { Request, Response } from "express";
import { getNews } from "./news.service.js";
import { getUserLanguage } from "../profiles/profile.repo.js";

/**
 * @swagger
 * /api/v1/news:
 *   get:
 *     summary: Get news articles
 *     description: Fetch news articles from various sources with optional filtering
 *     tags:
 *       - News
 *     parameters:
 *       - in: query
 *         name: userId
 *         schema:
 *           type: string
 *         description: User ID for personalized language preference
 *         required: false
 *       - in: header
 *         name: x-user-id
 *         schema:
 *           type: string
 *         description: User ID from header (alternative to query param)
 *         required: false
 *       - in: query
 *         name: source
 *         schema:
 *           type: string
 *           enum: [indian_express, bbc_hindi, ndtv, toi, the_hindu]
 *           default: indian_express
 *         description: News source provider
 *         required: false
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 50
 *           default: 20
 *         description: Maximum number of articles to return
 *         required: false
 *       - in: query
 *         name: categories
 *         schema:
 *           type: string
 *           description: Comma-separated category names (e.g., "sports,international")
 *         description: Filter by one or more categories
 *         required: false
 *     responses:
 *       200:
 *         description: Successful response with news articles
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/NewsResponse'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
export async function handleGetNews(req: Request, res: Response) {
  const userId = String(req.query.userId || req.header("x-user-id") || "").trim();
  const provider = String(req.query.source || "indian_express");
  const limit = req.query.limit ? Number(req.query.limit) : 20;
  const categoriesParam = String(req.query.categories || "").trim();
  const categories = categoriesParam ? categoriesParam.split(",").map(s => s.trim()).filter(Boolean) : undefined;

  let targetLang: string | null = null;
  if (userId) {
    try { targetLang = (await getUserLanguage(userId)) || null; } catch { targetLang = null; }
  }

  const items = await getNews({ provider: provider as any, limit, targetLang, categories });
  res.json({ data: items });
}


