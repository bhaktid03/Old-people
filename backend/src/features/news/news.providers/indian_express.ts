import Parser from "rss-parser";
import { NewsItem, NewsProvider } from "./provider.types.js";

const FEED_URL = "https://indianexpress.com/feed/"; // general feed

const parser = new Parser<{ items: any[] }>();

function toNewsItem(item: any): NewsItem {
  return {
    id: item.guid || item.id || item.link,
    title: item.title,
    summary: item.contentSnippet || item.summary,
    url: item.link,
    imageUrl: extractImage(item),
    publishedAt: item.isoDate || item.pubDate,
    source: "The Indian Express",
    language: "en",
  };
}

function extractImage(item: any): string | undefined {
  const content: string = item['content:encoded'] || item.content || '';
  const match = content.match(/<img[^>]+src\=\"([^\"]+)\"/i);
  return match?.[1];
}

export const IndianExpressProvider: NewsProvider = {
  name: "indian_express",
  async fetchLatest(limit: number): Promise<NewsItem[]> {
    const feed = await parser.parseURL(FEED_URL);
    const items = (feed.items || []).slice(0, limit).map(toNewsItem);
    return items;
  },
};




