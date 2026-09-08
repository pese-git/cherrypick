import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags `.singleton()` chained directly after `.toInstance(...)` /
/// `.toInstanceAsync(...)`.
///
/// Per `Binding.singleton()`'s own doc comment, the call is a no-op there:
/// the value passed to `toInstance` is already a single, constant instance
/// returned on every resolve. `.singleton()` only does something meaningful
/// after a provider (`toProvide`, `toProvideAsync`, ...).
class AvoidRedundantSingletonOnInstance extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_redundant_singleton_on_instance',
    '.singleton() has no effect after .toInstance()/.toInstanceAsync() '
        '— the bound value is already a single, constant instance.',
    correctionMessage: 'Remove the redundant .singleton() call.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidRedundantSingletonOnInstance()
    : super(
        name: 'avoid_redundant_singleton_on_instance',
        description:
            'Drop .singleton() after .toInstance(), where it does nothing.',
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
    if (node.methodName.name != 'singleton') return;
    if (!isCallOn(node, 'Binding', 'cherrypick')) return;

    final target = node.target;
    if (target is! MethodInvocation) return;
    if (target.methodName.name != 'toInstance' &&
        target.methodName.name != 'toInstanceAsync') {
      return;
    }
    if (!isCallOn(target, 'Binding', 'cherrypick')) return;

    rule.reportAtNode(node);
  }
}
