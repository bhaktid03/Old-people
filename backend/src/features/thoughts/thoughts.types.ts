export type ThoughtType = "text" | "audio" | "video";

export type ThoughtContent = 
  | { type: "text"; text: string }
  | { type: "audio"; audioUrl?: string; audioFileId?: string; transcript?: string; mediaUrl?: string }
  | { type: "video"; videoUrl?: string; videoFileId?: string; thumbnailUrl?: string; caption?: string; mediaUrl?: string };

export type ThoughtDoc = {
  _id: string;
  newsUrl: string; // News article URL (stable, unique identifier from NewsItem.url)
  userId: string;
  contentType: ThoughtType;
  content: ThoughtContent;
  respectUserIds: string[];
  createdAt: Date;
  updatedAt: Date;
};

export type CreateThoughtInput = {
  newsUrl: string; // News article URL from NewsItem.url
  userId: string;
  contentType: ThoughtType;
  content: ThoughtContent;
};

export type ThoughtResponse = {
  id: string;
  newsUrl: string;
  userId: string;
  contentType: ThoughtType;
  content: ThoughtContent;
  respectUserIds: string[];
  respectCount: number;
  createdAt: string;
  updatedAt: string;
};

