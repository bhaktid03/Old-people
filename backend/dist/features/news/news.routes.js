import { Router } from "express";
import { handleGetNews } from "./news.controller.js";
const router = Router();
// GET /api/v1/news?userId=UID&source=indian_express&limit=20
router.get("/", handleGetNews);
export default router;
