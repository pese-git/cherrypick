import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Replaces `extends SilentCherryPickObserver` with
/// `implements CherryPickObserver`, merging into an existing `implements`
/// clause if the class already has one.
class ReplaceExtendsWithImplementsFix extends ResolvedCorrectionProducer {
  static const _replaceExtendsWithImplementsKind = FixKind(
    'cherrypick_lint.fix.replaceExtendsWithImplements',
    DartFixKindPriority.standard,
    'Replace with implements CherryPickObserver',
  );

  ReplaceExtendsWithImplementsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _replaceExtendsWithImplementsKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    final extendsClause = declaration?.extendsClause;
    if (declaration == null || extendsClause == null) return;

    await builder.addDartFileEdit(file, (builder) {
      final implementsClause = declaration.implementsClause;
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
  }
}
