import { Router } from "express";
import newsRouter from "../features/news/news.routes.js";
import mediaRouter from "../features/media/media.routes.js";
import mediaV2Router from "../features/media-v2/mediaV2.routes.js";
import thoughtsRouter from "../features/thoughts/thoughts.routes.js";
import usersRouter from "../features/users/user.routes.js";
import profilesRouter from "../features/profiles/profile.routes.js";
import chatsRouter from "../features/chats/chat.routes.js";
import communityV2Router from "../features/community-v2/postV2.routes.js";

const router = Router();

router.use("/news", newsRouter);
router.use("/media", mediaRouter);
router.use("/media-v2", mediaV2Router);
router.use("/community-v2", communityV2Router);
router.use("/thoughts", thoughtsRouter);
router.use("/users", usersRouter);
router.use("/profiles", profilesRouter);
router.use("/chats", chatsRouter);
export default router;


