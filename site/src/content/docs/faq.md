---
title: "FAQ"
description: Common questions about scopes, bindings, disposal, performance, and code generation.
---

## Do I need `await` when closing a scope if nothing is `Disposable`?

Yes. Always `await` `CherryPick.closeRootScope()`, `CherryPick.closeScope()` and
`scope.dispose()`, even if none of your services implement `Disposable` today. If you
add cleanup later by implementing `dispose()`, CherryPick handles it automatically and
your shutdown code keeps working unchanged.

:::tip
[`cherrypick_lint`](/linting/) flags a missing `await` on scope disposal calls right in the IDE.
:::

## When should I use `tryResolve` instead of `resolve`?

Use `tryResolve<T>()` / `tryResolveAsync<T>()` when a missing binding is an expected
case: they return `null` if nothing is registered. `null` means "not registered", not
"failed" — asking for a registered binding the wrong way (for example `tryResolve` on an
async binding) still throws. See [Dependency Resolution API](/dependency-resolution-api/).

## Why do I get `Can't resolve dependency` inside a module's `builder`?

Bindings in `builder` are registered sequentially, so a type bound with `toInstance`
cannot `scope.resolve<T>()` another type registered in the same `builder` — it is not
available yet. Either build the chain by hand before calling `toInstance`, or use
`toProvide` / `toProvideAsync`, which resolve lazily.
See [Binding](/core-concepts/binding/).

## Does `.singleton()` do anything after `.toInstance()`?

No. An object passed to `toInstance()` is already a single instance returned on every
resolve. `.singleton()` only matters for providers such as `toProvide` / `toProvideAsync`.

## Why does a parameterized singleton ignore new params?

With `.toProvideWithParams(...).singleton()` only the **first**
`resolve<T>(params: ...)` uses its params; every later call returns the cached instance.
Drop `.singleton()` if you need a new instance per params.

## A subscope closed, but my `Disposable` was not disposed. Why?

A `Disposable` is owned by the scope that **declares its binding**, not the scope you
resolved it through. Resolving a parent's dependency via a subscope does not transfer
ownership. Declare the binding in the scope whose lifetime matches the resource.
See [Disposable → Ownership](/core-concepts/disposable/#ownership-which-scope-disposes-what).

## How do I catch circular dependencies?

Open a scope with `CherryPick.openSafeRootScope()` or call `scope.enableCycleDetection()`
for one scope; use `CherryPick.enableGlobalCrossScopeCycleDetection()` to track cycles
across scopes. A cycle throws `CircularDependencyException` with the full chain. Enable it
in debug and tests and turn it off in production.
See [Circular Dependency Detection](/advanced-features/circular-dependency-detection/).

## Does resolution get slower as the app grows?

No. Since version 3.0.0 CherryPick keeps a Map-based index of bindings, so `resolve<T>()`
and related calls are O(1) regardless of how many modules or bindings a scope has.
Earlier versions scanned every module and binding. The change is internal and did not
alter the API.

## The generator produces nothing for my `@module`. What is missing?

Check three things: the `part '<file>.module.cherrypick.g.dart';` directive, the class
`extends Module` and is `abstract`, and every method has `@provide` or `@instance`.
Then re-run `dart run build_runner build --delete-conflicting-outputs`.
[`cherrypick_lint`](/linting/) reports all of these before you run codegen.
See [Using Annotations](/using-annotations/).

## How do I use CherryPick in Flutter?

Wrap the app in `CherryPickProvider` from `cherrypick_flutter` and get scopes with
`CherryPickProvider.of(context).openRootScope()` or `.openSubScope(scopeName: ...)`.
See the [Quick Start](/getting-started/#using-it-in-flutter).
