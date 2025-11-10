import Parser from "rss-parser";
const FEED_URL = "https://indianexpress.com/feed/"; // general feed
const parser = new Parser();
function toNewsItem(item) {
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
function extractImage(item) {
    const content = item['content:encoded'] || item.content || '';
    const match = content.match(/<img[^>]+src\=\"([^\"]+)\"/i);
    return match?.[1];
}
export const IndianExpressProvider = {
    name: "indian_express",
    async fetchLatest(limit) {
        const feed = await parser.parseURL(FEED_URL);
        const items = (feed.items || []).slice(0, limit).map(toNewsItem);
        return items;
    },
};
