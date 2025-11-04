export type MediaType = "image" | "video" | "audio";

export type AuthorSnapshot = {
  userId: string;
  displayName?: string;
  imageUrl?: string; // avatar
};

export type PostDoc = {
  _id: string; // postId
  author: AuthorSnapshot;
  text?: string;
  media?: { type: MediaType; url: string; mimeType?: string }[]; // optional multiple
  likeUserIds: string[];
  commentsCount: number;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
};

export type CommentDoc = {
  _id: string; // commentId
  postId: string;
  author: AuthorSnapshot;
  text: string;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
};


