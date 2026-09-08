---
title: Linting
description: Catch CherryPick API misuse in the IDE with cherrypick_lint.
---

[`cherrypick_lint`](https://github.com/pese-git/cherrypick/tree/master/cherrypick_lint) is an
[analyzer plugin](https://pub.dev/packages/analysis_server_plugin) that catches CherryPick API
misuse in the IDE and in `dart analyze` — no `build_runner` required. This page shows what each rule catches, with a
bad/good example, and how to install and configure it.

> `cherrypick_generator` already validates annotations, but only when you run codegen.
> `cherrypick_lint` surfaces the same class of mistakes — plus a few runtime traps codegen can't see —
> as you type.

## Install

The plugin is not a dependency of your project — the analysis server resolves it itself.
Name it in the top-level `plugins` section of `analysis_options.yaml`:

```yaml
# analysis_options.yaml
plugins:
  cherrypick_lint: ^1.0.0
```

Requires Dart >=3.10 (Flutter >=3.38).

Restart the Dart Analysis Server afterwards (in VS Code: *Dart: Restart Analysis Server*) —
analyzer plugins are only picked up on start-up. The rules then appear both in the IDE and in
`dart analyze` / `flutter analyze`, so CI needs no extra step.

## await-rules

Missing `await` on scope disposal means resources may not actually be freed by the next line.
Wrapping the call in `unawaited(...)` is treated as an explicit, intentional fire-and-forget and
doesn't trigger these rules.

### `avoid_unawaited_close_sub_scope`

```dart
// ❌ avoid_unawaited_close_sub_scope
scope.closeSubScope('feature');

// ✅
await scope.closeSubScope('feature');
```

### `avoid_unawaited_close_scope`

```dart
// ❌ avoid_unawaited_close_scope
CherryPick.closeScope(scopeName: 'feature');

// ✅
await CherryPick.closeScope(scopeName: 'feature');
```

### `avoid_unawaited_scope_dispose`

```dart
// ❌ avoid_unawaited_scope_dispose
scope.dispose();

// ✅
await scope.dispose();
```

## annotation-rules

The same class of mistakes `cherrypick_generator`'s `AnnotationValidator` throws on at build
time — caught in the IDE instead, before you run the generator.

### `module_must_be_abstract`

```dart
// ❌ module_must_be_abstract
@module()
class AppModule {
  @provide()
  Api api() => Api();
}

// ✅
@module()
abstract class AppModule {
  @provide()
  Api api() => Api();
}
```

### `module_method_missing_binding`

```dart
@module()
abstract class AppModule {
  // ❌ module_method_missing_binding — no @provide/@instance
  Api api() => Api();

  // ✅
  @provide()
  Api api() => Api();
}
```

### `inject_field_must_be_late_final`

```dart
class ProfileScreen with _$ProfileScreen {
  // ❌ inject_field_must_be_late_final
  @inject()
  UserManager manager;

  // ✅
  @inject()
  late final UserManager manager;
}
```

### `named_value_must_not_be_empty`

```dart
// ❌ named_value_must_not_be_empty
@named('')
ApiClient mockApi() => MockApiClient();

// ✅
@named('mock')
ApiClient mockApi() => MockApiClient();
```

### `params_requires_provide`

```dart
@module()
abstract class FeatureModule {
  // ❌ params_requires_provide
  @params()
  UserManager createManager(Map<String, dynamic> args) => ...;

  // ✅
  @provide()
  @params()
  UserManager createManager(Map<String, dynamic> args) => ...;
}
```

## runtime-trap-rules

Footguns that only show up at runtime — `cherrypick_generator` can't see these since they're not
annotation misuse.

### `avoid_extends_silent_observer`

`Scope` fast-paths `if (_observer is SilentCherryPickObserver)`, so a subclass created via
`extends` silently receives **none** of the 14 observer callbacks.

```dart
// ❌ avoid_extends_silent_observer
class MyObserver extends SilentCherryPickObserver {}

// ✅
class MyObserver implements CherryPickObserver {
  // ... implement all 14 methods
}
```

### `avoid_redundant_singleton_on_instance` (info)

Per `Binding.singleton()`'s own doc comment, chaining it after `.toInstance()`/`.toInstanceAsync()`
has no effect — the bound value is already a single, constant instance. `.singleton()` only means
something after a provider.

```dart
// ℹ️ avoid_redundant_singleton_on_instance
bind<Api>().toInstance(ApiMock()).singleton();

// ✅
bind<Api>().toInstance(ApiMock());
// or, if you actually want lazy single-instance creation:
bind<Api>().toProvide(() => ApiMock()).singleton();
```

### `avoid_singleton_on_provide_with_params` (info, no quick fix)

`.singleton()` after `.toProvideWithParams()`/`.toProvideAsyncWithParams()` turns the binding into
a "master singleton": only the very first `resolve<T>(params: ...)` uses its parameters, every
later resolve returns the same cached instance regardless of params. That's sometimes exactly what
you want, so this rule has no quick fix — it's a nudge to double-check intent.

```dart
// ℹ️ avoid_singleton_on_provide_with_params
bind<Service>().toProvideWithParams((params) => Service(params)).singleton();

// fine if a new instance per params is intended — just drop .singleton()
bind<Service>().toProvideWithParams((params) => Service(params));
```

### `avoid_resolve_in_to_instance` (warning, no quick fix)

`.toInstance(...)` bindings inside a `Module.builder` are applied sequentially, so calling
`scope.resolve<T>()` (or `resolveAsync`/`tryResolve`/`tryResolveAsync`) to build the value can throw
`Can't resolve dependency ...` if `T` is registered later in the same builder. Deferring the resolve
with `.toProvide(() => ...)` runs it lazily, once every sibling binding is already registered.

```dart
// ❌ avoid_resolve_in_to_instance
bind<int>().toInstance(scope.resolve<String>().length);

// ✅
bind<int>().toProvide(() => scope.resolve<String>().length);
```

### `avoid_precomputed_value_in_provide` (warning, no quick fix)

A provider closure exists to be re-invoked on every `resolve<T>()` — the value should be built
there. If the closure just returns a variable built earlier in the same method, that value was
actually constructed once, at `Module.builder()` time, so every `resolve<T>()` silently returns the
same instance — an unintended pseudo-singleton that bypasses `.singleton()`'s explicit opt-in.
`.toInstance(...)` isn't affected by this: it always constructs eagerly regardless of where the
value comes from, so precomputing a value for it is fine.

```dart
// ❌ avoid_precomputed_value_in_provide
final api = ApiMock();
bind<Api>().toProvide(() => api);

// ✅
bind<Api>().toProvide(() => ApiMock());
```

## Disabling a rule

```yaml
# analysis_options.yaml
plugins:
  cherrypick_lint:
    version: ^1.0.0
    diagnostics:
      avoid_extends_silent_observer: false
```

A single line or file can be exempted with an ignore comment, using the `<plugin>/<rule>` form:

```dart
// ignore: cherrypick_lint/avoid_unawaited_scope_dispose
scope.dispose();
```

## References

- [cherrypick_lint README](https://github.com/pese-git/cherrypick/blob/master/cherrypick_lint/README.md) — full rule table, compatibility, contributing
- [Using Annotations](/using-annotations/)
- [Documentation Links](/documentation-links/)
