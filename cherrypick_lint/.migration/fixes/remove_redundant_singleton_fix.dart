import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Deletes a redundant `.singleton()` call chained after `.toInstance(...)`.
class RemoveRedundantSingletonFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.sourceRange != analysisError.sourceRange) return;

      final target = node.target;
      if (target == null) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Remove redundant .singleton()',
        priority: 10,
      );
      changeBuilder.addDartFileEdit((builder) {
        builder.addDeletion(SourceRange(target.end, node.end - target.end));
      });
    });
  }
}
