# drnamlabs.com

Personal site of Nam H. Le, Ph.D. Astro, static output, no backend.

## Run

```bash
npm install
npm run dev        # http://localhost:4321
npm run build      # -> dist/
npm run preview    # serve dist/ locally
```

## Publish

```bash
./deploy.sh --dry-run    # see what would change
./deploy.sh              # build, back up the live site, upload, verify
```

It rsyncs `dist/` to `theta-server:/var/www/drnamlabs` over the existing
`~/.ssh/config` host alias. nginx serves the directory statically with
`try_files $uri $uri/ =404`, so there is no service to restart. Each deploy
copies the current live files to `/var/www/drnamlabs_backups/<timestamp>/`
first.

The same server also runs `theta.bunnyquant.com`, `bunnyquant.com` and
`bunnyquant.vn` from sibling directories. `deploy.sh` never touches them.

## Where the content lives

| Change this | Edit |
|---|---|
| Name, role, nav, contact links | `src/data/site.json` |
| Publication list | `src/data/publications.json` — the single source of truth |
| Research strands | `src/pages/research.astro` |
| BunnyQuant / Theta | `src/pages/bunnyquant.astro` |
| Home page copy | `src/pages/index.astro` |
| Colours, type, spacing | `src/styles/global.css` |
| The CV people download | `public/CV.pdf` |
| Blog posts | `src/content/blog/*.md` |

Keep `publications.json` in step with `/Volumes/DATA/postdoc/CV/cv_nam_le.tex`; they are
the two places a publication has to be listed.

## The hero canvas

`src/components/PhasePortrait.astro` draws a decorative trajectory cycling
clockwise through four labelled quadrants. The curve is a Lissajous figure and
encodes nothing about the Theta method — see the confidentiality note in
`CLAUDE.md`, and keep it that way: this file ships its script to the browser
verbatim, comments included.

It reads its colours from the CSS custom properties, so it follows the theme
toggle; it pauses when off-screen or when the tab is hidden, and renders a
single static orbit under `prefers-reduced-motion`.

## Notes

- `public/CV.pdf` is what the CV links resolve to. `deploy.sh` refuses to
  publish it if it still contains `[TODO]` placeholders.
- `/CV.pdf` and `/bunnyquant` deliberately keep the paths the previous site
  linked to, so old links do not 404.

## Blog

Posts are Markdown files in `src/content/blog/`. Start one with:

```bash
./new-post.sh "How the Baldwin effect misleads"     # English
./new-post.sh vi "Vì sao mô hình truyền thống hỏng"  # Vietnamese
```

That writes the frontmatter `src/content.config.ts` expects — a wrong field
name fails the build rather than silently dropping the post. Posts begin with
`draft: true`: they appear in `npm run dev` and are excluded from the built
site. Set `draft: false` and `./deploy.sh` to publish.

`lang` is `en` or `vi`; when both exist the index shows a language filter.
Images go in `public/blog/` and are referenced as `/blog/name.png`. The feed
at `/rss.xml` is generated from the same files.

## Comments

Self-hosted [Remark42](https://remark42.com) on the same server — no third
party sees the threads or the addresses.

| | |
|---|---|
| Service | `remark42.service`, listening on `127.0.0.1:5061` |
| Binary | `/opt/remark42/remark42` |
| Config | `/etc/remark42.env` (mode 600) |
| Data | `/var/lib/remark42/` — Bolt DB plus nightly backups |
| Public path | `https://drnamlabs.com/remark42/` (nginx proxy) |
| Moderation | <https://drnamlabs.com/remark42/web/> — user `admin`, password in `/root/remark42-admin-credentials.txt` |

Readers comment with a display name; no account is required. To require a
verified email address instead, add SMTP settings to `/etc/remark42.env`, set
`AUTH_EMAIL_ENABLE=true`, and `systemctl restart remark42`.

Useful commands:

```bash
ssh theta-server systemctl status remark42
ssh theta-server journalctl -u remark42 -n 50
ssh theta-server ls -la /var/lib/remark42/backup   # nightly exports
```
