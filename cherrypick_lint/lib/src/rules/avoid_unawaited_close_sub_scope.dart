import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags `scope.closeSubScope(name)` calls that aren't awaited.
///
/// `closeSubScope` disposes the child scope and its `Disposable`
/// dependencies asynchronously; without `await`, resources may still be
/// alive on the next line.
class AvoidUnawaitedCloseSubScope extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unawaited_close_sub_scope',
    'Missing await on Scope.closeSubScope() — the sub-scope and its '
        'Disposable dependencies may not be disposed yet.',
    correctionMessage:
        'Add await, or wrap the call in unawaited() if this is intentional.',
    severity: DiagnosticSeverity.WARNING,
  );

  AvoidUnawaitedCloseSubScope()
    : super(
        name: 'avoid_unawaited_close_sub_scope',
        description:
            'Await Scope.closeSubScope() so the sub-scope and its Disposable '
            'dependencies are released before execution continues.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'closeSubScope') return;

    if (!isExactlyType(node.target?.staticType, 'Scope', 'cherrypick')) return;

    if (isFutureHandled(node) || isWrappedInUnawaited(node)) return;

    rule.reportAtNode(node);
  }
}
