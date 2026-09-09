/// The rules and quick fixes that make up `cherrypick_lint`.
///
/// This library is **not** the plugin entrypoint — the Dart Analysis Server
/// loads `lib/main.dart` and its top-level `plugin` variable. This one exists
/// so the rules can be imported directly, e.g. from tests or from another
/// plugin that wants to reuse them.
library;

export 'src/fixes/add_await_fix.dart';
export 'src/fixes/add_late_final_fix.dart';
export 'src/fixes/add_module_part_directive_fix.dart';
export 'src/fixes/make_class_abstract_fix.dart';
export 'src/fixes/remove_redundant_singleton_fix.dart';
export 'src/fixes/replace_extends_with_implements_fix.dart';
export 'src/rules/avoid_extends_silent_observer.dart';
export 'src/rules/avoid_precomputed_value_in_provide.dart';
export 'src/rules/avoid_redundant_singleton_on_instance.dart';
export 'src/rules/avoid_resolve_in_to_instance.dart';
export 'src/rules/avoid_singleton_on_provide_with_params.dart';
export 'src/rules/avoid_unawaited_close_scope.dart';
export 'src/rules/avoid_unawaited_close_sub_scope.dart';
export 'src/rules/avoid_unawaited_scope_dispose.dart';
export 'src/rules/inject_field_must_be_late_final.dart';
export 'src/rules/module_method_missing_binding.dart';
export 'src/rules/module_must_be_abstract.dart';
export 'src/rules/module_must_extend_module.dart';
export 'src/rules/module_requires_part_directive.dart';
export 'src/rules/named_value_must_not_be_empty.dart';
export 'src/rules/params_requires_provide.dart';
