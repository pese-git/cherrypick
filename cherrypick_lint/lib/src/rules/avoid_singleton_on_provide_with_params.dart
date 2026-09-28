import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags `.singleton()` chained after `.toProvideWithParams(...)` /
/// `.toProvideAsyncWithParams(...)`.
///
/// Per `Binding.singleton()`'s own doc comment, only the very first
/// `resolve<T>(params: ...)` call uses its parameters — every later resolve,
/// regardless of params, returns the same cached instance. That's sometimes
/// exactly what's wanted (a "master singleton"), so unlike
/// `avoid_redundant_singleton_on_instance` this rule offers no quick fix —
/// it's a nudge to double-check intent, not a mistake to auto-correct.
class AvoidSingletonOnProvideWithParams extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_singleton_on_provide_with_params',
    '.singleton() after .toProvideWithParams()/.toProvideAsyncWithParams() '
        'only applies params on the very first resolve — every later resolve '
        'returns the same cached instance regardless of params.',
    correctionMessage:
        'If you want a new instance per params, remove .singleton(). If a '
        'single master instance shared across all params is intended, this '
        'is fine as-is.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidSingletonOnProvideWithParams()
    : super(
        name: 'avoid_singleton_on_provide_with_params',
        description:
            'Double-check .singleton() after a params provider: only the '
            'first resolve sees its params.',
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
    if (target.methodName.name != 'toProvideWithParams' &&
        target.methodName.name != 'toProvideAsyncWithParams') {
      return;
    }
    if (!isCallOn(target, 'Binding', 'cherrypick')) return;

    rule.reportAtNode(node);
  }
}
