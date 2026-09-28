import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Inserts `await ` before the call expression that triggered the
/// diagnostic. Shared by every await-rule (`avoid_unawaited_*`), since the
/// fix is identical regardless of which one fired.
class AddAwaitFix extends CorrectionProducerWithDiagnostic {
  static const _addAwaitKind = FixKind(
    'cherrypick_lint.fix.addAwait',
    DartFixKindPriority.standard,
    'Add await',
  );

  AddAwaitFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _addAwaitKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // `node` is the node covering the reported range; only act when that is
    // exactly the flagged invocation, so an enclosing call (e.g. a
    // `Future.wait(...)` around the flagged argument) never gets the await.
    final invocation = node;
    if (invocation is! MethodInvocation) return;
    if (invocation.offset != diagnostic.offset ||
        invocation.length != diagnostic.length) {
      return;
    }

    // `await` is only valid inside an async function/method/closure body.
    // Without this guard the fix would offer to insert `await` into sync
    // code, turning it into a compile error.
    final body = invocation.thisOrAncestorOfType<FunctionBody>();
    if (body == null || !body.isAsynchronous) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(invocation.offset, 'await ');
    });
  }
}
