import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Replaces `extends SilentCherryPickObserver` with
/// `implements CherryPickObserver`, merging into an existing `implements`
/// clause if the class already has one.
class ReplaceExtendsWithImplementsFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addClassDeclaration((node) {
      final extendsClause = node.extendsClause;
      if (extendsClause == null) return;
      if (!analysisError.sourceRange.intersects(extendsClause.sourceRange)) {
        return;
      }

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Заменить на implements CherryPickObserver',
        priority: 10,
      );
      changeBuilder.addDartFileEdit((builder) {
        final implementsClause = node.implementsClause;
        if (implementsClause == null) {
          builder.addSimpleReplacement(
            extendsClause.sourceRange,
            'implements CherryPickObserver',
          );
        } else {
          builder.addSimpleReplacement(extendsClause.sourceRange, '');
          builder.addSimpleInsertion(
            implementsClause.interfaces.first.offset,
            'CherryPickObserver, ',
          );
        }
      });
    });
  }
}
