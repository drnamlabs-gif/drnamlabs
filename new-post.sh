#!/usr/bin/env bash
#
# Start a new blog post.
#
#   ./new-post.sh "How the Baldwin effect misleads"        # English
#   ./new-post.sh vi "Vì sao mô hình truyền thống hỏng"    # Vietnamese
#
# Writes src/content/blog/<slug>.md with the frontmatter the schema expects
# and opens it. The post starts as a draft: it shows in `npm run dev` and is
# left out of the published site until you set `draft: false`.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

lang=en
if [[ "${1:-}" == "vi" || "${1:-}" == "en" ]]; then
  lang="$1"; shift
fi

title="${*:-}"
if [[ -z "$title" ]]; then
  echo "usage: ./new-post.sh [en|vi] \"Post title\"" >&2
  exit 1
fi

# Slug: strip Vietnamese diacritics, lowercase, keep words, join with dashes.
slug=$(printf '%s' "$title" \
  | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null || printf '%s' "$title")
slug=$(printf '%s' "$slug" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E "s/[^a-z0-9]+/-/g; s/^-+//; s/-+$//" \
  | cut -c1-60)
[[ -n "$slug" ]] || slug="post"

today=$(date +%Y-%m-%d)
file="src/content/blog/${slug}.md"

if [[ -e "$file" ]]; then
  echo "Already exists: $file" >&2
  exit 1
fi

# The description is what shows on the index and in the RSS feed, so it is
# left empty on purpose -- an unwritten one is easier to notice than a bad one.
cat > "$file" <<EOF
---
title: "${title//\"/\\\"}"
description: ""
date: ${today}
lang: ${lang}
tags: []
draft: true
---

EOF

echo "Created $file"
echo
echo "  1. Write it. Fill in 'description' -- the build shows it on the index and in RSS."
echo "  2. Preview:  npm run dev          -> http://localhost:4321/blog/"
echo "  3. Publish:  set draft: false, then ./deploy.sh"

if command -v code >/dev/null 2>&1; then
  code "$file"
fi
