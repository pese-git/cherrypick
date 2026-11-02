import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags a method in a `@module` class that has neither `@provide` nor
/// `@instance` — the generator has no binding annotation to work with.
///
/// Visibility and `static` make no difference: `GeneratedClass` collects
/// `ClassElement.methods` filtered only by `!isAbstract`, and every one of
/// them goes through `AnnotationValidator.validateMethodAnnotations`, which
/// throws on a method that carries neither annotation. So a private helper or
/// a static utility inside a `@module` class fails the build exactly like a
/// public one. Getters and setters are not in `ClassElement.methods` and are
/// therefore never validated.
class ModuleMethodMissingBinding extends AnalysisRule {
  static const LintCode code = LintCode(
    'module_method_missing_binding',
    'Methods in a @module class must be annotated with @provide or '
        '@instance — codegen validates every non-abstract method, private '
        'and static ones included.',
    correctionMessage:
        'Add @provide() or @instance() to this method, or move it out of the '
        '@module class.',
    severity: DiagnosticSeverity.ERROR,
  );

  ModuleMethodMissingBinding()
    : super(
        name: 'module_method_missing_binding',
        description:
            'Annotate every method of a @module class with @provide or '
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
    // Only accessors are exempt: they live in `ClassElement.getters`/
    // `.setters`, which codegen never looks at. Operators, private and
    // static methods all reach the validator.
    if (node.isGetter || node.isSetter) return;

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
