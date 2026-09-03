---
title: Linting
description: Catch CherryPick API misuse in the IDE with cherrypick_lint.
---

[`cherrypick_lint`](https://github.com/pese-git/cherrypick/tree/master/cherrypick_lint) is a
[`custom_lint`](https://pub.dev/packages/custom_lint) plugin that catches CherryPick API misuse
right in the IDE — no `build_runner` required. This page shows what each rule catches, with a
bad/good example, and how to install and configure it.

> `cherrypick_generator` already validates annotations, but only when you run codegen.
> `cherrypick_lint` surfaces the same class of mistakes — plus a few runtime traps codegen can't see —
> as you type.

## Install

```yaml
# pubspec.yaml
dev_dependencies:
  custom_lint: ^0.8.1
  cherrypick_lint: ^0.1.0
```

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint
```

Restart your IDE's analysis server (or run `dart run custom_lint`) after adding the plugin.
`dart analyze` never surfaces `custom_lint` diagnostics — use `dart run custom_lint` to see them
from the command line (e.g. in CI).

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

## Disabling a rule

```yaml
# analysis_options.yaml
custom_lint:
  rules:
    - avoid_extends_silent_observer: false
```

## References

- [cherrypick_lint README](https://github.com/pese-git/cherrypick/blob/master/cherrypick_lint/README.md) — full rule table, compatibility, contributing
- [Using Annotations](/using-annotations/)
- [Documentation Links](/documentation-links/)
