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
- Requires Dart >=3.11.0 (Flutter >=3.41), up from >=3.9.0.
- Tests moved to `analyzer_testing` unit tests; the `// expect_lint` fixture
  package became a plain installation example.

See the "Migration from 0.x" section of the README for the before/after table.

Why: `custom_lint`'s repository is archived and its author no longer has
publishing rights, recommending `analysis_server_plugin` instead. Verified
against `analysis_server_plugin` 0.3.22, `analyzer` 14.3.0 and
`analyzer_plugin` 0.14.16 on Dart 3.11.5 (Flutter 3.41.7).

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
