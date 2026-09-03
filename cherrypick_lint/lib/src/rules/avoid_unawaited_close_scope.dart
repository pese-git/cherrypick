import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../fixes/add_await_fix.dart';
import '../utils.dart';

/// Flags `CherryPick.closeScope(...)` calls that aren't awaited.
class AvoidUnawaitedCloseScope extends DartLintRule {
  const AvoidUnawaitedCloseScope() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_unawaited_close_scope',
    problemMessage: 'Missing await on CherryPick.closeScope().',
    correctionMessage:
        'Add await, or wrap the call in unawaited() if this is intentional.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'closeScope') return;
      if (!isStaticCallOn(node, 'CherryPick', 'cherrypick')) return;

      if (isAwaited(node) || isWrappedInUnawaited(node)) return;

      reporter.atNode(node, _code);
    });
  }

  @override
  List<Fix> getFixes() => [AddAwaitFix()];
}
