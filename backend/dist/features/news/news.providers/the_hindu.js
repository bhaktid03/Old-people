import Parser from "rss-parser";
const FEED_URL = "https://www.thehindu.com/feeder/default.rss";
const parser = new Parser();
function toNewsItem(item) {
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
export const TheHinduProvider = {
    name: "the_hindu",
    async fetchLatest(limit) {
        const feed = await parser.parseURL(FEED_URL);
        return (feed.items || []).slice(0, limit).map(toNewsItem);
    },
};
