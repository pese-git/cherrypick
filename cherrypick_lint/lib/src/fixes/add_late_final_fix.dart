import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Adds the missing `late` and/or `final` modifiers to a field declaration.
class AddLateFinalFix extends ResolvedCorrectionProducer {
  static const _addLateFinalKind = FixKind(
    'cherrypick_lint.fix.addLateFinal',
    DartFixKindPriority.standard,
    'Add late final',
  );

  AddLateFinalFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _addLateFinalKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<FieldDeclaration>();
    if (declaration == null) return;

    final fields = declaration.fields;
    if (fields.isLate && fields.isFinal) return;

    await builder.addDartFileEdit(file, (builder) {
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
  }
}
