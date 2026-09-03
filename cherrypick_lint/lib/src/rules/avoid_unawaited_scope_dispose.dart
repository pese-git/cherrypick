import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../fixes/add_await_fix.dart';
import '../utils.dart';

const _scopeChecker = TypeChecker.fromName('Scope', packageName: 'cherrypick');

/// Flags `scope.dispose()` calls that aren't awaited, when the receiver's
/// static type is exactly [Scope]. User-defined synchronous `Disposable`
/// implementations return `void` and are intentionally not covered.
class AvoidUnawaitedScopeDispose extends DartLintRule {
  const AvoidUnawaitedScopeDispose() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_unawaited_scope_dispose',
    problemMessage: 'Missing await on Scope.dispose().',
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
      if (node.methodName.name != 'dispose') return;

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
