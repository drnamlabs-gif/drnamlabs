# drnamlabs.com — context for Claude Code

Personal academic site of **Nam H. Le, Ph.D.** — postdoctoral research fellow at the
University of Vermont (Morphology, Evolution & Cognition Lab; co-mentored by Josh Bongard
and Michael Levin), and founder of the BunnyQuant quantitative-analytics venture.

Astro, static output, no application backend. Live at <https://drnamlabs.com>.

## Do this first

```bash
npm install
npm run dev        # http://localhost:4321 — drafts are visible here only
npm run build      # -> dist/
./deploy.sh        # build, back up the live site, rsync, verify
```

## The one rule that matters

**Never publish the mechanism behind Theta / the multi-timeframe market method.**
It is an unpublished trade secret behind a shipped product. Off-limits in any public
output — site copy, README, commit messages, anything: the change of variables, the
governing equations, the fixed-point identity, the linearisation result, the reduction to
independent filters, "deconvolution", numeric thresholds or time constants, measured event
rates, and the named instruments used for validation. Even the phrase "multi-timeframe RSI"
is avoided; the product says "Period (N)" and "Oscillator (N)" instead.

Write capability, not mechanism: *what it does for the reader*. `src/pages/bunnyquant.astro`
is the worked example of the right register. This was got wrong once and had to be pulled
from the live site.

## Layout

| Change this | Edit |
|---|---|
| Name, role, nav, contact links | `src/data/site.json` |
| Publication list | `src/data/publications.json` — single source of truth |
| Research strands | `src/pages/research.astro` |
| BunnyQuant / Theta | `src/pages/bunnyquant.astro` |
| Home page copy | `src/pages/index.astro` |
| Blog posts | `src/content/blog/*.md` (`./new-post.sh "Title"`, or `./new-post.sh vi "Tiêu đề"`) |
| Colours, type, spacing | `src/styles/global.css` |
| Published CV | `public/CV.pdf` |

The CV itself is built **outside this repo**, from `/Volumes/DATA/postdoc/CV/cv_nam_le.tex` via
`/Volumes/DATA/postdoc/CV/build.sh`. That build refuses to emit a PDF containing `[TODO]` placeholders,
a named target employer, or the Theta method. Keep `publications.json` in step with it —
those are the two places a publication has to be listed.

## Traps that have already bitten

1. **Do not add `redirects` to `astro.config.mjs`.** With `build.format: 'directory'` a key
   like `/research.html` is emitted as a *directory* named `research.html`, and `/index.html`
   collides with the real index file — the build fails with `ENOTDIR`. Legacy `.html` URLs
   are kept alive by stub files in `public/` instead.
2. **`.wrap` and `.prose` must not be the same element.** `.wrap` sets `margin-inline: auto`;
   combined with `.prose`'s `max-width` it centres the reading column away from the heading.
   Nest them.
3. **Content collections drag in Astro's image service, which needs `sharp`.** Disabled via
   `image: { service: { entrypoint: 'astro/assets/services/noop' } }` — post images are plain
   files in `public/blog/`.
4. **The nav link row scrolls horizontally on purpose.** Adding a nav item used to overflow
   the page on a 390px screen. The theme button sits outside that scroll container.
5. **`astro preview` resolves `/research` to the stub `research.html`**, while nginx correctly
   301s to `/research/`. Internal links carry trailing slashes to skip the hop. Trust nginx,
   not `preview`, on this.

## Deployment

`./deploy.sh` rsyncs `dist/` to `theta-server:/var/www/drnamlabs` over an existing
`~/.ssh/config` host alias, after copying the live files to a timestamped backup directory.
nginx serves the directory statically (`try_files $uri $uri/ =404`), so there is no service
to restart. It then curl-verifies every route.

**The same server also runs `theta.bunnyquant.com`, `bunnyquant.com`, `bunnyquant.vn` and
`corr.bunnyquant.com` from sibling directories.** `deploy.sh` never touches them. Run
`nginx -t` before any reload, and re-check those hosts afterwards.

HTML is served `Cache-Control: no-cache` and `/_astro/*` (content-hashed) `immutable`. Without
that, browsers heuristically cached an eight-month-old homepage for weeks after a deploy.

## Comments

Self-hosted [Remark42](https://remark42.com), so no third party sees the threads or the
readers' addresses. `remark42.service` on `127.0.0.1:5061`, proxied at `/remark42/`; data in
`/var/lib/remark42/`. Readers comment with a display name, no account. Moderation UI at
`/remark42/web/`. Verified-email commenting needs SMTP settings the site owner must supply.

## House style

Match the existing prose: plain, specific, no marketing register. Prefer stating the finding
over praising it. British spelling. Vietnamese blog posts are first-class — `lang: vi`.
