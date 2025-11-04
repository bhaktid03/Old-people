import { Router } from "express";
import { createUserHandler, deleteUserHandler, getUserHandler, listUsersHandler, updateUserHandler } from "./user.controller.js";

const router = Router();

router.get("/", listUsersHandler);
router.post("/", createUserHandler);
router.get("/:id", getUserHandler);
router.put("/:id", updateUserHandler);
router.delete("/:id", deleteUserHandler);

export default router;


