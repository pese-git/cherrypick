# CherryPick pitfalls and `cherrypick_lint` rules

Use this list when reviewing CherryPick code. Rule names are `cherrypick_lint`
4.x diagnostics; enable the plugin so the user sees them in the IDE:

```yaml
# analysis_options.yaml
plugins:
  cherrypick_lint: ^4.0.0
```

Restart the Dart analysis server after adding it. Silence one line with
`// ignore: cherrypick_lint/<rule>`; disable a rule under
`plugins: cherrypick_lint: diagnostics: <rule>: false` (then the version moves to
`version: ^4.0.0`).

## Teardown

| Rule | Wrong | Right |
|---|---|---|
| `avoid_unawaited_close_sub_scope` | `scope.closeSubScope('x');` | `await scope.closeSubScope('x');` |
| `avoid_unawaited_close_scope` | `CherryPick.closeScope(scopeName: 'x');` | `await CherryPick.closeScope(scopeName: 'x');` |
| `avoid_unawaited_scope_dispose` | `scope.dispose();` | `await scope.dispose();` |

Wrapping in `unawaited(...)` is treated as intentional (e.g. in a widget's
synchronous `dispose()`).

## Module and annotation mistakes (mirror the generator)

| Rule | Problem |
|---|---|
| `module_requires_part_directive` | `@module` file without `part '<file>.module.cherrypick.g.dart';` — the build “succeeds” and generates nothing |
| `module_must_extend_module` | `@module` class without `extends Module` — generated code does not compile |
| `module_must_be_abstract` | concrete `@module` class |
| `module_method_missing_binding` | a method (private or static included) without `@provide()`/`@instance()` |
| `inject_field_must_be_late_final` | `@inject()` field that is not `late final` |
| `named_value_must_not_be_empty` | `@named('')` |
| `params_requires_provide` | `@params()` without `@provide()` |

Not covered by a lint rule but rejected by the generator: `@provide()` and
`@instance()` on the same method, `@singleton()` on a `void` method, and
`@named` values that are not identifiers (`'my-api'` → use `'myApi'`).

## Runtime traps

| Rule | Problem | Fix |
|---|---|---|
| `avoid_resolve_in_to_instance` (warning) | `bind<A>().toInstance(scope.resolve<B>())` — runs at install time; fails if `B` is bound later in the same `builder` | `toProvide(() => A(scope.resolve<B>()))` |
| `avoid_precomputed_value_in_provide` (warning) | `final api = Api(); bind<Api>().toProvide(() => api);` — a hidden singleton built at install time | build inside the closure; add `.singleton()` if one instance is wanted |
| `avoid_singleton_on_provide_with_params` (info) | `toProvideWithParams(...).singleton()` — first params win forever | drop `.singleton()` unless that is intended |
| `avoid_redundant_singleton_on_instance` (info) | `toInstance(x).singleton()` — no effect | drop `.singleton()`, or use `toProvide(...).singleton()` for laziness |
| `avoid_extends_silent_observer` | `class MyObserver extends SilentCherryPickObserver` — receives no callbacks | `implements CherryPickObserver` |

## Other mistakes to look for in review

- `resolve<T>()` on a binding created with `toProvideAsync`, a `Future`-returning
  `@provide()` method, or `toInstance(future)` → `StateError`; use `resolveAsync<T>()`.
- `resolve<Future<T>>()` for a generated async provider: the binding is for `T`.
- `toProvideAsync(() => syncValue)` → compile error in 4.x; use `toProvide`.
- Installing `AppModule()` instead of the generated `$AppModule()`.
- Calling a non-existent `injectFields()`; the generated method is `_inject(this)`.
- Expecting `@inject()` fields to come from a locally held scope — they come from
  `CherryPick.openRootScope()` / `openScope(scopeName:)`.
- Reopening a feature scope and installing the same modules again without closing it first.
- Registering a non-singleton `Disposable` in the root scope: every resolve adds
  an instance that is only disposed when the app closes the root.
- No cycle detection in debug/tests, so a cycle shows up as `StackOverflowError`.
- Tests sharing the root scope: missing `await CherryPick.closeRootScope()` in `tearDown`.
- Setting the global observer after `openRootScope()` — the existing root keeps the old one.
