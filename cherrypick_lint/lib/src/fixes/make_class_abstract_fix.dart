import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Inserts the `abstract` modifier before a `class` declaration.
class MakeClassAbstractFix extends ResolvedCorrectionProducer {
  static const _makeClassAbstractKind = FixKind(
    'cherrypick_lint.fix.makeClassAbstract',
    DartFixKindPriority.standard,
    'Make class abstract',
  );

  MakeClassAbstractFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _makeClassAbstractKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;
    if (declaration.abstractKeyword != null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(declaration.classKeyword.offset, 'abstract ');
    });
  }
}
