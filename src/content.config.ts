import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

// Posts are plain Markdown files in src/content/blog/. Use ./new-post.sh to
// scaffold one -- it writes the frontmatter this schema expects, so a typo in
// a field name fails the build rather than silently dropping the post.
const blog = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/blog' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    date: z.coerce.date(),
    // Posts may be in either language; the index lets readers filter.
    lang: z.enum(['en', 'vi']).default('en'),
    tags: z.array(z.string()).default([]),
    // Drafts build locally but are excluded from the published site.
    draft: z.boolean().default(false),
  }),
});

export const collections = { blog };
