import { Router } from "express";
import multer from "multer";
import { createV2PostHandler, getV2PostHandler, listV2PostsHandler } from "./postV2.controller.js";

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 50 * 1024 * 1024 } });

const router = Router();

router.post(
  "/posts",
  upload.fields([
    { name: "images", maxCount: 10 },
    { name: "audio", maxCount: 5 },
    { name: "videos", maxCount: 5 },
  ]),
  createV2PostHandler
);

router.get("/posts", listV2PostsHandler);
router.get("/posts/:postId", getV2PostHandler);

export default router;


