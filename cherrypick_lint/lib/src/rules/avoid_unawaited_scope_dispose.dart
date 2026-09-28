import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags `scope.dispose()` calls that aren't awaited, when the receiver's
/// static type is exactly `Scope`. User-defined synchronous `Disposable`
/// implementations return `void` and are intentionally not covered.
class AvoidUnawaitedScopeDispose extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unawaited_scope_dispose',
    'Missing await on Scope.dispose().',
    correctionMessage:
        'Add await, or wrap the call in unawaited() if this is intentional.',
    severity: DiagnosticSeverity.WARNING,
  );

  AvoidUnawaitedScopeDispose()
    : super(
        name: 'avoid_unawaited_scope_dispose',
        description:
            'Await Scope.dispose() so resources are released before '
            'execution continues.',
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
    if (node.methodName.name != 'dispose') return;

    if (!isExactlyType(node.target?.staticType, 'Scope', 'cherrypick')) return;

    if (isFutureHandled(node) || isWrappedInUnawaited(node)) return;

    rule.reportAtNode(node);
  }
}
