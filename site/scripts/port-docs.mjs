// One-off migration: Docusaurus markdown -> Starlight markdown.
// Converts frontmatter (title from H1, drops sidebar_position), rewrites
// internal .md links to Starlight routes and out-of-tree links to GitHub URLs.
import { readdirSync, readFileSync, mkdirSync, writeFileSync, statSync } from 'node:fs';
import { join, dirname, relative, posix } from 'node:path';

const ROOT = new URL('../..', import.meta.url).pathname; // repo root
const GH = 'https://github.com/pese-git/cherrypick/blob/master';

const JOBS = [
  {
    src: join(ROOT, 'website/docs'),
    out: join(ROOT, 'site/src/content/docs'),
    prefix: '', // English is the root locale
  },
  {
    src: join(ROOT, 'website/i18n/ru/docusaurus-plugin-content-docs/current'),
    out: join(ROOT, 'site/src/content/docs/ru'),
    prefix: '/ru',
  },
];

function walk(dir) {
  const out = [];
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) out.push(...walk(full));
    else if (name.endsWith('.md')) out.push(full);
  }
  return out;
}

// Build the set of valid in-tree slugs from the English source dir.
const validSlugs = new Set(
  walk(JOBS[0].src).map((f) => relative(JOBS[0].src, f).replace(/\.md$/, '')),
);

function slugToRoute(slug, prefix) {
  return `${prefix}/${slug.split('/').map(encodeURIComponent).join('/')}/`;
}

function rewriteLink(target, fileDirRelative, prefix) {
  // Leave anchors, mailto, http(s), and non-.md targets untouched.
  const [path, hash = ''] = target.split('#');
  const suffix = hash ? `#${hash}` : '';
  if (!path.endsWith('.md')) return target;
  if (/^https?:\/\//.test(path)) return target;

  // Out-of-tree references -> GitHub.
  if (path.startsWith('../') || path.startsWith('doc/')) {
    const clean = path.startsWith('../') ? path.slice(3) : path;
    return `${GH}/${clean}${suffix}`;
  }

  // Resolve relative to the file's directory, then match against valid slugs.
  const resolved = posix.normalize(posix.join(fileDirRelative, path)).replace(/\.md$/, '');
  if (validSlugs.has(resolved)) return `${slugToRoute(resolved, prefix)}${suffix}`;

  // Unknown in-tree target -> GitHub fallback (keeps the build from breaking).
  return `${GH}/website/docs/${path}${suffix}`;
}

function yamlQuote(s) {
  return `"${s.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
}

// Pages that are hand-maintained in the site (e.g. rewritten as .mdx) and must
// not be regenerated as .md, which would create a duplicate-slug conflict.
const SKIP = new Set(['installation.md']);

let count = 0;
for (const job of JOBS) {
  for (const file of walk(job.src)) {
    const relPath = relative(job.src, file); // e.g. core-concepts/scope.md
    if (SKIP.has(relPath)) continue;
    let text = readFileSync(file, 'utf8');
    const fileDirRelative = dirname(relPath) === '.' ? '' : dirname(relPath);

    // Strip existing frontmatter, remember non-position keys we care about.
    let fmTitle = null;
    text = text.replace(/^---\n([\s\S]*?)\n---\n?/, (_, body) => {
      const m = body.match(/^title:\s*(.+)$/m);
      if (m) fmTitle = m[1].trim().replace(/^["']|["']$/g, '');
      return '';
    });

    // Take the first H1 as the title and remove it from the body.
    let title = fmTitle;
    text = text.replace(/^\s*#\s+(.+?)\s*$/m, (whole, h1) => {
      if (!title) title = h1.trim();
      return ''; // drop the H1 line; Starlight renders the frontmatter title
    });
    if (!title) title = relPath.replace(/\.md$/, '');

    // Drop HTML comments: they never render and are invalid MDX, which breaks
    // the starlight-versions markdown transform when snapshotting versions.
    text = text.replace(/<!--[\s\S]*?-->[ \t]*\n?/g, '');

    text = text.replace(/^\n+/, ''); // trim leading blank lines

    // Rewrite markdown links.
    text = text.replace(/\]\(([^)]+)\)/g, (whole, target) => {
      const t = target.trim();
      return `](${rewriteLink(t, fileDirRelative, job.prefix)})`;
    });

    const frontmatter = `---\ntitle: ${yamlQuote(title)}\n---\n\n`;
    const outPath = join(job.out, relPath);
    mkdirSync(dirname(outPath), { recursive: true });
    writeFileSync(outPath, frontmatter + text.trimEnd() + '\n');
    count++;
  }
}
console.log(`Ported ${count} files.`);
