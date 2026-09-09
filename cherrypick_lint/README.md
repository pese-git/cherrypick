# cherrypick_lint

An [analyzer plugin](https://pub.dev/packages/analysis_server_plugin) that
catches [CherryPick](https://pub.dev/packages/cherrypick) DI API misuse in the
IDE and in `dart analyze` — no `build_runner` required.

`cherrypick_generator` already validates annotations, but only when you run
codegen. `cherrypick_lint` surfaces the same class of mistakes (plus a few
runtime traps `codegen` can't see) as you type.

## Install

The plugin is **not** a dependency of your project — the analysis server
resolves it itself. Name it in the top-level `plugins` section of your
`analysis_options.yaml`:

```yaml
# analysis_options.yaml
plugins:
  cherrypick_lint: ^1.1.0
```

Then restart the Dart Analysis Server (in VS Code: *Dart: Restart Analysis
Server*); analyzer plugins are only picked up on start-up. The rules then show
up both in the IDE and in `dart analyze` / `flutter analyze` — there is no
separate command to run.

Requires Dart >=3.10 (Flutter >=3.38) — the release that introduced analyzer
plugins.

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
| `module_requires_part_directive` | a `@module` library without `part '<file>.module.cherrypick.g.dart';` | Add the generated part directive |
| `module_must_extend_module` | `@module` class without `Module` in its supertype chain | — |
| `module_must_be_abstract` | `@module` on a non-`abstract` class | Make class abstract |
| `module_method_missing_binding` | a method in a `@module` class without `@provide`/`@instance` — private and `static` included | — |
| `inject_field_must_be_late_final` | `@inject` field not declared `late final` | Add late final |
| `named_value_must_not_be_empty` | `@named('')` | — |
| `params_requires_provide` | `@params` without `@provide` | — |

`module_requires_part_directive` covers the one requirement whose failure is
silent: `moduleBuilder` is a `PartBuilder`, so without the part directive
`build_runner` finishes successfully having written nothing, saying so only
through a log warning.

`module_must_extend_module` covers the other hard requirement. The generated
part is `final class $Foo extends Foo`, whose `builder()` body is a list of
`bind<T>()` calls; both members come from `Module`, so a `@module` class that
doesn't extend it gets a part that can't compile — and the generator itself
reports nothing, since it writes the file happily.

`abstract`, by contrast, is not something the generator checks: it collects the
non-abstract methods and emits `final class $Foo extends Foo` either way. A
concrete `@module` class is still a dead end, which is why the rule stays an
`error` — `Module.builder` is abstract, so without an override Dart rejects the
class (`non_abstract_class_inherits_abstract_member`), and with one the
generator's validator rejects `builder` itself as a method carrying neither
`@provide` nor `@instance`.

That same validator is why `module_method_missing_binding` ignores neither
private nor `static` methods: `GeneratedClass` collects `ClassElement.methods`
filtered only by `!isAbstract`, and every one of them must carry `@provide` or
`@instance` or the build fails. Getters and setters are the only exemption —
they live in `ClassElement.getters`/`.setters`, which codegen never reads.

An abstract method inside a `@module` class is a different problem the rule
does not yet describe well: codegen skips it, but the generated
`final class $Foo extends Foo` then leaves it unimplemented, so the part
doesn't compile — and annotating it doesn't help (with `@provide` the binding
is silently dropped and `builder()` comes out empty). The rule still reports
such a method; the fix is to give it a body or move it out of the module
class, not to add an annotation.

### runtime-trap-rules — footguns `codegen` can't see

| Rule | Severity | Triggers on | Quick fix |
|---|---|---|---|
| `avoid_extends_silent_observer` | `warning` | `class Foo extends SilentCherryPickObserver` | Replace with `implements CherryPickObserver` |
| `avoid_redundant_singleton_on_instance` | `info` | `.singleton()` chained after `.toInstance(...)`/`.toInstanceAsync(...)` | Remove redundant `.singleton()` |
| `avoid_singleton_on_provide_with_params` | `info` | `.singleton()` chained after `.toProvideWithParams(...)`/`.toProvideAsyncWithParams(...)` | — |
| `avoid_resolve_in_to_instance` | `warning` | `scope.resolve()`/`resolveAsync()`/`tryResolve()`/`tryResolveAsync()` inside `.toInstance(...)`/`.toInstanceAsync(...)` | — |
| `avoid_precomputed_value_in_provide` | `warning` | `.toProvide(...)`/`.toProvideAsync(...)`/`.toProvideWithParams(...)`/`.toProvideAsyncWithParams(...)` closure that just returns a variable built outside it | — |

`SilentCherryPickObserver` is deliberately skipped by `Scope`'s fast path
(`if (_observer is SilentCherryPickObserver)`), so an `extends` subclass
silently receives none of the 14 observer callbacks — `implements
CherryPickObserver` is always what you want instead.

`.singleton()` after `.toInstance(...)` is a documented no-op (see
`Binding.singleton()`'s doc comment): the bound value is already a single,
constant instance, so the call does nothing but read as if it did.

`.singleton()` after `.toProvideWithParams(...)` turns the binding into a
"master singleton" that only honors params on the very first resolve — every
later resolve returns the same cached instance regardless of params. That's
sometimes intentional, so this rule has no quick fix; it's a nudge to
double-check, not an auto-correctable mistake.

`.toInstance(...)` bindings inside a `Module.builder` are applied
sequentially, so calling `scope.resolve<T>()` (or `resolveAsync`/`tryResolve`/
`tryResolveAsync`) to build the value can throw `Can't resolve dependency ...`
if `T` is registered later in the same builder (see `Binding.toInstance()`'s
doc comment for the full example). Deferring the resolve with
`.toProvide(() => ...)` runs it lazily, once every sibling binding is already
registered — this rule has no quick fix since the fix depends on how the
dependency chain should actually be built.

A provider closure exists to be re-invoked on every `resolve<T>()` — the
value should be built there. `bind<T>().toProvide(() => variable)`, where
`variable` was already constructed earlier in the same method, actually
builds the value once, at `Module.builder()` time; every `resolve<T>()` then
silently returns that same instance, an unintended pseudo-singleton that
bypasses `.singleton()`'s explicit opt-in. `.toInstance(...)` isn't affected
by this — it always constructs eagerly regardless of where the value comes
from, so precomputing a value for it is fine.

## Disabling a rule

Every rule is enabled by default. Switch one off under the plugin's
`diagnostics` key:

```yaml
# analysis_options.yaml
plugins:
  cherrypick_lint:
    version: ^1.1.0
    diagnostics:
      avoid_extends_silent_observer: false
```

A single line or file can be exempted with an ignore comment, using the
`<plugin>/<rule>` form:

```dart
// ignore: cherrypick_lint/avoid_unawaited_scope_dispose
scope.dispose();
```

## Compatibility

Requires Dart >=3.10.0 (Flutter >=3.38).

Every published `analysis_server_plugin` release pins one exact `analyzer`
version, and `analyzer` >=13.1.0 requires Dart >=3.11 — so which versions you
actually get follows from your SDK. Both resolutions are tested from the same
sources:

| | Dart 3.10 (Flutter 3.38) | Dart 3.11+ (Flutter 3.41+) |
|---|---|---|
| `analysis_server_plugin` | 0.3.14 | 0.3.22 |
| `analyzer` | 12.1.0 | 14.3.0 |
| `analyzer_plugin` | 0.14.8 | 0.14.16 |

The rules and fixes compile against both `analyzer` majors unchanged.

Versions 0.1.x were built on [`custom_lint`](https://pub.dev/packages/custom_lint),
whose repository is archived and which its author no longer publishes; see
[Migration from 0.x](#migration-from-0x) below.

## Migration from 0.x

The rules, their messages, severities and quick fixes are unchanged. Only
installation changes:

| 0.1.x (`custom_lint`) | 1.0.0 (analyzer plugin) |
|---|---|
| `dev_dependencies: custom_lint`, `cherrypick_lint` | no dependency at all |
| `analyzer: plugins: [custom_lint]` | top-level `plugins: cherrypick_lint: ^1.0.0` |
| `custom_lint: rules: - <rule>: false` | `plugins: cherrypick_lint: diagnostics: <rule>: false` |
| `dart run custom_lint` in CI | plain `dart analyze` |
| `// ignore: <rule>` | `// ignore: cherrypick_lint/<rule>` |

So: drop both `dev_dependencies`, replace the `analyzer: plugins:` block with
the top-level `plugins:` block above, delete any `dart run custom_lint` step
from CI, and restart the analysis server.

## Development

Every rule is covered by unit tests built on
[`analyzer_testing`](https://pub.dev/packages/analyzer_testing) — inline
sources plus `assertDiagnostics`/`assertNoDiagnostics`, no fixture files and
no subprocess:

```bash
dart test
```

[`example/`](example) is a rule-clean CherryPick setup that doubles as an
installation demo: its `analysis_options.yaml` enables this plugin by path,
and `dart analyze` there is expected to stay quiet.

Quick fixes have no automated coverage: `analyzer_testing` has no API for
testing fixes, and `dart fix` does not apply plugin fixes. Check them by hand
in the IDE.

> **Note:** after changing this package's dependencies (or the Dart SDK),
> `dart analyze` in a package that enables the plugin can start failing with
> `Bad state: The analysis server crashed unexpectedly`. The analysis server
> caches a synthetic wrapper package per plugin configuration under
> `~/.dartServer/.plugin_manager/<hash>/` and reuses it after the plugin's
> dependencies have moved on. Delete the stale directories and the crash goes
> away:
>
> ```bash
> rm -rf ~/.dartServer/.plugin_manager
> ```
