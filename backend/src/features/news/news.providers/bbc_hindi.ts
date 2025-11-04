import Parser from "rss-parser";
import { NewsItem, NewsProvider } from "./provider.types.js";

const FEED_URL = "https://feeds.bbci.co.uk/hindi/rss.xml";
const parser = new Parser<{ items: any[] }>();

function toNewsItem(item: any): NewsItem {
  return {
    id: item.guid || item.id || item.link,
    title: item.title,
    summary: item.contentSnippet || item.summary,
    url: item.link,
    imageUrl: undefined,
    publishedAt: item.isoDate || item.pubDate,
    source: "BBC Hindi",
    language: "hi",
  };
}

export const BbcHindiProvider: NewsProvider = {
  name: "bbc_hindi",
  async fetchLatest(limit: number): Promise<NewsItem[]> {
    const feed = await parser.parseURL(FEED_URL);
    return (feed.items || []).slice(0, limit).map(toNewsItem);
  },
};


