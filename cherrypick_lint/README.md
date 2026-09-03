# cherrypick_lint

A [`custom_lint`](https://pub.dev/packages/custom_lint) plugin that catches
[CherryPick](https://pub.dev/packages/cherrypick) DI API misuse right in the
IDE — no `build_runner` required.

`cherrypick_generator` already validates annotations, but only when you run
codegen. `cherrypick_lint` surfaces the same class of mistakes (plus a few
runtime traps `codegen` can't see) as you type.

## Install

```yaml
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

Restart your IDE's analysis server (or run `dart run custom_lint`) after adding
the plugin.

## Rules

### await-rules — missing `await` on scope disposal (`warning`)

| Rule | Triggers on | Quick fix |
|---|---|---|
| `avoid_unawaited_close_sub_scope` | `scope.closeSubScope(name)` without `await` | Add await |
| `avoid_unawaited_close_scope` | `CherryPick.closeScope(...)` without `await` | Add await |
| `avoid_unawaited_scope_dispose` | `scope.dispose()` without `await`, where `scope` is a `Scope` | Add await |

Wrapping the call in `unawaited(...)` is treated as an explicit, intentional
fire-and-forget and doesn't trigger these rules.

### annotation-rules — invalid annotation usage (`error`)

| Rule | Triggers on | Quick fix |
|---|---|---|
| `module_must_be_abstract` | `@module` on a non-`abstract` class | Make class abstract |
| `module_method_missing_binding` | public method in a `@module` class without `@provide`/`@instance` | — |
| `inject_field_must_be_late_final` | `@inject` field not declared `late final` | Add late final |
| `named_value_must_not_be_empty` | `@named('')` | — |
| `params_requires_provide` | `@params` without `@provide` | — |

### runtime-trap-rules — footguns `codegen` can't see

| Rule | Severity | Triggers on | Quick fix |
|---|---|---|---|
| `avoid_extends_silent_observer` | `warning` | `class Foo extends SilentCherryPickObserver` | Replace with `implements CherryPickObserver` |
| `avoid_experimental_scope_api` | `info` | `CherryPick.openScope`/`closeScope` | — (suggests `openSubScope`/`closeSubScope`) |

`SilentCherryPickObserver` is deliberately skipped by `Scope`'s fast path
(`if (_observer is SilentCherryPickObserver)`), so an `extends` subclass
silently receives none of the 14 observer callbacks — `implements
CherryPickObserver` is always what you want instead.

## Disabling a rule

```yaml
# analysis_options.yaml
custom_lint:
  rules:
    - avoid_experimental_scope_api: false
```

## Compatibility

Requires Dart >=3.9.0, `custom_lint` / `custom_lint_builder` ^0.8.1 (analyzer
^8.0.0).

## Development

Fixture files exercising every rule live in [`example/lib`](example/lib), each
using `// expect_lint: <code>` to assert the exact violations expected:

```bash
cd example
dart pub get
dart run custom_lint          # verify every expect_lint is fulfilled
dart run custom_lint --fix    # try quick fixes against real violations
```
