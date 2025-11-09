import { Router } from "express";
import multer from "multer";
import { addMembersHandler, createConversationHandler, deleteMessageAllHandler, deleteMessageForUserHandler, editMessageHandler, getConversationHandler, getMessageHandler, getMediaByUrlHandler, listConversationsHandler, listMessagesHandler, receiptHandler, removeMembersHandler, sendMessageHandler, updateConversationHandler } from "./chat.controller.js";
import { getPresenceHandler, setPresenceHandler } from "./presence.controller.js";

const router = Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 50 * 1024 * 1024 } });

// Conversations
router.post("/conversations", createConversationHandler);
router.get("/conversations", listConversationsHandler);
router.get("/conversations/:id", getConversationHandler);
router.put("/conversations/:id", updateConversationHandler);
router.post("/conversations/:id/members", addMembersHandler);
router.delete("/conversations/:id/members", removeMembersHandler);

// Messages
router.get("/conversations/:id/messages", listMessagesHandler);
router.post("/conversations/:id/messages", upload.single("media"), sendMessageHandler);
router.get("/messages/:messageId", getMessageHandler);
router.put("/messages/:messageId", editMessageHandler);
router.delete("/messages/:messageId", deleteMessageAllHandler);
router.post("/messages/:messageId/deleteForUser", deleteMessageForUserHandler);
router.post("/messages/:messageId/receipt", receiptHandler);

// Media
router.get("/media/stream", getMediaByUrlHandler);

// Presence
router.post("/presence", setPresenceHandler);
router.get("/presence/:userId", getPresenceHandler);

export default router;


