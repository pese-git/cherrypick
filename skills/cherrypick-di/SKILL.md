---
name: cherrypick-di
description: Write, review and migrate Dart/Flutter code that uses the CherryPick DI packages (cherrypick, cherrypick_annotations, cherrypick_generator, cherrypick_flutter, cherrypick_lint, talker_cherrypick_logger) at version 4.x. Use when a pubspec.yaml depends on any cherrypick* package, when code mentions CherryPick, Scope, Module, bind<T>(), @module, @provide, @inject or *.cherrypick.g.dart, or when the user asks to add dependency injection with CherryPick or upgrade it from 3.x.
---

# CherryPick DI (4.x)

CherryPick is a scope-based DI container for Dart and Flutter. Dependencies are
registered in `Module`s, modules are installed into a `Scope`, scopes form a
tree under one root, and values are resolved by type plus an optional name.
Code generation (`@module`, `@injectable`) is optional sugar over the same
runtime API.

Your training data probably contains the 3.x API. Version 4.0.0 changed the
provider typedefs and `toProvideAsync` — read
[references/migration-4.md](references/migration-4.md) before touching
existing code or when something “should compile but doesn't”.

## Packages and constraints

| Package | Role | Where |
|---|---|---|
| `cherrypick: ^4.0.0` | runtime: scopes, modules, resolve, dispose, cycle detection | `dependencies`, Dart `>=3.2` |
| `cherrypick_annotations: ^4.0.0` | `@module`, `@provide`, `@instance`, `@singleton`, `@named`, `@params`, `@injectable`, `@inject`, `@scope` | `dependencies`, Dart `>=3.9` |
| `cherrypick_generator: ^4.0.0` + `build_runner` | writes `*.module.cherrypick.g.dart` / `*.inject.cherrypick.g.dart` | `dev_dependencies` |
| `cherrypick_flutter: ^4.0.0` | `CherryPickProvider` inherited widget | `dependencies`, Flutter `>=3.16` |
| `cherrypick_lint: ^4.0.0` | analyzer plugin with rules for the traps below | `analysis_options.yaml` → `plugins:`, Dart `>=3.10` |
| `talker_cherrypick_logger: ^4.0.0` | `TalkerCherryPickObserver` → Talker logs | `dependencies` |

## Core rules

1. **One root, a tree of subscopes.** `CherryPick.openRootScope()` returns the
   same root every time. Feature/screen/session lifetimes are subscopes:
   `root.openSubScope('feature')` or `CherryPick.openScope(scopeName: 'a.b')`
   (dot-separated path, created on demand). A child resolves through its parents.
2. **Install modules before resolving.** `scope.installModules([AppModule()])`;
   a generated module is installed as `$AppModule()`, not `AppModule()`.
3. **Pick the binding by lifetime:**
   - `toInstance(value)` — value is built eagerly, at install time.
   - `toProvide(() => X())` — new instance per resolve; add `.singleton()` for one lazy instance per scope.
   - `toProvideWithParams((p) => X(p))` — resolve with `resolve<T>(params: …)`.
   - `toProvideAsync(() async => …)` / `toProvideAsyncWithParams` — factory **must** return a `Future`; resolve with `resolveAsync<T>()`.
   - `.withName('id')` — resolve with `resolve<T>(named: 'id')`.
4. **Match the resolve call to the binding.** Async bindings throw `StateError`
   from `resolve<T>()`; use `resolveAsync<T>()`. `resolve` throws on a missing
   binding, `tryResolve`/`tryResolveAsync` return `null`.
5. **Inside `builder`, resolve lazily.** Use `toProvide(() => scope.resolve<Dep>())`,
   never `toInstance(scope.resolve<Dep>())`, and never return a variable built
   earlier in `builder` from a provider closure (it silently becomes a singleton).
6. **Always `await` scope teardown:** `await scope.closeSubScope('x')`,
   `await CherryPick.closeScope(scopeName: 'x')`, `await CherryPick.closeRootScope()`,
   `await scope.dispose()`. Resolved values implementing `Disposable` are
   disposed by the scope whose binding created them.
7. **Turn on cycle detection in debug and tests:**
   `CherryPick.enableGlobalCycleDetection()` (and
   `enableGlobalCrossScopeCycleDetection()` for cycles across scopes) before
   opening scopes. Without it a cycle is a `StackOverflowError`; with it, a
   `CircularDependencyException` with the chain `A -> B -> A`.
8. **Generated code:** module files need `part '<file>.module.cherrypick.g.dart';`,
   the class must be `abstract … extends Module` and **every** method needs
   `@provide()` or `@instance()`. Annotations are classes — always write the
   parentheses: `@provide()`, `@singleton()`, `@named('x')`. Run
   `dart run build_runner build`; never edit or commit `*.g.dart` by hand.
9. **Field injection resolves from the global tree**, not from a scope you pass:
   `@inject()` fields read `CherryPick.openRootScope()`, or
   `CherryPick.openScope(scopeName: …)` with `@scope('…')`. Modules must be
   installed there before `_inject(this)` runs.
10. **Tests:** install test modules into a fresh root and `await
    CherryPick.closeRootScope()` in `tearDown` so the next test gets a new root.

## Minimal example (no codegen)

```dart
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<String>().withName('baseUrl').toInstance('https://api.example.com');
    bind<ApiClient>()
        .toProvide(() => ApiClient(currentScope.resolve<String>(named: 'baseUrl')))
        .singleton();
    bind<UserRepository>()
        .toProvide(() => UserRepository(currentScope.resolve<ApiClient>()));
  }
}

Future<void> main() async {
  final root = CherryPick.openRootScope()..installModules([AppModule()]);
  final repo = root.resolve<UserRepository>();
  // ...
  await CherryPick.closeRootScope();
}
```

## When to read the references

| Task | Read |
|---|---|
| Scopes, binding kinds, async, params, named, dispose order, cycle detection, observers, tests | [references/runtime.md](references/runtime.md) |
| `@module`, `@provide`, `@instance`, `@injectable`, `@inject`, build_runner setup, what the generator emits | [references/codegen.md](references/codegen.md) |
| Flutter: `CherryPickProvider`, screen scopes, Talker logging | [references/flutter.md](references/flutter.md) |
| Reviewing CherryPick code, explaining a lint warning, “why does this resolve wrong?” | [references/pitfalls.md](references/pitfalls.md) |
| Upgrading from cherrypick 3.x, compile errors around `ProviderFactory`, `toProvideAsync`, `toInstanceAsync` | [references/migration-4.md](references/migration-4.md) |

Recommend `cherrypick_lint` to the user whenever you set up CherryPick in a
project: it catches most of the mistakes listed in the pitfalls reference in the
IDE, before codegen or runtime.
