import { defineConfig } from 'astro/config';

// Reading time, computed at build time. A tiny local plugin rather than a
// dependency: it is a word count, and the site ships no runtime JS for it.
function remarkReadingTime() {
  return (tree, file) => {
    let words = 0;
    const walk = (node) => {
      if (node.type === 'text' || node.type === 'inlineCode') {
        words += String(node.value).trim().split(/\s+/).filter(Boolean).length;
      }
      (node.children ?? []).forEach(walk);
    };
    walk(tree);
    // Vietnamese runs to more, shorter words than English; 200 wpm is a fair
    // middle and the number is only ever a hint.
    file.data.astro.frontmatter.minutes = Math.max(1, Math.round(words / 200));
    file.data.astro.frontmatter.words = words;
  };
}

export default defineConfig({
  site: 'https://drnamlabs.com',
  // nginx serves this with `try_files $uri $uri/ =404`, so directory-style
  // URLs (/research/index.html) resolve correctly without trailing-slash
  // redirects. Do not switch to `format: 'file'` without changing nginx.
  build: { format: 'directory' },
  trailingSlash: 'ignore',

  // Post images live in public/blog/ and are served as-is, so the optimising
  // image service (and its sharp dependency) is not needed.
  image: { service: { entrypoint: 'astro/assets/services/noop' } },

  markdown: {
    remarkPlugins: [remarkReadingTime],
    shikiConfig: { themes: { light: 'github-light', dark: 'github-dark' }, wrap: false },
  },

  // Note: do NOT use Astro's `redirects` here. With `format: 'directory'` a
  // key like '/research.html' is emitted as a *directory* named
  // "research.html", and '/index.html' collides with the real index file, so
  // the build fails. The legacy .html URLs are kept alive by small stub files
  // in public/ instead, which nginx serves directly.
});
