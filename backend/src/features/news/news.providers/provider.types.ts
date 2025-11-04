export type NewsItem = {
  id: string;
  title: string;
  summary?: string;
  url: string;
  imageUrl?: string;
  publishedAt?: string;
  source: string;
  language?: string; // ISO 639-1 if known from source
};

export interface NewsProvider {
  name: string;
  fetchLatest(limit: number): Promise<NewsItem[]>;
}




