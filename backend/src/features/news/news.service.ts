import { IndianExpressProvider } from "./news.providers/indian_express.js";
import { BbcHindiProvider } from "./news.providers/bbc_hindi.js";
import { NdtvProvider } from "./news.providers/ndtv.js";
import { ToiProvider } from "./news.providers/toi.js";
import { TheHinduProvider } from "./news.providers/the_hindu.js";
import { NewsItem, NewsProvider } from "./news.providers/provider.types.js";

const PROVIDERS: Record<string, NewsProvider> = {
  indian_express: IndianExpressProvider,
  bbc_hindi: BbcHindiProvider,
  ndtv: NdtvProvider,
  toi: ToiProvider,
  the_hindu: TheHinduProvider,
};

export type GetNewsOptions = {
  provider?: keyof typeof PROVIDERS;
  limit?: number;
  targetLang?: string | null;
};

export async function getNews(opts: GetNewsOptions): Promise<NewsItem[]> {
  const provider = PROVIDERS[opts.provider || "indian_express"];
  const limit = Math.min(Math.max(opts.limit || 20, 1), 50);
  const items = await provider.fetchLatest(limit);
  return items;
}


