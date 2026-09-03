import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/avoid_experimental_scope_api.dart';
import 'src/rules/avoid_extends_silent_observer.dart';
import 'src/rules/avoid_unawaited_close_scope.dart';
import 'src/rules/avoid_unawaited_close_sub_scope.dart';
import 'src/rules/avoid_unawaited_scope_dispose.dart';
import 'src/rules/inject_field_must_be_late_final.dart';
import 'src/rules/module_method_missing_binding.dart';
import 'src/rules/module_must_be_abstract.dart';
import 'src/rules/named_value_must_not_be_empty.dart';
import 'src/rules/params_requires_provide.dart';

/// Entrypoint used by `custom_lint` to discover this plugin.
PluginBase createPlugin() => _CherryPickLint();

class _CherryPickLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
    // await-rules
    AvoidUnawaitedCloseSubScope(),
    AvoidUnawaitedCloseScope(),
    AvoidUnawaitedScopeDispose(),
    // annotation-rules
    ModuleMustBeAbstract(),
    ModuleMethodMissingBinding(),
    InjectFieldMustBeLateFinal(),
    NamedValueMustNotBeEmpty(),
    ParamsRequiresProvide(),
    // runtime-trap-rules
    AvoidExtendsSilentObserver(),
    AvoidExperimentalScopeApi(),
  ];
}
