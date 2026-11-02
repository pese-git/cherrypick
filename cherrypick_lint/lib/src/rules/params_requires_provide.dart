import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags a `@params` method that lacks `@provide` — the generator needs
/// `@provide` to emit a `toProvideWithParams` binding.
class ParamsRequiresProvide extends AnalysisRule {
  static const LintCode code = LintCode(
    'params_requires_provide',
    '@params must be paired with @provide.',
    correctionMessage: 'Add @provide() to this method.',
    severity: DiagnosticSeverity.ERROR,
  );

  ParamsRequiresProvide()
    : super(
        name: 'params_requires_provide',
        description:
            'Pair @params with @provide so the generator emits a '
            'toProvideWithParams binding.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    final annotations = annotationNames(element);
    if (!annotations.contains('params') || annotations.contains('provide')) {
      return;
    }

    rule.reportAtToken(node.name);
  }
}
