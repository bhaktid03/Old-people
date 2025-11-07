import { Router } from "express";
import {
  handleCreateCommunityThought,
  handleGetCommunityThought,
  handleGetCommunityThoughts,
  handleDeleteCommunityThought,
  handleUpdateCommunityThought,
  handleRespectCommunityThought,
  handleUnrespectCommunityThought,
} from "./community.controller.js";

const router = Router();

// POST /api/v1/community-thoughts - Create a new thought/comment on a community
router.post("/", handleCreateCommunityThought);

// GET /api/v1/community-thoughts?communityId=xxx or ?userId=xxx - Get thoughts by community or user
router.get("/", handleGetCommunityThoughts);

// GET /api/v1/community-thoughts/:id - Get a specific thought
router.get("/:id", handleGetCommunityThought);

// PUT /api/v1/community-thoughts/:id - Update a thought
router.put("/:id", handleUpdateCommunityThought);

// DELETE /api/v1/community-thoughts/:id - Delete a thought
router.delete("/:id", handleDeleteCommunityThought);

// POST /api/v1/community-thoughts/:id/respect - Respect a thought
router.post("/:id/respect", handleRespectCommunityThought);

// DELETE /api/v1/community-thoughts/:id/respect - Remove respect
router.delete("/:id/respect", handleUnrespectCommunityThought);

export default router;

