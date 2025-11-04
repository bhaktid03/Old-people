import Parser from "rss-parser";
import { NewsItem, NewsProvider } from "./provider.types.js";

const FEED_URL = "https://www.thehindu.com/feeder/default.rss";
const parser = new Parser<{ items: any[] }>();

function toNewsItem(item: any): NewsItem {
  return {
    id: item.guid || item.id || item.link,
    title: item.title,
    summary: item.contentSnippet || item.summary,
    url: item.link,
    imageUrl: undefined,
    publishedAt: item.isoDate || item.pubDate,
    source: "The Hindu",
    language: "en",
  };
}

export const TheHinduProvider: NewsProvider = {
  name: "the_hindu",
  async fetchLatest(limit: number): Promise<NewsItem[]> {
    const feed = await parser.parseURL(FEED_URL);
    return (feed.items || []).slice(0, limit).map(toNewsItem);
  },
};




