import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags `CherryPick.closeScope(...)` calls that aren't awaited.
class AvoidUnawaitedCloseScope extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unawaited_close_scope',
    'Missing await on CherryPick.closeScope().',
    correctionMessage:
        'Add await, or wrap the call in unawaited() if this is intentional.',
    severity: DiagnosticSeverity.WARNING,
  );

  AvoidUnawaitedCloseScope()
    : super(
        name: 'avoid_unawaited_close_scope',
        description:
            'Await CherryPick.closeScope() so the scope and its '
            'Disposable dependencies are released before execution continues.',
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
    if (node.methodName.name != 'closeScope') return;
    if (!isCallOn(node, 'CherryPick', 'cherrypick')) return;

    if (isFutureHandled(node) || isWrappedInUnawaited(node)) return;

    rule.reportAtNode(node);
  }
}
