export type ConversationType = "solo" | "group";

export type ConversationDoc = {
  _id: string; // conversationId
  type: ConversationType;
  memberIds: string[]; // userIds
  adminIds?: string[]; // for groups
  name?: string; // for groups
  avatarUrl?: string; // optional group avatar
  lastMessageId?: string;
  lastMessageAt?: Date;
  createdAt: Date;
  updatedAt: Date;
};

export type MessageType = "text" | "image" | "voice";

export type MessageReceipt = {
  userId: string;
  deliveredAt?: Date;
  seenAt?: Date;
};

export type MessageDoc = {
  _id: string; // messageId
  conversationId: string;
  senderId: string;
  type: MessageType;
  text?: string;
  mediaUrl?: string; // for image/voice
  mediaMimeType?: string;
  voiceDurationMs?: number;
  receipts: MessageReceipt[]; // one per participant
  editedAt?: Date;
  deletedAt?: Date; // hard delete avoided; soft-delete for all
  deletedForUserIds?: string[]; // per-user delete
  createdAt: Date;
  updatedAt: Date;
};


