---
title: Quick Start
description: The main DI components in CherryPick 1.x — Binding, Module, and Scope.
---

This guide walks through the three core components of CherryPick 1.x.

## Main DI components

### Binding

A `Binding` configures how a dependency is created. It has two primary methods,
`toInstance()` and `toProvide()`, plus the helpers `withName()` and `singleton()`.

- `toInstance()` — takes an already-created instance.
- `toProvide()` — takes a `provider` function (an instance constructor).
- `withName()` — takes a string used to name the instance, so it can later be
  resolved by that name from the container.
- `singleton()` — marks the binding as a singleton: the container creates a
  single shared instance.

```dart
// Provide a ready instance via toInstance()
Binding<String>().toInstance("hello world");

// Provide a lazily-created instance via a factory
Binding<String>().toProvide(() => "hello world");

// Named instance
Binding<String>().withName("my_string").toInstance("hello world");
// or
Binding<String>().withName("my_string").toProvide(() => "hello world");

// Singleton
Binding<String>().toInstance("hello world");
// or
Binding<String>().toProvide(() => "hello world").singleton();
```

### Module

A `Module` is a container of bindings. Subclass it and implement
`void builder(Scope currentScope)`, registering your dependencies with `bind<T>()`.

```dart
class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().toInstance(ApiClientMock());
  }
}
```

### Scope

A `Scope` is a container that holds the whole dependency tree (scopes, modules,
instances). Resolve a dependency with `resolve<T>()`, passing the type and any
extra parameters. Use `tryResolve<T>()` to get `null` instead of throwing when a
dependency is not found.

```dart
// Open the root scope
final rootScope = CherryPick.openRootScope();

// Install a module
rootScope.installModules([AppModule()]);

// Resolve an instance
final client = rootScope.resolve<ApiClient>();
// or, without throwing when missing:
final maybeClient = rootScope.tryResolve<ApiClient>();

// Close the root scope
CherryPick.closeRootScope();
```

Continue with a full [example application](/v1/example-application/).
