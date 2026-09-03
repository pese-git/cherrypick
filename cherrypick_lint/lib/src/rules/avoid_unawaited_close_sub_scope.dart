import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../fixes/add_await_fix.dart';
import '../utils.dart';

const _scopeChecker = TypeChecker.fromName('Scope', packageName: 'cherrypick');

/// Flags `scope.closeSubScope(name)` calls that aren't awaited.
///
/// `closeSubScope` disposes the child scope and its `Disposable`
/// dependencies asynchronously; without `await`, resources may still be
/// alive on the next line.
class AvoidUnawaitedCloseSubScope extends DartLintRule {
  const AvoidUnawaitedCloseSubScope() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_unawaited_close_sub_scope',
    problemMessage:
        'Missing await on Scope.closeSubScope() — the sub-scope and its '
        'Disposable dependencies may not be disposed yet.',
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
      if (node.methodName.name != 'closeSubScope') return;

      final targetType = node.target?.staticType;
      if (targetType == null || !_scopeChecker.isExactlyType(targetType)) {
        return;
      }

      if (isAwaited(node) || isWrappedInUnawaited(node)) return;

      reporter.atNode(node, _code);
    });
  }

  @override
  List<Fix> getFixes() => [AddAwaitFix()];
}
