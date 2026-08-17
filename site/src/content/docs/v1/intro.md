---
title: Introduction
description: What CherryPick 1.x is and the core building blocks it provides.
---

:::caution[Archived version]
This documents CherryPick **1.x** (1.0.3). For the current release, see the
[latest documentation](/getting-started/).
:::

**CherryPick** is a lightweight dependency injection (DI) library for Dart and
Flutter. It lets you describe how your objects are created and wired together,
and resolve them on demand through a tree of scopes.

## Core building blocks

CherryPick 1.x is built around three concepts:

- **[Binding](/v1/getting-started/#binding)** — a configurator that describes how
  a single dependency is created (`toInstance()` / `toProvide()`), optionally
  named (`withName()`) or shared as a `singleton()`.
- **[Module](/v1/getting-started/#module)** — a container of bindings. You subclass
  `Module` and register dependencies inside `builder(Scope currentScope)`.
- **[Scope](/v1/getting-started/#scope)** — a container that holds the whole
  dependency tree (scopes, modules, instances). You resolve instances from a
  scope and open child scopes from it.

## Features

- Root and nested (sub) scopes
- Named instances
- Singleton and factory bindings

## Next steps

- [Installation](/v1/installation/) — add CherryPick to your project.
- [Quick Start](/v1/getting-started/) — bindings, modules, and scopes by example.
- [Example Application](/v1/example-application/) — a complete app.
