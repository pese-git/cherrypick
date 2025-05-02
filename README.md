# CherryPick Workspace

Welcome to the CherryPick Workspace, a comprehensive suite for dependency management in Flutter applications. It consists of the `cherrypick` and `cherrypick_flutter` packages, designed to enhance modularity and testability by providing robust dependency and state management tools.

## Overview

- **`cherrypick`**: A Dart library offering core tools for dependency injection and management through modules and scopes.
- **`cherrypick_flutter`**: A Flutter-specific library facilitating access to the root scope via the context using `CherryPickProvider`, simplifying state management within the widget tree.

## Repository Structure

- **Packages**:
  - `cherrypick`: Core DI functionalities.
  - `cherrypick_flutter`: Flutter integration for context-based root scope access.

## Quick Start Guide

### Installation

To add the packages to your project, include the dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  cherrypick: any
  cherrypick_flutter: any
```

Run `flutter pub get` to install the dependencies.

### Usage

#### cherrypick

- **Binding Dependencies**: Use `Binding` to set up dependencies.

  ```dart
  Binding<String>().toInstance("hello world");
  Binding<String>().toProvide(() => "hello world").singleton();
  ```

- **Creating Modules**: Define dependencies within a module.

  ```dart
  class AppModule extends Module {
    @override
    void builder(Scope currentScope) {
      bind<ApiClient>().toInstance(ApiClientMock());
    }
  }
  ```

- **Managing Scopes**: Control dependency lifecycles with scopes.

  ```dart
  final rootScope = Cherrypick.openRootScope();
  rootScope.installModules([AppModule()]);
  final apiClient = rootScope.resolve<ApiClient>();
  ```

#### cherrypick_flutter

- **CherryPickProvider**: Wrap your widget tree to access the root scope via context.

  ```dart
  void main() {
    runApp(CherryPickProvider(
      rootScope: yourRootScopeInstance,
      child: MyApp(),
    ));
  }
  ```

- **Accessing Root Scope**: Use `CherryPickProvider.of(context).rootScope` to interact with the root scope in your widgets.

  ```dart
  final rootScope = CherryPickProvider.of(context).rootScope;
  ```

### Example Project

Check the `example` directory for a complete demonstration of implementing CherryPick Workspace in a Flutter app.

## Features

- [x] Dependency Binding and Resolution
- [x] Custom Module Creation
- [x] Root and Sub-Scopes
- [x] Convenient Root Scope Access in Flutter

## Contributing

We welcome contributions from the community. Feel free to open issues or submit pull requests with suggestions and enhancements.

## License

This project is licensed under the Apache License 2.0. You may obtain a copy of the License at [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

## Links

- [GitHub Repository](https://github.com/pese-git/cherrypick)