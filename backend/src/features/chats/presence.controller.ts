import { Request, Response } from "express";
import { getUserById, updateUser } from "../users/user.repo.js";
import { setUserPresence } from "../users/user.repo.js";

export async function setPresenceHandler(req: Request, res: Response) {
  const { userId, online } = req.body as { userId: string; online: boolean };
  if (!userId || typeof online !== "boolean") return res.status(400).json({ ok: false, error: "userId and online required" });
  const updated = await setUserPresence(userId, online);
  if (!updated) return res.status(404).json({ ok: false, error: "User not found" });
  res.json(updated);
}

export async function getPresenceHandler(req: Request, res: Response) {
  const userId = req.params.userId;
  const user = await getUserById(userId);
  if (!user) return res.status(404).json({ ok: false, error: "User not found" });
  res.json({ userId, online: !!user.online, lastSeenAt: user.lastSeenAt });
}


