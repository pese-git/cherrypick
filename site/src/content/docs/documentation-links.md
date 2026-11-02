---
title: Packages & Resources
description: CherryPick packages, extended guides, and source code.
---

## Packages

| Package | Description |
|---------|-------------|
| [**cherrypick**](https://pub.dev/packages/cherrypick) | Runtime DI core: scopes, modules, bindings, disposal, cycle detection. |
| [**cherrypick_flutter**](https://pub.dev/packages/cherrypick_flutter) | Flutter integration: `CherryPickProvider` exposes DI scopes to the widget tree. |
| [**cherrypick_annotations**](https://pub.dev/packages/cherrypick_annotations) | Dart annotations for concise DI definitions and code generation. |
| [**cherrypick_generator**](https://pub.dev/packages/cherrypick_generator) | `build_runner` generator that produces DI bindings from annotations. |
| [**talker_cherrypick_logger**](https://pub.dev/packages/talker_cherrypick_logger) | Logs DI events, errors, and diagnostics through [Talker](https://pub.dev/packages/talker), in the UI and the console. |
| [**cherrypick_lint**](https://pub.dev/packages/cherrypick_lint) | Analyzer plugin that catches API misuse — missing `await` on scope disposal, invalid annotation usage, runtime traps — in the IDE and in `dart analyze`. See [Linting](/linting/). |

## Extended guides in the repository

- [Full tutorial](https://github.com/pese-git/cherrypick/blob/master/doc/full_tutorial_en.md)
- [Annotations & code generation](https://github.com/pese-git/cherrypick/blob/master/doc/annotations_en.md)
- [Circular dependency detection](https://github.com/pese-git/cherrypick/blob/master/doc/cycle_detection.en.md)
- [Migrating to 4.0.0](https://github.com/pese-git/cherrypick/blob/master/doc/migration_4.0.0_en.md)
- [cherrypick_lint README](https://github.com/pese-git/cherrypick/blob/master/cherrypick_lint/README.md)

## Source

- [GitHub repository](https://github.com/pese-git/cherrypick)
- [Changelog](https://github.com/pese-git/cherrypick/blob/master/CHANGELOG.md)
