import 'package:analyzer/dart/ast/ast.dart';
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
      // Match the exact flagged node — not merely any invocation whose
      // range contains it (e.g. an outer `Future.wait(...)` call around
      // the flagged argument), which used to cause the fix to also insert
      // `await` around the outer call.
      if (node.sourceRange != analysisError.sourceRange) return;

      // `await` is only valid inside an async function/method/closure body.
      // Without this guard the fix would offer to insert `await` into sync
      // code, turning it into a compile error.
      final body = node.thisOrAncestorOfType<FunctionBody>();
      if (body == null || !body.isAsynchronous) return;

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
