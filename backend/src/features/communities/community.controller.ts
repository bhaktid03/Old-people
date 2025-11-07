import { Request, Response } from "express";
import { getCommunities, getCommunity } from "./community.service.js";

export async function handleGetCommunities(req: Request, res: Response) {
  const { limit, skip } = req.query;

  try {
    const communities = await getCommunities({
      limit: limit ? Number(limit) : undefined,
      skip: skip ? Number(skip) : undefined,
    });

    return res.json({ data: communities });
  } catch (error: any) {
    return res.status(400).json({ error: error.message || "Failed to fetch communities" });
  }
}

export async function handleGetCommunity(req: Request, res: Response) {
  const { id } = req.params;

  const community = await getCommunity(id);
  if (!community) {
    return res.status(404).json({ error: "Community not found" });
  }

  return res.json({ data: community });
}

