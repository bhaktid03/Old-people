import {
  CommunityThoughtDoc,
  CreateCommunityThoughtInput,
  CommunityThoughtResponse,
  CommunityThoughtType,
} from "./community.types.js";
import {
  createCommunityThought as repoCreateCommunityThought,
  getCommunityThoughtById,
  getCommunityThoughtsByCommunityId,
  getCommunityThoughtsByUserId,
  getAllCommunityThoughts,
  deleteCommunityThought as repoDeleteCommunityThought,
  updateCommunityThought as repoUpdateCommunityThought,
} from "./community.repo.js";

function toResponse(doc: CommunityThoughtDoc): CommunityThoughtResponse {
  const content = { ...doc.content } as any;
  // Attach mediaUrl when we have GridFS fileIds
  if (doc.content.type === "audio" && doc.content["audioFileId"]) {
    content.mediaUrl = `/api/v1/media/${doc.content["audioFileId"]}/stream`;
  }
  if (doc.content.type === "video" && doc.content["videoFileId"]) {
    content.mediaUrl = `/api/v1/media/${doc.content["videoFileId"]}/stream`;
  }
  return {
    id: doc._id,
    communityId: doc.communityId,
    userId: doc.userId,
    contentType: doc.contentType,
    content,
    respectUserIds: doc.respectUserIds ?? [],
    respectCount: (doc.respectUserIds ?? []).length,
    createdAt: doc.createdAt.toISOString(),
    updatedAt: doc.updatedAt.toISOString(),
  };
}

export async function createCommunityThought(input: CreateCommunityThoughtInput): Promise<CommunityThoughtResponse> {
  // Validate content based on type
  if (input.contentType === "text" && input.content.type !== "text") {
    throw new Error("Content type mismatch: expected text content");
  }
  if (input.contentType === "audio" && input.content.type !== "audio") {
    throw new Error("Content type mismatch: expected audio content");
  }
  if (input.contentType === "video" && input.content.type !== "video") {
    throw new Error("Content type mismatch: expected video content");
  }

  const doc = await repoCreateCommunityThought(input);
  return toResponse(doc);
}

export async function getCommunityThought(thoughtId: string): Promise<CommunityThoughtResponse | null> {
  const doc = await getCommunityThoughtById(thoughtId);
  return doc ? toResponse(doc) : null;
}

export type GetCommunityThoughtsOptions = {
  communityId?: string;
  userId?: string;
  limit?: number;
  skip?: number;
};

export async function getCommunityThoughts(options: GetCommunityThoughtsOptions): Promise<CommunityThoughtResponse[]> {
  let docs: CommunityThoughtDoc[];

  if (options.communityId) {
    docs = await getCommunityThoughtsByCommunityId(options.communityId, {
      limit: options.limit,
      skip: options.skip,
    });
  } else if (options.userId) {
    docs = await getCommunityThoughtsByUserId(options.userId, {
      limit: options.limit,
      skip: options.skip,
    });
  } else {
    // Return all community thoughts if no filter is provided
    docs = await getAllCommunityThoughts({
      limit: options.limit,
      skip: options.skip,
    });
  }

  return docs.map(toResponse);
}

export async function deleteCommunityThought(thoughtId: string, userId: string): Promise<boolean> {
  return await repoDeleteCommunityThought(thoughtId, userId);
}

export async function updateCommunityThought(
  thoughtId: string,
  userId: string,
  updates: { content?: CommunityThoughtDoc["content"] }
): Promise<CommunityThoughtResponse | null> {
  const doc = await repoUpdateCommunityThought(thoughtId, userId, updates);
  return doc ? toResponse(doc) : null;
}

export async function respectCommunityThought(thoughtId: string, userId: string): Promise<CommunityThoughtResponse | null> {
  const { addRespect } = await import("./community.repo.js");
  const doc = await addRespect(thoughtId, userId);
  return doc ? toResponse(doc) : null;
}

export async function unrespectCommunityThought(thoughtId: string, userId: string): Promise<CommunityThoughtResponse | null> {
  const { removeRespect } = await import("./community.repo.js");
  const doc = await removeRespect(thoughtId, userId);
  return doc ? toResponse(doc) : null;
}

