import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags an `@inject` field that isn't declared `late final`.
///
/// Without `late`, the field can't be initialized after the constructor
/// runs; without `final`, it can be silently overwritten after injection.
class InjectFieldMustBeLateFinal extends AnalysisRule {
  static const LintCode code = LintCode(
    'inject_field_must_be_late_final',
    '@inject fields must be declared late final.',
    correctionMessage: 'Add the late final modifiers to this field.',
    severity: DiagnosticSeverity.ERROR,
  );

  InjectFieldMustBeLateFinal()
    : super(
        name: 'inject_field_must_be_late_final',
        description:
            'Declare @inject fields late final so they can be injected once '
            'and never reassigned.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addFieldDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (final variable in node.fields.variables) {
      final element = variable.declaredFragment?.element;
      if (element == null || !hasAnnotation(element, 'inject')) continue;
      if (variable.isLate && variable.isFinal) continue;

      rule.reportAtToken(variable.name);
    }
  }
}
