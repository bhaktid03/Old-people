import { Router } from "express";
import multer from "multer";
import { getProfileHandler, getProfileImageByUrlHandler, upsertProfileHandler } from "./profile.controller.js";

const router = Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 20 * 1024 * 1024 } });

router.get("/image", getProfileImageByUrlHandler);
router.get("/:userId", getProfileHandler);
// Accept either JSON body (imageUrl) or multipart/form-data with single `image` file
router.put("/:userId", upload.single("image"), upsertProfileHandler);

export default router;


