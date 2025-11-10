import Parser from "rss-parser";
const FEED_URL = "https://timesofindia.indiatimes.com/rssfeeds/-2128936835.cms";
const parser = new Parser();
function toNewsItem(item) {
    return {
        id: item.guid || item.id || item.link,
        title: item.title,
        summary: item.contentSnippet || item.summary,
        url: item.link,
        imageUrl: undefined,
        publishedAt: item.isoDate || item.pubDate,
        source: "Times of India",
        language: "en",
    };
}
export const ToiProvider = {
    name: "toi",
    async fetchLatest(limit) {
        const feed = await parser.parseURL(FEED_URL);
        return (feed.items || []).slice(0, limit).map(toNewsItem);
    },
};
