import { getCollection } from 'astro:content';
import site from '../data/site.json';

// Hand-rolled rather than pulling in @astrojs/rss: the feed is a dozen lines
// and this keeps the project at a single dependency.
const esc = (s: string) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
   .replace(/"/g, '&quot;').replace(/'/g, '&apos;');

export async function GET(context: { site?: URL }) {
  const origin = (context.site ?? new URL('https://drnamlabs.com')).origin;
  const posts = (await getCollection('blog', ({ data }) => !data.draft))
    .sort((a, b) => b.data.date.valueOf() - a.data.date.valueOf());

  const items = posts.map((p) => `    <item>
      <title>${esc(p.data.title)}</title>
      <link>${origin}/blog/${p.id}/</link>
      <guid isPermaLink="true">${origin}/blog/${p.id}/</guid>
      <description>${esc(p.data.description)}</description>
      <pubDate>${p.data.date.toUTCString()}</pubDate>
      <dc:language>${p.data.lang}</dc:language>
    </item>`).join('\n');

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>${esc(site.name)} — Blog</title>
    <link>${origin}/blog/</link>
    <atom:link href="${origin}/rss.xml" rel="self" type="application/rss+xml"/>
    <description>Notes on evolutionary computation, artificial life, and complex adaptive systems. In English and Vietnamese.</description>
    <language>en</language>
${items}
  </channel>
</rss>
`;

  return new Response(xml, { headers: { 'Content-Type': 'application/rss+xml; charset=utf-8' } });
}
