import Parser from "rss-parser";
const FEED_URL = "https://feeds.bbci.co.uk/hindi/rss.xml";
const parser = new Parser();
function toNewsItem(item) {
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
export const BbcHindiProvider = {
    name: "bbc_hindi",
    async fetchLatest(limit) {
        const feed = await parser.parseURL(FEED_URL);
        return (feed.items || []).slice(0, limit).map(toNewsItem);
    },
};
