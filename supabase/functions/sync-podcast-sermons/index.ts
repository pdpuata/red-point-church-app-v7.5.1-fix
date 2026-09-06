import { json, optionsResponse } from "../_shared/cors.ts";
import { adminClient, requireAdmin } from "../_shared/supabase.ts";

const RSS_URL = "https://www.redpointchurch.com/pinetown-podcast-feed?format=rss";
const USER_AGENT = "RedPointChurchSermonSync/1.0";

type PodcastEpisode = {
  source_guid: string;
  title: string;
  description: string | null;
  preached_at: string | null;
  audio_url: string;
  image_url: string | null;
};

function decodeHtml(value: string) {
  return value
    .replace(/<[^>]*>/g, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&quot;/gi, '"')
    .replace(/&apos;/gi, "'")
    .replace(/&#39;/g, "'")
    .replace(/&#(x[0-9a-f]+|\d+);/gi, (_, code: string) =>
      String.fromCodePoint(code.toLowerCase().startsWith("x")
        ? parseInt(code.slice(1), 16)
        : parseInt(code, 10))
    )
    .replace(/\s+/g, " ")
    .trim();
}

function xmlText(block: string, name: string) {
  const match = block.match(
    new RegExp(`<(?:[A-Za-z0-9_.-]+:)?${name}\\b[^>]*>([\\s\\S]*?)</(?:[A-Za-z0-9_.-]+:)?${name}>`, "i")
  );
  if (!match) return null;
  const value = match[1].replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1");
  return value.trim() || null;
}

function xmlAttribute(block: string, elementName: string, attributeName: string) {
  const match = block.match(
    new RegExp(`<(?:(?:[A-Za-z0-9_.-]+):)?${elementName}\\b[^>]*\\b${attributeName}=["']([^"']+)["']`, "i")
  );
  return match ? decodeHtml(match[1]) : null;
}

function episodeTitle(rawTitle: string) {
  return decodeHtml(rawTitle)
    .replace(/^(Sunday Sermon|Sermon)\s*\/\/\s*/i, "")
    .replace(/\s*[-–—]?\s*\d{1,2}\/\d{1,2}\/\d{4}\s*$/, "")
    .trim();
}

function parseDate(value: string | null) {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

export function parsePodcastFeed(xml: string): PodcastEpisode[] {
  const channel = xml.match(/<channel\b[^>]*>([\s\S]*?)<\/channel>/i)?.[1] || "";
  if (!channel) throw new Error("Podcast feed is not valid RSS XML.");

  const channelImage =
    xmlAttribute(channel, "itunes:image", "href") || xmlText(channel, "url");
  const itemRegex = /<item\b[^>]*>([\s\S]*?)<\/item>/gi;
  const episodes: PodcastEpisode[] = [];
  let match: RegExpExecArray | null;

  while ((match = itemRegex.exec(channel)) !== null) {
    const item = match[1];
    const sourceGuid = xmlText(item, "guid");
    const rawTitle = xmlText(item, "title");
    const audioUrl = xmlAttribute(item, "enclosure", "url");
    if (!sourceGuid || !rawTitle || !audioUrl) continue;

    const description = xmlText(item, "description");
    const imageUrl =
      xmlAttribute(item, "itunes:image", "href") || channelImage || null;
    const title = episodeTitle(rawTitle);
    if (!title) continue;

    episodes.push({
      source_guid: sourceGuid,
      title,
      description: description ? decodeHtml(description) : null,
      preached_at: parseDate(xmlText(item, "pubDate")),
      audio_url: audioUrl,
      image_url: imageUrl,
    });
  }

  return episodes;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return optionsResponse();
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    await requireAdmin(req);
    const response = await fetch(RSS_URL, {
      headers: { Accept: "application/rss+xml, application/xml, text/xml", "User-Agent": USER_AGENT },
    });
    if (!response.ok) throw new Error(`Podcast feed returned HTTP ${response.status}.`);

    const episodes = parsePodcastFeed(await response.text());
    if (!episodes.length) throw new Error("Podcast feed contained no usable episodes.");

    const db = adminClient();
    let imported = 0;
    let updated = 0;

    for (const episode of episodes) {
        let { data: existing, error: lookupError } = await db
        .from("sermons")
        .select("id")
        .eq("source_guid", episode.source_guid)
        .maybeSingle();
      if (lookupError) throw lookupError;

        if (!existing) {
          const fallback = await db
            .from("sermons")
            .select("id")
            .eq("audio_url", episode.audio_url)
            .maybeSingle();
          if (fallback.error) throw fallback.error;
          existing = fallback.data;
        }

      const payload = {
        title: episode.title,
        description: episode.description,
        preached_at: episode.preached_at,
        audio_url: episode.audio_url,
        youtube_url: null,
        image_url: episode.image_url,
        source_guid: episode.source_guid,
      };

      if (existing) {
        const { error } = await db.from("sermons").update(payload).eq("id", existing.id);
        if (error) throw error;
        updated++;
      } else {
        const { error } = await db.from("sermons").insert({ ...payload, published: false });
        if (error) throw error;
        imported++;
      }
    }

    return json({ success: true, source: RSS_URL, sermonsFound: episodes.length, imported, updated });
  } catch (error) {
    console.error("Podcast sermon sync error:", error);
    return json({ error: error instanceof Error ? error.message : "Podcast sermon sync failed." }, 500);
  }
});
