## 1.1.0

Two new rules for the `@module` requirements that codegen actually enforces,
and a correction to two existing ones. Verified by running
`cherrypick_generator`'s `moduleBuilder` through `build_test` on each case.

- **New** `module_requires_part_directive` (`error`, quick fix "Add the
  generated part directive"): a `@module` library must declare
  `part '<file>.module.cherrypick.g.dart';`. `moduleBuilder` is a
  `PartBuilder`, so without it the build succeeds having written nothing and
  warns only in the `build_runner` log.
- **New** `module_must_extend_module` (`error`, no quick fix): a `@module`
  class must have `Module` in its supertype chain. The generated part is
  `final class $Foo extends Foo` whose `builder()` body calls `bind<T>()` —
  both come from `Module` — so codegen emits a part that cannot compile, and
  reports nothing itself.
- `module_method_missing_binding` no longer skips private methods, and now
  covers `static` methods and operators. `GeneratedClass` collects
  `ClassElement.methods` filtered only by `!isAbstract`, without a visibility
  check, so `String _helper() => 'x';` inside a `@module` class fails the build
  exactly like a public method would. Getters and setters stay exempt: they are
  not part of `ClassElement.methods`. This means the rule reports on code it
  previously accepted.
- `module_must_be_abstract` keeps its `error` severity, but its message and
  documentation no longer claim the generator requires the modifier — it
  doesn't. The reason a concrete `@module` class still cannot work is that
  `Module.builder` is abstract: without an override Dart rejects the class,
  and with one the generator's validator rejects `builder` as a method carrying
  neither `@provide` nor `@instance`.

## 1.0.0

**BREAKING**: the plugin now runs on the official
[`analysis_server_plugin`](https://pub.dev/packages/analysis_server_plugin)
framework instead of `custom_lint`, which changes how it is installed. What
each rule flags, with which severity and which quick fix, is unchanged.

- Install by naming the plugin in the top-level `plugins:` section of
  `analysis_options.yaml`; it is no longer a `dev_dependency`, and
  `custom_lint` is not needed at all.
- Diagnostics now appear in `dart analyze` / `flutter analyze` as well as in
  the IDE. The separate `dart run custom_lint` step is gone.
- Rules are disabled under `plugins: cherrypick_lint: diagnostics:` instead of
  `custom_lint: rules:`.
- Ignore comments take the plugin prefix: `// ignore: cherrypick_lint/<rule>`.
- Requires Dart >=3.10.0 (Flutter >=3.38), up from >=3.9.0 — that is the
  release which introduced analyzer plugins.
- Tests moved to `analyzer_testing` unit tests; the `// expect_lint` fixture
  package became a plain installation example.

See the "Migration from 0.x" section of the README for the before/after table.

Why: `custom_lint`'s repository is archived and its author no longer has
publishing rights, recommending `analysis_server_plugin` instead.

Verified from the same sources on both supported SDKs: `analysis_server_plugin`
0.3.14 / `analyzer` 12.1.0 on Dart 3.10.4 (Flutter 3.38.5), and 0.3.22 /
`analyzer` 14.3.0 on Dart 3.11.5 (Flutter 3.41.7).

## 0.1.0

- Initial release.
- await-rules: `avoid_unawaited_close_sub_scope`, `avoid_unawaited_close_scope`,
  `avoid_unawaited_scope_dispose`, each with an "Add await" quick fix.
- annotation-rules: `module_must_be_abstract` (+ quick fix), `module_method_missing_binding`,
  `inject_field_must_be_late_final` (+ quick fix), `named_value_must_not_be_empty`,
  `params_requires_provide`.
- runtime-trap-rules: `avoid_extends_silent_observer` (+ quick fix),
  `avoid_redundant_singleton_on_instance` (+ quick fix),
  `avoid_singleton_on_provide_with_params` (no quick fix — the pattern can be
  intentional), `avoid_resolve_in_to_instance` (no quick fix — flags
  `scope.resolve()`/`resolveAsync()`/`tryResolve()`/`tryResolveAsync()` inside
  `.toInstance(...)`/`.toInstanceAsync(...)`, a documented runtime crash risk),
  `avoid_precomputed_value_in_provide` (no quick fix — flags a provider
  closure that just returns a value built outside it instead of constructing
  one, an unintended pseudo-singleton).
- Fix: `avoid_extends_silent_observer` and the three await-rules never set
  `errorSeverity` explicitly, so they silently reported as `info` instead of
  the documented `warning`. All four now set `errorSeverity:
  ErrorSeverity.WARNING`.
