import { Router } from "express";
import newsRouter from "../features/news/news.routes.js";
import mediaRouter from "../features/media/media.routes.js";
import thoughtsRouter from "../features/thoughts/thoughts.routes.js";
import usersRouter from "../features/users/user.routes.js";
import profilesRouter from "../features/profiles/profile.routes.js";

const router = Router();

router.use("/news", newsRouter);
router.use("/media", mediaRouter);
router.use("/thoughts", thoughtsRouter);
router.use("/users", usersRouter);
router.use("/profiles", profilesRouter);
export default router;


