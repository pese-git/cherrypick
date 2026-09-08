import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/fixes/add_await_fix.dart';
import 'src/fixes/add_late_final_fix.dart';
import 'src/fixes/make_class_abstract_fix.dart';
import 'src/rules/avoid_unawaited_close_scope.dart';
import 'src/rules/avoid_unawaited_close_sub_scope.dart';
import 'src/rules/avoid_unawaited_scope_dispose.dart';
import 'src/rules/inject_field_must_be_late_final.dart';
import 'src/rules/module_method_missing_binding.dart';
import 'src/rules/module_must_be_abstract.dart';
import 'src/rules/named_value_must_not_be_empty.dart';
import 'src/rules/params_requires_provide.dart';

/// Entrypoint used by the Dart Analysis Server to load this plugin.
///
/// The server generates code that imports this library and reads this
/// top-level `plugin` variable, so neither its name nor its location
/// (`lib/main.dart`) is negotiable.
final plugin = CherryPickLintPlugin();

class CherryPickLintPlugin extends Plugin {
  @override
  String get name => 'cherrypick_lint';

  @override
  void register(PluginRegistry registry) {
    // Every rule is registered as a warning rule, i.e. enabled by default.
    // `registerLintRule` would make a rule opt-in, silently switching it off
    // for existing users. Severity lives in each rule's `LintCode` and is
    // independent of how the rule is registered.
    // await-rules
    registry.registerWarningRule(AvoidUnawaitedCloseSubScope());
    registry.registerFixForRule(
      AvoidUnawaitedCloseSubScope.code,
      AddAwaitFix.new,
    );
    registry.registerWarningRule(AvoidUnawaitedCloseScope());
    registry.registerFixForRule(AvoidUnawaitedCloseScope.code, AddAwaitFix.new);
    registry.registerWarningRule(AvoidUnawaitedScopeDispose());
    registry.registerFixForRule(
      AvoidUnawaitedScopeDispose.code,
      AddAwaitFix.new,
    );

    // annotation-rules
    registry.registerWarningRule(ModuleMustBeAbstract());
    registry.registerFixForRule(
      ModuleMustBeAbstract.code,
      MakeClassAbstractFix.new,
    );
    registry.registerWarningRule(ModuleMethodMissingBinding());
    registry.registerWarningRule(InjectFieldMustBeLateFinal());
    registry.registerFixForRule(
      InjectFieldMustBeLateFinal.code,
      AddLateFinalFix.new,
    );
    registry.registerWarningRule(NamedValueMustNotBeEmpty());
    registry.registerWarningRule(ParamsRequiresProvide());
  }
}
