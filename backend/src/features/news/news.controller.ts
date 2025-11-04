import { Request, Response } from "express";
import { getNews } from "./news.service.js";
import { getUserLanguage } from "../profiles/profile.repo.js";

export async function handleGetNews(req: Request, res: Response) {
  const userId = String(req.query.userId || req.header("x-user-id") || "").trim();
  const provider = String(req.query.source || "indian_express");
  const limit = req.query.limit ? Number(req.query.limit) : 20;

  let targetLang: string | null = null;
  if (userId) {
    try { targetLang = (await getUserLanguage(userId)) || null; } catch { targetLang = null; }
  }

  const items = await getNews({ provider: provider as any, limit, targetLang });
  res.json({ data: items });
}


