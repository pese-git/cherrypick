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
