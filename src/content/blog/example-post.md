---
title: "Example post — delete or rewrite this"
description: "A template showing every frontmatter field and how the formatting renders. It is a draft, so it never appears on the live site."
date: 2026-08-19
lang: en
tags: ["notes"]
draft: true
---

This file is a template, not a post. It has `draft: true`, so it shows when you run
`npm run dev` locally and is left out of the published site entirely. Copy it, or run
`./new-post.sh "Your title"` to get a fresh one.

## Frontmatter

Only two fields matter day to day:

- `lang` — `en` or `vi`. Vietnamese posts get a "Tiếng Việt" tag and readers can filter the
  index by language. Write in whichever language the thought arrived in.
- `draft` — `true` keeps a post local. Set it to `false` when you want it published.

`date` drives the ordering, `description` is what shows on the index and in the RSS feed, and
`tags` is a free list.

## How things render

Ordinary paragraphs, **bold**, *italic*, `inline code`, and [links](/research/).

> A blockquote, for when you are quoting a referee who missed the point.

1. Numbered lists work
2. So do bulleted ones
3. And nested content underneath them

```python
# Code blocks are syntax-highlighted, and follow the light/dark theme.
def baldwin(population, generations):
    for _ in range(generations):
        population = select(learn(population))
    return population
```

| Column | Meaning |
|---|---|
| Tables | are supported |
| Wide ones | scroll inside their own box |

Images go in `public/blog/` and are referenced as `![caption](/blog/your-image.png)`.

## Comments

Every published post gets a comment thread at the bottom. Readers give a display name and can
reply to each other; you moderate from the Remark42 admin panel. Nothing is shared with a third
party — the threads live on your own server.
