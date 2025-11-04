export type UserDoc = {
  _id: string; // userId (string)
  phone?: string;
  email?: string;
  displayName?: string;
  online?: boolean;
  lastSeenAt?: Date;
  createdAt: Date;
  updatedAt: Date;
};


