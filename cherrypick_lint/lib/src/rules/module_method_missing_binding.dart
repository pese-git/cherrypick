import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../utils.dart';

/// Flags a public method in a `@module` class that has neither `@provide`
/// nor `@instance` — the generator has no binding annotation to work with.
class ModuleMethodMissingBinding extends DartLintRule {
  const ModuleMethodMissingBinding() : super(code: _code);

  static const _code = LintCode(
    name: 'module_method_missing_binding',
    problemMessage:
        'Public methods in a @module class must be annotated with @provide '
        'or @instance.',
    correctionMessage: 'Add @provide() or @instance() to this method.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
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

      reporter.atToken(node.name, _code);
    });
  }
}
