---
title: Введение
description: Что предлагает CherryPick 2.x и как связаны его пакеты.
---

:::caution[Архивная версия]
Это документация CherryPick **2.x** (2.2.0). Актуальный релиз смотрите в
[последней документации](/ru/getting-started/).
:::

**CherryPick** — это современный инструментарий внедрения зависимостей (DI) для
Dart и Flutter. Он сочетает лаконичный runtime-API с опциональными аннотациями и
кодогенерацией: связывайте зависимости вручную или доверьте это генератору.

## Преимущества

- 📦 Простой декларативный API для регистрации и получения зависимостей
- ⚡️ Полная поддержка синхронной и асинхронной регистрации
- 🧩 DI через аннотации с кодогенерацией, включая field injection
- 🏷️ Именованные биндинги для нескольких реализаций интерфейса
- 🏭 Параметризованные биндинги для runtime-фабрик (например, по ID)
- 🌲 Гибкая система скоупов для изоляции и иерархии зависимостей
- 🕹️ Опциональное получение через `tryResolve`
- 🐞 Понятные ошибки на этапе компиляции при неверных аннотациях или конфигурации DI

## Пакеты

| Пакет | Назначение |
| ----- | ---------- |
| [`cherrypick`](https://pub.dev/packages/cherrypick) | Ядро DI (runtime) |
| [`cherrypick_annotations`](https://pub.dev/packages/cherrypick_annotations) | Аннотации DI |
| [`cherrypick_generator`](https://pub.dev/packages/cherrypick_generator) | Кодогенерация DI |
| [`cherrypick_flutter`](https://pub.dev/packages/cherrypick_flutter) | Интеграция с Flutter (`CherryPickProvider`) |

CherryPick — не только для Flutter: все основные возможности работают в Dart CLI,
на сервере и в микросервисах.

## Дальше

- [Установка](/ru/v2/installation/)
- [Быстрый старт](/ru/v2/getting-started/) — биндинги, модули и скоупы
- [Биндинги](/ru/v2/bindings/) · [Скоупы](/ru/v2/scopes/) · [Аннотации](/ru/v2/using-annotations/)
