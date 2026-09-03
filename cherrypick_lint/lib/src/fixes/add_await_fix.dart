import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Inserts `await ` before the call expression that triggered the
/// diagnostic. Shared by every await-rule (`avoid_unawaited_*`), since the
/// fix is identical regardless of which one fired.
class AddAwaitFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Add await',
        priority: 10,
      );
      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(node.offset, 'await ');
      });
    });
  }
}
