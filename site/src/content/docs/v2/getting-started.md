---
title: Quick Start
description: The core DI components in CherryPick 2.x — Binding, Module, and Scope.
---

This guide covers the three core components of CherryPick 2.x. For the full
binding API see [Bindings](/v2/bindings/), and for the scope tree see
[Scopes](/v2/scopes/).

## Main DI components

### Binding

A `Binding` configures how a dependency is created. The primary methods are
`toInstance()` and `toProvide()`, plus the helpers `withName()` and `singleton()`.

- `toInstance()` — takes an already-created instance.
- `toProvide()` — takes a `provider` function (an instance constructor).
- `withName()` — names the instance so it can be resolved by that name.
- `singleton()` — marks the binding as a singleton within its scope.

```dart
// Ready instance
Binding<String>().toInstance("hello world");

// Lazy factory
Binding<String>().toProvide(() => "hello world");

// Named instance
Binding<String>().withName("my_string").toProvide(() => "hello world");

// Singleton
Binding<String>().toProvide(() => "hello world").singleton();
```

### Module

A `Module` is a container of bindings. Subclass it and implement
`void builder(Scope currentScope)`, registering dependencies with `bind<T>()`.

```dart
class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().toInstance(ApiClientMock());
  }
}
```

### Scope

A `Scope` holds the whole dependency tree. Resolve a dependency with
`resolve<T>()`, or `tryResolve<T>()` to get `null` instead of throwing when it is
not found.

```dart
// Open the root scope
final rootScope = CherryPick.openRootScope();

// Install a module
rootScope.installModules([AppModule()]);

// Resolve
final client = rootScope.resolve<ApiClient>();
// or, without throwing:
final maybeClient = rootScope.tryResolve<ApiClient>();

// Close the root scope
CherryPick.closeRootScope();
```

## Next steps

- [Bindings](/v2/bindings/) — async, named, and parameterized bindings.
- [Scopes](/v2/scopes/) — named scopes and hierarchy.
- [Using Annotations](/v2/using-annotations/) — DI with code generation.
- [Example Application](/v2/example-application/) — a complete app.
