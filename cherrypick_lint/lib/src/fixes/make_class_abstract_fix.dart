import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Inserts the `abstract` modifier before a `class` declaration.
class MakeClassAbstractFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;
      if (node.abstractKeyword != null) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Сделать класс abstract',
        priority: 10,
      );
      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(node.classKeyword.offset, 'abstract ');
      });
    });
  }
}
