# CherryPick site

Landing page (визитка) and documentation for **CherryPick** — a dependency
injection ecosystem for Dart & Flutter. Built with [Astro 5](https://astro.build)
and [Starlight](https://starlight.astro.build).

## Structure

```
site/
├── astro.config.mjs        # Starlight config: i18n (en/ru), sidebar, theme
├── src/
│   ├── assets/logo.svg      # navbar logo (cherry mark)
│   ├── styles/custom.css    # fresh minimal cherry-accent theme
│   └── content/docs/
│       ├── index.mdx        # landing page — English (splash template)
│       ├── *.md             # English docs (root locale)
│       └── ru/              # Russian landing + docs
├── public/favicon.svg
└── scripts/port-docs.mjs    # one-off migration from the old Docusaurus docs
```

English is the root locale (served at `/`); Russian is served under `/ru/`.

## Commands

```sh
npm install       # install dependencies
npm run dev       # start the dev server (http://localhost:4321)
npm run build     # build the static site to ./dist
npm run preview   # preview the production build locally
```

## Editing docs

Each page is a Markdown file with a `title` in its frontmatter. Sidebar order
and group labels (with Russian translations) are defined in `astro.config.mjs`.
To add a Russian translation for a page, create the same file path under
`src/content/docs/ru/`.

## Documentation versioning

Versioning is provided by [`starlight-versions`](https://starlight-versions.vercel.app).
The **unversioned** docs at the root of `src/content/docs/` are the latest
(development) line, labelled `4.x.x (dev)`. Archived versions are snapshots
committed under `src/content/docs/<slug>/` (and `src/content/docs/ru/<slug>/`
for Russian), with a config file per version in `src/content/versions/`.

Current versions (see `astro.config.mjs` → `starlightVersions`):

| Label        | Slug   | URL prefix |
| ------------ | ------ | ---------- |
| `4.x.x (dev)`| —      | `/`        |
| `3.x.x`      | `v3`   | `/v3/`     |
| `2.x.x`      | `v2`   | `/v2/`     |
| `1.x.x`      | `v1`   | `/v1/`     |

### Cutting a new version

The plugin snapshots the current docs into a new version directory. Two quirks
to know about:

1. **One new version per build.** Add a single new entry to the `versions`
   array, then run `npm run build`. The plugin refuses to create more than one
   snapshot at a time.
2. **Russian nested-dir cleanup.** With the root-locale i18n setup, the snapshot
   step incorrectly copies previously-archived versions inside the new Russian
   version directory. After building, remove them:

   ```sh
   # e.g. after creating v1, when v2 and v3 already existed
   rm -rf src/content/docs/ru/v1/v2 src/content/docs/ru/v1/v3
   ```

   Verify none remain: `find src/content/docs -type d -path '*/v[0-9]/v[0-9]'`
   should print nothing.

Snapshot content is regular Markdown you can edit afterwards — the snapshot is
just the starting point for that version's docs.
