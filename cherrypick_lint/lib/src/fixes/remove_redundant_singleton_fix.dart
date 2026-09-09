import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Deletes a redundant `.singleton()` call chained after `.toInstance(...)`.
class RemoveRedundantSingletonFix extends CorrectionProducerWithDiagnostic {
  static const _removeRedundantSingletonKind = FixKind(
    'cherrypick_lint.fix.removeRedundantSingleton',
    DartFixKindPriority.standard,
    'Remove redundant .singleton()',
  );

  RemoveRedundantSingletonFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _removeRedundantSingletonKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final invocation = node;
    if (invocation is! MethodInvocation) return;
    if (invocation.offset != diagnostic.offset ||
        invocation.length != diagnostic.length) {
      return;
    }

    final target = invocation.target;
    if (target == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(SourceRange(target.end, invocation.end - target.end));
    });
  }
}
