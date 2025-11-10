import { Router } from "express";
import newsRouter from "../features/news/news.routes.js";
import usersRouter from "../features/users/user.routes.js";
import profilesRouter from "../features/profiles/profile.routes.js";
import chatsRouter from "../features/chats/chat.routes.js";
import communityRouter from "../features/community/post.routes.js";

const router = Router();

router.use("/news", newsRouter);
router.use("/users", usersRouter);
router.use("/chats", chatsRouter);
router.use("/community", communityRouter);
router.use("/profiles", profilesRouter);

export default router;


