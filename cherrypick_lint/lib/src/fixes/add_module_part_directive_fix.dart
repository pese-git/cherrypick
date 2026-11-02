import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Adds the `part '<file>.module.cherrypick.g.dart';` directive the module
/// generator writes into, after the library's existing directives.
class AddModulePartDirectiveFix extends ResolvedCorrectionProducer {
  static const _addModulePartDirectiveKind = FixKind(
    'cherrypick_lint.fix.addModulePartDirective',
    DartFixKindPriority.standard,
    'Add the generated part directive',
  );

  AddModulePartDirectiveFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _addModulePartDirectiveKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final unit = node.thisOrAncestorOfType<CompilationUnit>();
    if (unit == null) return;

    final fileName = file.split(RegExp(r'[/\\]')).last;
    if (!fileName.endsWith('.dart')) return;
    final partUri =
        '${fileName.substring(0, fileName.length - '.dart'.length)}'
        '.module.cherrypick.g.dart';

    final directives = unit.directives;
    if (directives.isNotEmpty) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(directives.last.end, "\n\npart '$partUri';");
      });
      return;
    }

    // No directives at all: the part goes above the first declaration, which
    // is where the annotated class itself starts.
    final offset = unit.declarations.isEmpty
        ? 0
        : unit.declarations.first.offset;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(offset, "part '$partUri';\n\n");
    });
  }
}
