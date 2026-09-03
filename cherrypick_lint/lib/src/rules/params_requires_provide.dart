import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../utils.dart';

/// Flags a `@params` method that lacks `@provide` — the generator needs
/// `@provide` to emit a `toProvideWithParams` binding.
class ParamsRequiresProvide extends DartLintRule {
  const ParamsRequiresProvide() : super(code: _code);

  static const _code = LintCode(
    name: 'params_requires_provide',
    problemMessage: '@params must be paired with @provide.',
    correctionMessage: 'Add @provide() to this method.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      final element = node.declaredFragment?.element;
      if (element == null) return;

      final annotations = annotationNames(element);
      if (!annotations.contains('params') || annotations.contains('provide')) {
        return;
      }

      reporter.atToken(node.name, _code);
    });
  }
}
