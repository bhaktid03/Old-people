export type CommunityDoc = {
  _id: string;
  name: string;
  description?: string;
  imageUrl?: string;
  memberCount?: number;
  createdAt: Date;
  updatedAt: Date;
};

export type CommunityResponse = {
  id: string;
  name: string;
  description?: string;
  imageUrl?: string;
  memberCount?: number;
  createdAt: string;
  updatedAt: string;
};



