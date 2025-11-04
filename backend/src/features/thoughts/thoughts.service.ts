import {
  ThoughtDoc,
  CreateThoughtInput,
  ThoughtResponse,
  ThoughtType,
} from "./thoughts.types.js";
import {
  createThought as repoCreateThought,
  getThoughtById,
  getThoughtsByNewsUrl,
  getThoughtsByUserId,
  deleteThought as repoDeleteThought,
  updateThought as repoUpdateThought,
} from "./thoughts.repo.js";

function toResponse(doc: ThoughtDoc): ThoughtResponse {
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
    newsUrl: doc.newsUrl,
    userId: doc.userId,
    contentType: doc.contentType,
    content,
    createdAt: doc.createdAt.toISOString(),
    updatedAt: doc.updatedAt.toISOString(),
  };
}

export async function createThought(input: CreateThoughtInput): Promise<ThoughtResponse> {
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

  const doc = await repoCreateThought(input);
  return toResponse(doc);
}

export async function getThought(thoughtId: string): Promise<ThoughtResponse | null> {
  const doc = await getThoughtById(thoughtId);
  return doc ? toResponse(doc) : null;
}

export type GetThoughtsOptions = {
  newsUrl?: string;
  userId?: string;
  limit?: number;
  skip?: number;
};

export async function getThoughts(options: GetThoughtsOptions): Promise<ThoughtResponse[]> {
  let docs: ThoughtDoc[];

  if (options.newsUrl) {
    docs = await getThoughtsByNewsUrl(options.newsUrl, {
      limit: options.limit,
      skip: options.skip,
    });
  } else if (options.userId) {
    docs = await getThoughtsByUserId(options.userId, {
      limit: options.limit,
      skip: options.skip,
    });
  } else {
    throw new Error("Either newsUrl or userId must be provided");
  }

  return docs.map(toResponse);
}

export async function deleteThought(thoughtId: string, userId: string): Promise<boolean> {
  return await repoDeleteThought(thoughtId, userId);
}

export async function updateThought(
  thoughtId: string,
  userId: string,
  updates: { content?: ThoughtDoc["content"] }
): Promise<ThoughtResponse | null> {
  const doc = await repoUpdateThought(thoughtId, userId, updates);
  return doc ? toResponse(doc) : null;
}

