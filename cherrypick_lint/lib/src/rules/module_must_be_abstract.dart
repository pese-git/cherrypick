import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../fixes/make_class_abstract_fix.dart';
import '../utils.dart';

/// Flags a `@module` class that isn't declared `abstract`.
///
/// The generator emits a concrete `final class $Foo extends Foo`; if `Foo`
/// isn't abstract, the generated code may fail to compile or misbehave.
class ModuleMustBeAbstract extends DartLintRule {
  const ModuleMustBeAbstract() : super(code: _code);

  static const _code = LintCode(
    name: 'module_must_be_abstract',
    problemMessage: '@module classes must be declared abstract.',
    correctionMessage: 'Add the abstract modifier to this class.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final element = node.declaredFragment?.element;
      if (element == null || !hasAnnotation(element, 'module')) return;
      if (node.abstractKeyword != null) return;

      reporter.atToken(node.name, _code);
    });
  }

  @override
  List<Fix> getFixes() => [MakeClassAbstractFix()];
}
