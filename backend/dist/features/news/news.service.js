import { IndianExpressProvider } from "./news.providers/indian_express.js";
import { BbcHindiProvider } from "./news.providers/bbc_hindi.js";
import { NdtvProvider } from "./news.providers/ndtv.js";
import { ToiProvider } from "./news.providers/toi.js";
import { TheHinduProvider } from "./news.providers/the_hindu.js";
const PROVIDERS = {
    indian_express: IndianExpressProvider,
    bbc_hindi: BbcHindiProvider,
    ndtv: NdtvProvider,
    toi: ToiProvider,
    the_hindu: TheHinduProvider,
};
export async function getNews(opts) {
    const provider = PROVIDERS[opts.provider || "indian_express"];
    const limit = Math.min(Math.max(opts.limit || 20, 1), 50);
    const items = await provider.fetchLatest(limit);
    return items;
}
