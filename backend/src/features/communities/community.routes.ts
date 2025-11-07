import { Router } from "express";
import {
  handleGetCommunities,
  handleGetCommunity,
} from "./community.controller.js";

const router = Router();

// GET /api/v1/communities - Get all communities
router.get("/", handleGetCommunities);

// GET /api/v1/communities/:id - Get a specific community
router.get("/:id", handleGetCommunity);

export default router;



