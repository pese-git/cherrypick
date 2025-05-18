# CherryPick Workspace

CherryPick Workspace is a modular ecosystem for declarative, type-safe dependency injection in Dart and Flutter applications. It brings together core dependency management, advanced code generation, annotation-driven DI, and seamless Flutter integration for stateful, testable, and scalable app architectures.

---

## Overview

CherryPick Workspace includes the following packages:

- **`cherrypick`** – Core dependency injection engine for Dart: bindings, modules, scopes, and runtime resolution.
- **`cherrypick_annotations`** – Lightweight annotation library (`@module`, `@singleton`, `@named`) for injectable code and code generation.
- **`cherrypick_generator`** – Code generator that produces DI module boilerplate from annotated Dart classes, using `cherrypick_annotations`.
- **`cherrypick_flutter`** – Flutter integration providing scope-aware dependency resolution via `CherryPickProvider` in the widget tree.

---

## Repository Structure

- `cherrypick/` – Core DI library (bindings, modules, scopes, runtime resolution)
- `cherrypick_annotations/` – DI annotations for use with generators
- `cherrypick_generator/` – Source-gen implementation for codegen of modules and bindings
- `cherrypick_flutter/` – Flutter tools to provide DI in widget subtree via `CherryPickProvider`
- `examples/` – Sample Flutter projects demonstrating patterns

---

## Quick Start Guide

### Installation

Add the desired packages to your `pubspec.yaml` (pick what you need):

```yaml
dependencies:
  cherrypick: ^latest
  cherrypick_annotations: ^latest
  cherrypick_flutter: ^latest

dev_dependencies:
  cherrypick_generator: ^latest
  build_runner: ^latest
```

Run `flutter pub get` or `dart pub get` to fetch dependencies.

---

### Usage

#### Core DI (`cherrypick`)

- **Bind dependencies:**

  ```dart
  Binding<String>().toInstance("hello world");
  Binding<ApiClient>().toProvide(() => ApiClientImpl()).singleton();
  ```

- **Module definition:**

  ```dart
  class AppModule extends Module {
    @override
    void builder(Scope currentScope) {
      bind<ApiClient>().toInstance(ApiClientMock());
    }
  }
  ```

- **Scope management:**

  ```dart
  final rootScope = CherryPick.openRootScope();
  rootScope.installModules([AppModule()]);
  final client = rootScope.resolve<ApiClient>();
  ```

  You can create sub-scopes for feature isolation as needed:

  ```dart
  final featureScope = rootScope.openSubScope("feature");
  featureScope.installModules([FeatureModule()]);
  ```

#### Annotation & Code Generation (`cherrypick_annotations`, `cherrypick_generator`)

- **Annotate your DI modules:**

  ```dart
  import 'package:cherrypick_annotations/cherrypick_annotations.dart';
  import 'package:cherrypick/cherrypick.dart';
  
  part 'app_module.cherrypick.g.dart';

  @module()
  abstract class AppModule extends Module {
    @singleton()
    ApiClient client() => ApiClientImpl();

    @named('apiBaseUrl')
    String baseUrl() => 'https://api.example.com';
  }
  ```

- **Generate code:**

  Run:

  ```shell
  dart run build_runner build
  ```

  This will generate efficient registration code for your modules.

#### Flutter Integration (`cherrypick_flutter`)

- **Setup `CherryPickProvider` in your widget tree:**

  ```dart
  void main() {
    runApp(
      CherryPickProvider(
        child: MyApp(),
      ),
    );
  }
  ```

- **Access DI scopes anywhere in Flutter:**

  ```dart
  class MyWidget extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      final cherryPick = CherryPickProvider.of(context);
      final rootScope = cherryPick.openRootScope();

      final repo = rootScope.resolve<MyRepository>();
      // use repo as needed...

      return Text('Dependency resolved!');
    }
  }
  ```

---

## Features

- [x] Module-based configuration & composition
- [x] Flexible scopes (main/root/subscopes)
- [x] Named and singleton bindings
- [x] Async binding and parameter injection
- [x] Annotations (`@module`, `@singleton`, `@named`) for concise setup
- [x] Code generation for efficient, boilerplate-free DI modules
- [x] Seamless integration with Flutter via InheritedWidget (`CherryPickProvider`)

---

## Example Projects

See the [`examples/`](examples/) directory for real-world usage patterns, including synchronous, asynchronous, and named injection in Flutter apps.

---

## Contributing

Community feedback, bug reports, and PRs are welcome! Please file issues and suggestions on the [GitHub issues page](https://github.com/pese-git/cherrypick/issues).

---

## License

CherryPick Workspace is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

---

## Links

- [CherryPick GitHub Repository](https://github.com/pese-git/cherrypick)
- [cherrypick_flutter on pub.dev](https://pub.dev/packages/cherrypick_flutter)
- [cherrypick_generator on pub.dev](https://pub.dev/packages/cherrypick_generator)
- [cherrypick_annotations on pub.dev](https://pub.dev/packages/cherrypick_annotations)
```