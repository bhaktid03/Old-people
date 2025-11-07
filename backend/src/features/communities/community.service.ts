import { CommunityDoc, CommunityResponse } from "./community.types.js";
import { getAllCommunities, getCommunityById } from "./community.repo.js";

function toResponse(doc: CommunityDoc): CommunityResponse {
  return {
    id: doc._id,
    name: doc.name,
    description: doc.description,
    imageUrl: doc.imageUrl,
    memberCount: doc.memberCount ?? 0,
    createdAt: doc.createdAt.toISOString(),
    updatedAt: doc.updatedAt.toISOString(),
  };
}

export type GetCommunitiesOptions = {
  limit?: number;
  skip?: number;
};

export async function getCommunities(options: GetCommunitiesOptions = {}): Promise<CommunityResponse[]> {
  const docs = await getAllCommunities({
    limit: options.limit,
    skip: options.skip,
  });

  return docs.map(toResponse);
}

export async function getCommunity(communityId: string): Promise<CommunityResponse | null> {
  const doc = await getCommunityById(communityId);
  return doc ? toResponse(doc) : null;
}



