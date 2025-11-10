import { Router } from "express";
import newsRouter from "../features/news/news.routes.js";
import usersRouter from "../features/users/user.routes.js";
const router = Router();
router.use("/news", newsRouter);
router.use("/users", usersRouter);
export default router;
