import { Router } from "express";
import { addCommentHandler, createPostHandler, deleteCommentHandler, deletePostHandler, getPostHandler, likePostHandler, listCommentsHandler, listPostsHandler, unlikePostHandler } from "./post.controller.js";

const router = Router();

router.post("/posts", createPostHandler);
router.get("/posts", listPostsHandler);
router.get("/posts/:postId", getPostHandler);
router.delete("/posts/:postId", deletePostHandler);
router.post("/posts/:postId/like", likePostHandler);
router.delete("/posts/:postId/like", unlikePostHandler);
router.get("/posts/:postId/comments", listCommentsHandler);
router.post("/posts/:postId/comments", addCommentHandler);
router.delete("/comments/:commentId", deleteCommentHandler);

export default router;


