import Parser from "rss-parser";
import { NewsItem, NewsProvider } from "./provider.types.js";

const FEED_URL = "https://feeds.bbci.co.uk/hindi/rss.xml";
const parser = new Parser<{ items: any[] }>();

function htmlToText(html?: string): string | undefined {
  if (!html) return undefined;
  // Remove scripts/styles
  let text = html.replace(/<script[\s\S]*?<\/script>/gi, "").replace(/<style[\s\S]*?<\/style>/gi, "");
  // Replace <br> and block tags with newlines
  text = text.replace(/<\/(p|div|h\d|li|blockquote)>/gi, "\n").replace(/<br\s*\/?>(\s*)/gi, "\n");
  // Strip all tags
  text = text.replace(/<[^>]+>/g, "");
  // Decode common entities
  text = text
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");
  // Collapse multiple newlines/spaces
  text = text.replace(/\n\s*\n+/g, "\n\n").replace(/[ \t]+/g, " ").trim();
  return text;
}

function toNewsItem(item: any): NewsItem {
  const contentHtml = item["content"] || item["content:encoded"];
  const fullText = htmlToText(contentHtml) || item.contentSnippet || item.summary;
  return {
    id: item.guid || item.id || item.link,
    title: item.title,
    summary: fullText,
    url: item.link,
    imageUrl: undefined,
    publishedAt: item.isoDate || item.pubDate,
    source: "BBC Hindi",
    language: "hi",
    contentHtml,
    category: Array.isArray(item.categories) && item.categories.length ? item.categories[0] : undefined,
    categories: Array.isArray(item.categories) ? item.categories : undefined,
  };
}

export const BbcHindiProvider: NewsProvider = {
  name: "bbc_hindi",
  async fetchLatest(limit: number): Promise<NewsItem[]> {
    const feed = await parser.parseURL(FEED_URL);
    return (feed.items || []).slice(0, limit).map(toNewsItem);
  },
};





