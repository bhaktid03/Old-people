import { Router } from "express";
import { getProfileHandler, upsertProfileHandler } from "./profile.controller.js";

const router = Router();

router.get("/:userId", getProfileHandler);
router.put("/:userId", upsertProfileHandler);

export default router;


