import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../fixes/add_late_final_fix.dart';
import '../utils.dart';

/// Flags an `@inject` field that isn't declared `late final`.
///
/// Without `late`, the field can't be initialized after the constructor
/// runs; without `final`, it can be silently overwritten after injection.
class InjectFieldMustBeLateFinal extends DartLintRule {
  const InjectFieldMustBeLateFinal() : super(code: _code);

  static const _code = LintCode(
    name: 'inject_field_must_be_late_final',
    problemMessage: '@inject fields must be declared late final.',
    correctionMessage: 'Add the late final modifiers to this field.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFieldDeclaration((node) {
      for (final variable in node.fields.variables) {
        final element = variable.declaredFragment?.element;
        if (element == null || !hasAnnotation(element, 'inject')) continue;
        if (variable.isLate && variable.isFinal) continue;

        reporter.atToken(variable.name, _code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [AddLateFinalFix()];
}
