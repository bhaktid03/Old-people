import Parser from "rss-parser";
import { NewsItem, NewsProvider } from "./provider.types.js";

const FEED_URL = "https://timesofindia.indiatimes.com/rssfeeds/-2128936835.cms";
const parser = new Parser<{ items: any[] }>();

function htmlToText(html?: string): string | undefined {
  if (!html) return undefined;
  let text = html.replace(/<script[\s\S]*?<\/script>/gi, "").replace(/<style[\s\S]*?<\/style>/gi, "");
  text = text.replace(/<\/(p|div|h\d|li|blockquote)>/gi, "\n").replace(/<br\s*\/?>(\s*)/gi, "\n");
  text = text.replace(/<[^>]+>/g, "");
  text = text
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");
  text = text.replace(/\n\s*\n+/g, "\n\n").replace(/[ \t]+/g, " ").trim();
  return text;
}

function toNewsItem(item: any): NewsItem {
  const contentHtml: string | undefined = item['content:encoded'] || item.content || undefined;
  const fullText = htmlToText(contentHtml) || item.contentSnippet || item.summary;
  return {
    id: item.guid || item.id || item.link,
    title: item.title,
    summary: fullText,
    url: item.link,
    imageUrl: undefined,
    publishedAt: item.isoDate || item.pubDate,
    source: "Times of India",
    language: "en",
    contentHtml,
    category: Array.isArray(item.categories) && item.categories.length ? item.categories[0] : undefined,
    categories: Array.isArray(item.categories) ? item.categories : undefined,
  };
}

export const ToiProvider: NewsProvider = {
  name: "toi",
  async fetchLatest(limit: number): Promise<NewsItem[]> {
    const feed = await parser.parseURL(FEED_URL);
    return (feed.items || []).slice(0, limit).map(toNewsItem);
  },
};





