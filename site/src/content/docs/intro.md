---
title: "Overview"
description: What CherryPick is, what it can do, and where to go next.
---

**CherryPick** is a lightweight, modular dependency injection toolkit for Dart and Flutter.
You describe how to build your services in **modules**, install the modules into a
**scope**, and resolve dependencies from that scope — synchronously or asynchronously,
by type or by name. Scopes form a tree, so features and screens can get their own
isolated dependencies and release them deterministically.

CherryPick works in pure Dart (CLI, server) and in Flutter apps, and you can wire it by
hand or let `cherrypick_generator` write the wiring from annotations.

## Key features

**Scopes and composition**

- [Root scope and named subscopes](/core-concepts/scope/), nested to any depth — see [Hierarchical Subscopes](/advanced-features/hierarchical-subscopes/)
- [Modular composition](/core-concepts/module/): group related bindings into modules

**Bindings and resolution**

- [Synchronous and asynchronous providers](/core-concepts/binding/)
- [Providers with runtime parameters](/core-concepts/binding/)
- [Named instances](/core-concepts/binding/) for several implementations of one type
- [Singleton lifecycle](/core-concepts/binding/)
- [Null-safe resolution](/dependency-resolution-api/) with `tryResolve` / `tryResolveAsync`

**Reliability and tooling**

- [Automatic cleanup](/core-concepts/disposable/) of every registered `Disposable`
- [Circular dependency detection](/advanced-features/circular-dependency-detection/), within one scope or across scopes
- [Logging](/advanced-features/logging/) of DI state and events through observers
- [Annotations and code generation](/using-annotations/) to remove boilerplate
- [IDE lint plugin](/linting/) (`cherrypick_lint`) that catches API misuse as you type

## Packages

| Package | Purpose |
|---------|---------|
| `cherrypick` | Runtime DI core: scopes, modules, bindings |
| `cherrypick_flutter` | `CherryPickProvider` for the widget tree |
| `cherrypick_annotations` + `cherrypick_generator` | Annotation-driven code generation |
| `talker_cherrypick_logger` | DI event logging via [Talker](https://pub.dev/packages/talker) |
| `cherrypick_lint` | Analyzer plugin for the IDE and `dart analyze` |

More details and links are in [Packages & Resources](/documentation-links/).

## Where to go next

1. [Install](/installation/) the packages.
2. Follow the [Quick Start](/getting-started/) to build your first module and scope.
3. Read the [Core Concepts](/core-concepts/binding/) once the basics click.
