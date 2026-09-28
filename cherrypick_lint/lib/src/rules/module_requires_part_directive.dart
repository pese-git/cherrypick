import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// The suffix `cherrypick_generator`'s `PartBuilder` appends to the source
/// file name, i.e. the part file a `@module` library must declare.
const _generatedSuffix = '.module.cherrypick.g.dart';

/// Flags a `@module` class in a library that doesn't declare the part file
/// the generator writes into.
///
/// `moduleBuilder` is a `PartBuilder`, so without
/// `part '<file>.module.cherrypick.g.dart';` the build produces no generated
/// class at all — and says so only through a `build_runner` warning that is
/// easy to miss, since the build itself still succeeds.
class ModuleRequiresPartDirective extends AnalysisRule {
  static const LintCode code = LintCode(
    'module_requires_part_directive',
    "A @module library must declare the generator's part file "
        "'{0}' — without it codegen writes nothing.",
    correctionMessage: "Add part '{0}'; after the import directives.",
    severity: DiagnosticSeverity.ERROR,
  );

  ModuleRequiresPartDirective()
    : super(
        name: 'module_requires_part_directive',
        description:
            'Declare the generated part file in a library that holds a '
            '@module class, or codegen silently produces nothing.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !hasAnnotation(element, 'module')) return;

    final unit = node.root;
    if (unit is! CompilationUnit) return;

    // In a part file the directive belongs to the owning library, which this
    // visitor doesn't see — leave the call on the library's own unit.
    if (unit.directives.any((directive) => directive is PartOfDirective)) {
      return;
    }

    final fileName = unit.declaredFragment?.source.shortName;
    if (fileName == null || !fileName.endsWith('.dart')) return;
    final expected =
        '${fileName.substring(0, fileName.length - '.dart'.length)}'
        '$_generatedSuffix';

    final isDeclared = unit.directives.whereType<PartDirective>().any(
      (directive) => directive.uri.stringValue == expected,
    );
    if (isDeclared) return;

    rule.reportAtToken(node.namePart.typeName, arguments: [expected]);
  }
}
