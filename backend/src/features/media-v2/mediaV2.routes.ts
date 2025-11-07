import { Router } from "express";
import multer from "multer";
import { streamByTypeHandler, uploadAnyHandler } from "./mediaV2.controller.js";

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 50 * 1024 * 1024 } });

const router = Router();

// Accept arrays for any of the supported fields
router.post(
  "/upload",
  upload.fields([
    { name: "images", maxCount: 10 },
    { name: "audio", maxCount: 5 },
    { name: "videos", maxCount: 5 },
  ]),
  uploadAnyHandler
);

router.get("/:type/:fileId/stream", streamByTypeHandler);

export default router;


