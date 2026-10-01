---
title: "Quick Start"
description: Your first module, scope, and resolution — in Dart and in Flutter.
---

This page walks through the minimum you need to wire an app with CherryPick. It assumes
you have already [installed](/installation/) the `cherrypick` package.

## 1. Describe a module

A [module](/core-concepts/module/) groups the [bindings](/core-concepts/binding/) that
tell CherryPick how to build each dependency. Override `builder` and call `bind<T>()`
for every type you want to provide:

```dart
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    // A ready-made instance.
    bind<ApiClient>().toInstance(ApiClientMock());

    // A factory, called on every resolve.
    bind<String>().toProvide(() => "Hello, CherryPick!");
  }
}
```

## 2. Open a scope and install the module

The root [scope](/core-concepts/scope/) is the top of the dependency tree. Install your
modules into it once, at startup:

```dart
final rootScope = CherryPick.openRootScope();
rootScope.installModules([AppModule()]);
```

## 3. Resolve dependencies

Ask the scope for a type. Use `resolveAsync` for async bindings and `tryResolve` when a
missing binding is a normal case rather than an error — see the
[Dependency Resolution API](/dependency-resolution-api/).

```dart
final greeting = rootScope.resolve<String>();
print(greeting); // prints: Hello, CherryPick!
```

## 4. Close the scope

When the app (or test) is done, close the scope. This disposes every
[`Disposable`](/core-concepts/disposable/) the scope owns. Always `await` it — even if
nothing is disposable today:

```dart
await CherryPick.closeRootScope();
```

## Using it in Flutter

Add `cherrypick_flutter` and wrap your app in `CherryPickProvider`. Widgets below it can
reach the scopes through `CherryPickProvider.of(context)`:

```dart
import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_flutter/cherrypick_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  CherryPick.openRootScope().installModules([AppModule()]);
  runApp(const CherryPickProvider(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = CherryPickProvider.of(context).openRootScope();
    return MaterialApp(home: Text(scope.resolve<String>()));
  }
}
```

`CherryPickProvider.of(context).openSubScope(scopeName: 'feature')` opens a
[subscope](/advanced-features/hierarchical-subscopes/) for a feature or a screen.

## Next steps

- [Using Annotations](/using-annotations/) — generate modules and field injection instead of writing them by hand.
- [Hierarchical Subscopes](/advanced-features/hierarchical-subscopes/) — isolate features and screens.
- [Example Application](/example-application/) — a complete app wired with CherryPick.
- [Linting](/linting/) — catch common mistakes in the IDE.
