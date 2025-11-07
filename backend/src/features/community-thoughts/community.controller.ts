import { Request, Response } from "express";
import {
  createCommunityThought,
  getCommunityThought,
  getCommunityThoughts,
  deleteCommunityThought as serviceDeleteCommunityThought,
  updateCommunityThought as serviceUpdateCommunityThought,
  respectCommunityThought as serviceRespectCommunityThought,
  unrespectCommunityThought as serviceUnrespectCommunityThought,
} from "./community.service.js";
import { CommunityThoughtType, CommunityThoughtContent } from "./community.types.js";

export async function handleCreateCommunityThought(req: Request, res: Response) {
  const { communityId, userId, contentType, content } = req.body;

  if (!communityId || !userId || !contentType || !content) {
    return res.status(400).json({ error: "Missing required fields" });
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
    const thought = await createCommunityThought({
      communityId: String(communityId),
      userId: String(userId),
      contentType: contentType as CommunityThoughtType,
      content: content as CommunityThoughtContent,
    });

    return res.status(201).json({ data: thought });
  } catch (error: any) {
    return res.status(400).json({ error: error.message || "Failed to create community thought" });
  }
}

export async function handleGetCommunityThought(req: Request, res: Response) {
  const { id } = req.params;

  const thought = await getCommunityThought(id);
  if (!thought) {
    return res.status(404).json({ error: "Community thought not found" });
  }

  return res.json({ data: thought });
}

export async function handleGetCommunityThoughts(req: Request, res: Response) {
  const { communityId, userId, limit, skip } = req.query;

  try {
    const thoughts = await getCommunityThoughts({
      communityId: communityId ? String(communityId) : undefined,
      userId: userId ? String(userId) : undefined,
      limit: limit ? Number(limit) : undefined,
      skip: skip ? Number(skip) : undefined,
    });

    return res.json({ data: thoughts });
  } catch (error: any) {
    return res.status(400).json({ error: error.message || "Failed to fetch community thoughts" });
  }
}

export async function handleDeleteCommunityThought(req: Request, res: Response) {
  const { id } = req.params;
  const userId = req.query.userId || req.body.userId;

  if (!userId) {
    return res.status(400).json({ error: "userId is required" });
  }

  const deleted = await serviceDeleteCommunityThought(id, String(userId));
  if (!deleted) {
    return res.status(404).json({ error: "Community thought not found or not authorized" });
  }

  return res.json({ ok: true });
}

export async function handleUpdateCommunityThought(req: Request, res: Response) {
  const { id } = req.params;
  const { userId, content } = req.body;

  if (!userId || !content) {
    return res.status(400).json({ error: "userId and content are required" });
  }

  try {
    const thought = await serviceUpdateCommunityThought(id, String(userId), { content });
    if (!thought) {
      return res.status(404).json({ error: "Community thought not found or not authorized" });
    }

    return res.json({ data: thought });
  } catch (error: any) {
    return res.status(400).json({ error: error.message || "Failed to update community thought" });
  }
}

export async function handleRespectCommunityThought(req: Request, res: Response) {
  const { id } = req.params;
  const { userId } = req.body;
  if (!userId) return res.status(400).json({ error: "userId is required" });
  const thought = await serviceRespectCommunityThought(id, String(userId));
  if (!thought) return res.status(404).json({ error: "Community thought not found" });
  return res.json({ data: thought });
}

export async function handleUnrespectCommunityThought(req: Request, res: Response) {
  const { id } = req.params;
  const { userId } = req.body;
  if (!userId) return res.status(400).json({ error: "userId is required" });
  const thought = await serviceUnrespectCommunityThought(id, String(userId));
  if (!thought) return res.status(404).json({ error: "Community thought not found" });
  return res.json({ data: thought });
}

