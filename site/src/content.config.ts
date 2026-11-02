import { defineCollection } from 'astro:content';
import { docsLoader, i18nLoader } from '@astrojs/starlight/loaders';
import { docsSchema, i18nSchema } from '@astrojs/starlight/schema';
import { docsVersionsLoader } from 'starlight-versions/loader';
import { z } from 'astro/zod';

// starlight-versions ships UI strings for en/de/es only. Extend the i18n schema
// with its keys so we can provide Russian translations in src/content/i18n/.
const starlightVersionsStrings = z
  .object({
    'starlightVersions.link.latest': z.string(),
    'starlightVersions.outdated.label': z.string(),
    'starlightVersions.outdated.slug': z.string(),
    'starlightVersions.search.link.latest': z.string(),
    'starlightVersions.search.outdated.label': z.string(),
    'starlightVersions.search.outdated.slug': z.string(),
    'starlightVersions.select.accessibleLabel': z.string(),
  })
  .partial();

export const collections = {
  docs: defineCollection({ loader: docsLoader(), schema: docsSchema() }),
  versions: defineCollection({ loader: docsVersionsLoader() }),
  i18n: defineCollection({
    loader: i18nLoader(),
    schema: i18nSchema({ extend: starlightVersionsStrings }),
  }),
};
