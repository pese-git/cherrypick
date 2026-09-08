import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../utils.dart';

/// Flags `@named('')` — an empty name is indistinguishable from no name and
/// leads to unpredictable resolution.
class NamedValueMustNotBeEmpty extends DartLintRule {
  const NamedValueMustNotBeEmpty() : super(code: _code);

  static const _code = LintCode(
    name: 'named_value_must_not_be_empty',
    problemMessage: '@named must not be given an empty string.',
    correctionMessage: 'Provide a non-empty name, or remove the annotation.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addAnnotation((node) {
      final owner = enclosingElementOf(node.element);
      if (owner?.name != 'named' ||
          !isDeclaredInPackage(owner, 'cherrypick_annotations')) {
        return;
      }

      final arguments = node.arguments?.arguments;
      if (arguments == null || arguments.isEmpty) return;

      final valueArg = arguments.first;
      if (valueArg is! StringLiteral) return;
      if (valueArg.stringValue != '') return;

      reporter.atNode(node, _code);
    });
  }
}
