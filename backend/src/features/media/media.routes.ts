import { Router } from "express";
import multer from "multer";
import { handleUploadAudio, handleUploadVideo, handleStreamMedia, handleStreamMediaByThought } from "./media.controller.js";

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 50 * 1024 * 1024 } });

const router = Router();

router.post("/audio", upload.single("file"), handleUploadAudio);
router.post("/video", upload.single("file"), handleUploadVideo);
router.get("/:fileId/stream", handleStreamMedia);
router.get("/by-thought/:thoughtId/stream", handleStreamMediaByThought);

export default router;


