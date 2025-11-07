export type CommunityThoughtType = "text" | "audio" | "video";

export type TextThoughtContent = {
  type: "text";
  text: string;
};

export type AudioThoughtContent = {
  type: "audio";
  // Either an uploaded GridFS fileId or an external URL may be present
  audioFileId?: string;
  audioUrl?: string;
};

export type VideoThoughtContent = {
  type: "video";
  // Either an uploaded GridFS fileId or an external URL may be present
  videoFileId?: string;
  videoUrl?: string;
};

export type CommunityThoughtContent =
  | TextThoughtContent
  | AudioThoughtContent
  | VideoThoughtContent;

export type CommunityThoughtDoc = {
  _id: string;
  communityId: string;
  userId: string;
  contentType: CommunityThoughtType;
  content: CommunityThoughtContent;
  respectUserIds?: string[];
  createdAt: Date;
  updatedAt: Date;
};

export type CreateCommunityThoughtInput = {
  communityId: string;
  userId: string;
  contentType: CommunityThoughtType;
  content: CommunityThoughtContent;
};

export type CommunityThoughtResponse = {
  id: string;
  communityId: string;
  userId: string;
  contentType: CommunityThoughtType;
  // Service may enrich with mediaUrl for audio/video
  content: CommunityThoughtContent & { mediaUrl?: string };
  respectUserIds: string[];
  respectCount: number;
  createdAt: string; // ISO string
  updatedAt: string; // ISO string
};




