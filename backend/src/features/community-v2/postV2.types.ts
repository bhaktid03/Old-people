export type V2MediaType = "image" | "audio" | "video";

export type V2AuthorSnapshot = {
  userId: string;
  displayName?: string;
  imageUrl?: string;
};

export type V2MediaItem = {
  type: V2MediaType;
  fileId: string;
  contentType?: string;
  streamUrl: string;
};

export type V2PostDoc = {
  _id: string;
  author: V2AuthorSnapshot;
  text?: string;
  media?: V2MediaItem[];
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
};


