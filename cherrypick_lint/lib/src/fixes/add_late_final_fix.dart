import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Adds the missing `late` and/or `final` modifiers to a field declaration.
class AddLateFinalFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addFieldDeclaration((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      final fields = node.fields;
      if (fields.isLate && fields.isFinal) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Добавить late final',
        priority: 10,
      );
      changeBuilder.addDartFileEdit((builder) {
        if (!fields.isLate && !fields.isFinal) {
          builder.addSimpleInsertion(fields.offset, 'late final ');
        } else if (!fields.isLate) {
          builder.addSimpleInsertion(fields.offset, 'late ');
        } else {
          final keyword = fields.keyword;
          if (keyword != null) {
            builder.addSimpleReplacement(
              SourceRange(keyword.offset, keyword.length),
              'final',
            );
          } else {
            final insertionOffset =
                fields.type?.offset ?? fields.variables.first.offset;
            builder.addSimpleInsertion(insertionOffset, 'final ');
          }
        }
      });
    });
  }
}
