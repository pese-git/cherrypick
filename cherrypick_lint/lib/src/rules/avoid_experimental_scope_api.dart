import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../utils.dart';

const _alternatives = {
  'openScope': 'openSubScope',
  'closeScope': 'closeSubScope',
};

/// Flags calls to the `@experimental` `CherryPick.openScope`/`closeScope`
/// helpers, suggesting the direct `Scope.openSubScope`/`closeSubScope` API.
class AvoidExperimentalScopeApi extends DartLintRule {
  const AvoidExperimentalScopeApi() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_experimental_scope_api',
    problemMessage:
        'CherryPick.{0} is experimental; prefer {1} on a Scope reference.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      final alternative = _alternatives[node.methodName.name];
      if (alternative == null) return;
      if (!isStaticCallOn(node, 'CherryPick', 'cherrypick')) return;

      reporter.atNode(
        node,
        _code,
        arguments: [node.methodName.name, alternative],
      );
    });
  }
}
