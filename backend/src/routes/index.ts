import { Router } from "express";
import newsRouter from "../features/news/news.routes.js";

const router = Router();

router.use("/news", newsRouter);

export default router;


