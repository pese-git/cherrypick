import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags a public method in a `@module` class that has neither `@provide`
/// nor `@instance` — the generator has no binding annotation to work with.
class ModuleMethodMissingBinding extends AnalysisRule {
  static const LintCode code = LintCode(
    'module_method_missing_binding',
    'Public methods in a @module class must be annotated with @provide '
        'or @instance.',
    correctionMessage: 'Add @provide() or @instance() to this method.',
    severity: DiagnosticSeverity.ERROR,
  );

  ModuleMethodMissingBinding()
    : super(
        name: 'module_method_missing_binding',
        description:
            'Annotate every public method of a @module class with @provide or '
            '@instance.',
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
    if (node.isGetter || node.isSetter || node.isOperator) return;
    if (node.name.lexeme.startsWith('_')) return;

    final classNode = node.thisOrAncestorOfType<ClassDeclaration>();
    final classElement = classNode?.declaredFragment?.element;
    if (classElement == null || !hasAnnotation(classElement, 'module')) {
      return;
    }

    final element = node.declaredFragment?.element;
    if (element == null) return;
    final annotations = annotationNames(element);
    if (annotations.contains('provide') || annotations.contains('instance')) {
      return;
    }

    rule.reportAtToken(node.name);
  }
}
