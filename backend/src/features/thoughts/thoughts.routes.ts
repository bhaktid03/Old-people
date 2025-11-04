import { Router } from "express";
import {
  handleCreateThought,
  handleGetThought,
  handleGetThoughts,
  handleDeleteThought,
  handleUpdateThought,
  handleRespectThought,
  handleUnrespectThought,
} from "./thoughts.controller.js";

const router = Router();

// POST /api/v1/thoughts - Create a new thought/comment on news
router.post("/", handleCreateThought);

// GET /api/v1/thoughts?newsUrl=xxx or ?userId=xxx - Get thoughts by news or user
router.get("/", handleGetThoughts);

// GET /api/v1/thoughts/:id - Get a specific thought
router.get("/:id", handleGetThought);

// PUT /api/v1/thoughts/:id - Update a thought
router.put("/:id", handleUpdateThought);

// DELETE /api/v1/thoughts/:id - Delete a thought
router.delete("/:id", handleDeleteThought);

// POST /api/v1/thoughts/:id/respect - Respect a thought
router.post("/:id/respect", handleRespectThought);

// DELETE /api/v1/thoughts/:id/respect - Remove respect
router.delete("/:id/respect", handleUnrespectThought);

export default router;

