import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/fixes/add_await_fix.dart';
import 'src/rules/avoid_unawaited_close_scope.dart';
import 'src/rules/avoid_unawaited_close_sub_scope.dart';
import 'src/rules/avoid_unawaited_scope_dispose.dart';

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
  }
}
