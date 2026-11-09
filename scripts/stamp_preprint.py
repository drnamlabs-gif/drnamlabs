# Dr. Nam H. Le. drnamlabs.com, bunnyquant.com
"""Stamp a submitted manuscript before it is hosted on drnamlabs.com.

Every page gets a footer line naming the author, the site and the venue it is
under review at, plus a faint diagonal mark. The PDF metadata records the same.
A stamp marks where a copy came from; it does not stop anyone redistributing it.

Usage:
  python scripts/stamp_preprint.py SRC.pdf public/papers/SLUG.pdf \
      --venue "Artificial Life" --submitted "October 2026"
Only the stamped copy goes into the repo, never the source PDF.
"""
import argparse
import datetime as dt
import os

import pymupdf as fitz

SITE = "drnamlabs.com"
GREY = (0.42, 0.42, 0.45)


def stamp(src, dst, venue, submitted, author, title=None):
    slug = os.path.splitext(os.path.basename(dst))[0]
    url = f"https://{SITE}/papers/{slug}.pdf"
    foot = (f"Preprint · {author} · {url} · Submitted to {venue}, {submitted} · "
            f"Not peer reviewed; cite the published version when available.")
    doc = fitz.open(src)
    for page in doc:
        r = page.rect
        size = 6.5 if r.width < 700 else 8
        box = fitz.Rect(24, r.height - 20, r.width - 24, r.height - 6)
        page.insert_textbox(box, foot, fontsize=size, color=GREY,
                            align=fitz.TEXT_ALIGN_CENTER, overlay=True)
        mark = f"{SITE} · preprint"
        fs = r.width / 11
        w = fitz.get_text_length(mark, fontsize=fs)
        c = fitz.Point(r.width / 2, r.height / 2)
        page.insert_text(fitz.Point(c.x - w / 2, c.y + fs / 3), mark, fontsize=fs,
                         color=(0.55, 0.55, 0.58), fill_opacity=0.07,
                         morph=(c, fitz.Matrix(-40)), overlay=True)
    meta = doc.metadata or {}
    meta.update({
        "author": author,
        "title": title or meta.get("title") or slug,
        "subject": f"Preprint submitted to {venue}, {submitted}. Source: {url}",
        "keywords": f"preprint; {SITE}; stamped {dt.date.today().isoformat()}",
        "creator": SITE,
    })
    doc.set_metadata(meta)
    os.makedirs(os.path.dirname(dst) or ".", exist_ok=True)
    doc.save(dst, garbage=4, deflate=True)
    return url


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--venue", required=True)
    ap.add_argument("--submitted", required=True, help='e.g. "October 2026"')
    ap.add_argument("--author", default="Nam H. Le")
    ap.add_argument("--title")
    a = ap.parse_args()
    print(stamp(a.src, a.dst, a.venue, a.submitted, a.author, a.title))


if __name__ == "__main__":
    main()
