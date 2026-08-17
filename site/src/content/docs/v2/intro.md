---
title: Introduction
description: What CherryPick 2.x offers and how its packages fit together.
---

:::caution[Archived version]
This documents CherryPick **2.x** (2.2.0). For the current release, see the
[latest documentation](/getting-started/).
:::

**CherryPick** is a modern dependency injection (DI) toolkit for Dart and
Flutter. It combines a concise runtime API with optional annotations and code
generation, so you can wire dependencies by hand or let the generator do it.

## Advantages

- 📦 Simple declarative API for registering and resolving dependencies
- ⚡️ Full support for both sync and async registrations
- 🧩 DI via annotations with code generation, including field injection
- 🏷️ Named bindings for multiple implementations of an interface
- 🏭 Parameterized bindings for runtime factories (e.g. by ID)
- 🌲 Flexible scope system for dependency isolation and hierarchy
- 🕹️ Optional resolution with `tryResolve`
- 🐞 Clear compile-time errors for invalid annotation or DI configuration

## Packages

| Package | Purpose |
| ------- | ------- |
| [`cherrypick`](https://pub.dev/packages/cherrypick) | Runtime DI core |
| [`cherrypick_annotations`](https://pub.dev/packages/cherrypick_annotations) | DI annotations |
| [`cherrypick_generator`](https://pub.dev/packages/cherrypick_generator) | DI code generation |
| [`cherrypick_flutter`](https://pub.dev/packages/cherrypick_flutter) | Flutter integration (`CherryPickProvider`) |

CherryPick is not just for Flutter — all core features work in Dart CLI tools,
servers, and microservices.

## Next steps

- [Installation](/v2/installation/)
- [Quick Start](/v2/getting-started/) — bindings, modules, and scopes
- [Bindings](/v2/bindings/) · [Scopes](/v2/scopes/) · [Using Annotations](/v2/using-annotations/)
