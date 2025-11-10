import { Router } from "express";
import { addMembersHandler, createConversationHandler, deleteMessageAllHandler, deleteMessageForUserHandler, editMessageHandler, getConversationHandler, getMessageHandler, listConversationsHandler, listMessagesHandler, receiptHandler, removeMembersHandler, sendMessageHandler, updateConversationHandler } from "./chat.controller.js";
import { getPresenceHandler, setPresenceHandler } from "./presence.controller.js";

const router = Router();

// Conversations
router.post("/conversations", createConversationHandler);
router.get("/conversations", listConversationsHandler);
router.get("/conversations/:id", getConversationHandler);
router.put("/conversations/:id", updateConversationHandler);
router.post("/conversations/:id/members", addMembersHandler);
router.delete("/conversations/:id/members", removeMembersHandler);

// Messages
router.get("/conversations/:id/messages", listMessagesHandler);
router.post("/conversations/:id/messages", sendMessageHandler);
router.get("/messages/:messageId", getMessageHandler);
router.put("/messages/:messageId", editMessageHandler);
router.delete("/messages/:messageId", deleteMessageAllHandler);
router.post("/messages/:messageId/deleteForUser", deleteMessageForUserHandler);
router.post("/messages/:messageId/receipt", receiptHandler);

// Presence
router.post("/presence", setPresenceHandler);
router.get("/presence/:userId", getPresenceHandler);

export default router;


