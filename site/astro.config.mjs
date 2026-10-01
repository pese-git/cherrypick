// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightVersions from 'starlight-versions';

const SITE = 'https://cherrypick.openidealab.com';

// https://astro.build/config
export default defineConfig({
  site: SITE,
  // Pages merged into others; archived versions (/vN/…) keep their own copies.
  redirects: {
    '/key-features': '/intro/',
    '/advanced-features/performance-improvements': '/faq/',
    '/additional-modules': '/documentation-links/',
    '/license': '/contributing/',
    '/ru/key-features': '/ru/intro/',
    '/ru/advanced-features/performance-improvements': '/ru/faq/',
    '/ru/additional-modules': '/ru/documentation-links/',
    '/ru/license': '/ru/contributing/',
  },
  integrations: [
    starlight({
      title: 'CherryPick',
      plugins: [
        starlightVersions({
          // The unversioned docs at the root are the latest (development) line.
          current: { label: '4.x (dev)' },
          // Archived versions. Add one at a time — the plugin snapshots a single
          // new version per build run.
          versions: [
            { slug: 'v3', label: '3.x' },
            { slug: 'v2', label: '2.x' },
            { slug: 'v1', label: '1.x' },
          ],
        }),
      ],
      description:
        'Lightweight, modular dependency injection for Dart & Flutter — hierarchical scopes, sync & async providers, code generation.',
      logo: {
        light: './src/assets/logo.svg',
        dark: './src/assets/logo.svg',
        replacesTitle: false,
      },
      favicon: '/favicon.svg',
      // Social preview; regenerate with `node scripts/og-image.mjs`.
      head: [
        { tag: 'meta', attrs: { property: 'og:image', content: `${SITE}/og.png` } },
        { tag: 'meta', attrs: { property: 'og:image:width', content: '1200' } },
        { tag: 'meta', attrs: { property: 'og:image:height', content: '630' } },
        { tag: 'meta', attrs: { property: 'og:image:alt', content: 'CherryPick — Dependency Injection for Dart & Flutter' } },
        { tag: 'meta', attrs: { name: 'twitter:image', content: `${SITE}/og.png` } },
      ],
      defaultLocale: 'root',
      locales: {
        root: { label: 'English', lang: 'en' },
        ru: { label: 'Русский', lang: 'ru' },
      },
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/pese-git/cherrypick',
        },
        {
          icon: 'telegram',
          label: 'Telegram',
          href: 'https://t.me/+22IVT0vqXBg1NDdi',
        },
      ],
      editLink: {
        baseUrl: 'https://github.com/pese-git/cherrypick/edit/master/site/',
      },
      customCss: ['./src/styles/custom.css'],
      components: {
        Header: './src/components/Header.astro',
      },
      sidebar: [
        {
          label: 'Getting Started',
          translations: { ru: 'Начало работы' },
          items: [
            { label: 'Overview', translations: { ru: 'Обзор' }, slug: 'intro' },
            { label: 'Installation', translations: { ru: 'Установка' }, slug: 'installation' },
            { label: 'Quick Start', translations: { ru: 'Быстрый старт' }, slug: 'getting-started' },
          ],
        },
        {
          label: 'Guides',
          translations: { ru: 'Руководства' },
          items: [
            { label: 'Dependency Resolution API', translations: { ru: 'API разрешения зависимостей' }, slug: 'dependency-resolution-api' },
            { label: 'Using Annotations', translations: { ru: 'Аннотации' }, slug: 'using-annotations' },
            { label: 'Linting', translations: { ru: 'Линтинг' }, slug: 'linting' },
            { label: 'Example Application', translations: { ru: 'Пример приложения' }, slug: 'example-application' },
          ],
        },
        {
          label: 'Core Concepts',
          translations: { ru: 'Основные концепции' },
          items: [
            { label: 'Binding', translations: { ru: 'Привязка (Binding)' }, slug: 'core-concepts/binding' },
            { label: 'Module', translations: { ru: 'Модуль' }, slug: 'core-concepts/module' },
            { label: 'Scope', translations: { ru: 'Скоуп (Scope)' }, slug: 'core-concepts/scope' },
            { label: 'Disposable', translations: { ru: 'Disposable' }, slug: 'core-concepts/disposable' },
          ],
        },
        {
          label: 'Advanced Features',
          translations: { ru: 'Продвинутые возможности' },
          items: [
            { label: 'Hierarchical Subscopes', translations: { ru: 'Иерархические подскоупы' }, slug: 'advanced-features/hierarchical-subscopes' },
            { label: 'Logging', translations: { ru: 'Логирование' }, slug: 'advanced-features/logging' },
            { label: 'Circular Dependency Detection', translations: { ru: 'Обнаружение циклов' }, slug: 'advanced-features/circular-dependency-detection' },
          ],
        },
        {
          label: 'Help & Reference',
          translations: { ru: 'Справка' },
          items: [
            { label: 'FAQ', translations: { ru: 'FAQ' }, slug: 'faq' },
            { label: 'Packages & Resources', translations: { ru: 'Пакеты и ресурсы' }, slug: 'documentation-links' },
            { label: 'Contributing & License', translations: { ru: 'Участие и лицензия' }, slug: 'contributing' },
          ],
        },
      ],
    }),
  ],
});
