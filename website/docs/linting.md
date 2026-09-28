---
sidebar_position: 5.5
---

# Linting

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
  cherrypick_lint: ^4.0.0-dev.0
```

Requires Dart >=3.10 (Flutter >=3.38).

The package is on [pub.dev](https://pub.dev/packages/cherrypick_lint). To try an unreleased
change, point the plugin at a local checkout of this repository instead:

```yaml
# analysis_options.yaml
plugins:
  cherrypick_lint:
    path: /absolute/path/to/cherrypick/cherrypick_lint
```

A version constraint, a constraint plus a `hosted` server URL, and a path are
the only forms the `plugins` section accepts.

Restart the Dart Analysis Server afterwards (in VS Code: *Dart: Restart Analysis Server*) —
analyzer plugins are only picked up on start-up. The rules then appear both in the IDE and in
`dart analyze` / `flutter analyze`, so CI needs no extra step.

## Which `cherrypick` versions

The plugin does not depend on `cherrypick` — it only reads your code — so nothing stops you
enabling it on any version. What differs is whether each rule's claim is true for the API you
actually have. This was checked by running the plugin on a file that violates every rule, and by
executing each claimed runtime behavior, against `cherrypick` 2.2.0, 3.0.0, 3.0.2 and 4.0.0-dev.6.

| `cherrypick` | Rules that apply |
|---|---|
| 4.x | All 15. |
| 3.x (tested: 3.0.0, 3.0.2) | 14 of 15. Not [`avoid_extends_silent_observer`](#avoid_extends_silent_observer): the fast path it warns about exists only in 4.x. Disable it there. |
| 2.x and older | Not supported. `closeScope` and `closeSubScope` are synchronous `void` and `Scope.dispose()` does not exist, so the await-rules flag calls with nothing to await and their quick fix produces a `use_of_void_result` error. `avoid_resolve_in_to_instance` and `avoid_singleton_on_provide_with_params` describe behavior 2.x does not have. |

Use the matching major of `cherrypick_annotations` and `cherrypick_generator`.

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

### `module_requires_part_directive`

`moduleBuilder` is a `PartBuilder`, so the part directive is what the generated
class is written into. Without it the build still succeeds and produces
nothing, warning only in the `build_runner` log.

```dart
// ❌ module_requires_part_directive — codegen writes nothing
@module()
abstract class AppModule extends Module {
  @provide()
  Api api() => Api();
}

// ✅
part 'app_module.module.cherrypick.g.dart';

@module()
abstract class AppModule extends Module {
  @provide()
  Api api() => Api();
}
```

### `module_must_extend_module`

The generated part is `final class $AppModule extends AppModule`, whose
`builder()` body is made of `bind<T>()` calls — both members come from
`Module`, so codegen emits a part that cannot compile.

```dart
// ❌ module_must_extend_module — generated part won't compile
@module()
abstract class AppModule {
  @provide()
  Api api() => Api();
}

// ✅
@module()
abstract class AppModule extends Module {
  @provide()
  Api api() => Api();
}
```

### `module_must_be_abstract`

The generator doesn't check the modifier itself, but a concrete `@module` class
is a dead end either way: `Module.builder` is abstract, so without an override
Dart rejects the class, and with one the generator rejects `builder` as a
method carrying neither `@provide` nor `@instance`.

```dart
// ❌ module_must_be_abstract
@module()
class AppModule extends Module {
  @provide()
  Api api() => Api();
}

// ✅
@module()
abstract class AppModule extends Module {
  @provide()
  Api api() => Api();
}
```

### `module_method_missing_binding`

Codegen validates every non-abstract method of the class — private and
`static` ones included. Only getters and setters are exempt, since they are not
part of `ClassElement.methods`.

```dart
@module()
abstract class AppModule extends Module {
  // ❌ module_method_missing_binding — no @provide/@instance
  Api api() => Api();

  // ❌ module_method_missing_binding — private methods are validated too
  String _token() => 'secret';

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

On `cherrypick` 4.x, `Scope` fast-paths `if (_observer is SilentCherryPickObserver)`, so a
subclass created via `extends` silently receives **none** of the 14 observer callbacks.

:::note
The fast path does not exist in `cherrypick` 3.x: there a subclass still receives its callbacks,
so this warning does not apply and the rule can be [disabled](#disabling-a-rule).
:::

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
    version: ^4.0.0-dev.0
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
- [Using Annotations](/docs/using-annotations)
- [Documentation Links](/docs/documentation-links)
