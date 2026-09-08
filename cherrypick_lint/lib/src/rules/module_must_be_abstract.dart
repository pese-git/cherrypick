import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags a `@module` class that isn't declared `abstract`.
///
/// The generator emits a concrete `final class $Foo extends Foo`; if `Foo`
/// isn't abstract, the generated code may fail to compile or misbehave.
class ModuleMustBeAbstract extends AnalysisRule {
  static const LintCode code = LintCode(
    'module_must_be_abstract',
    '@module classes must be declared abstract.',
    correctionMessage: 'Add the abstract modifier to this class.',
    severity: DiagnosticSeverity.ERROR,
  );

  ModuleMustBeAbstract()
    : super(
        name: 'module_must_be_abstract',
        description:
            'Declare @module classes abstract so the generated subclass is '
            'valid.',
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
    if (node.abstractKeyword != null) return;

    rule.reportAtToken(node.namePart.typeName);
  }
}
