import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags a `@module` class that isn't declared `abstract`.
///
/// The generator itself doesn't require `abstract` — it collects the
/// non-abstract methods and emits `final class $Foo extends Foo` either way.
/// A concrete `@module` class is nevertheless a dead end, because
/// `Module.builder` is abstract:
/// - without a `builder` override, Dart rejects the class itself
///   (`non_abstract_class_inherits_abstract_member`);
/// - with one, `builder` is a non-abstract method carrying neither `@provide`
///   nor `@instance`, so the generator's own validator fails the build on it
///   ('Method must be marked with either @instance or @provide annotation').
///
/// So `abstract` is the only shape that works, and it stays an `error`.
class ModuleMustBeAbstract extends AnalysisRule {
  static const LintCode code = LintCode(
    'module_must_be_abstract',
    '@module classes must be declared abstract: Module.builder is abstract, '
        'so a concrete module either fails to compile without a builder '
        'override or fails codegen with one.',
    correctionMessage: 'Add the abstract modifier to this class.',
    severity: DiagnosticSeverity.ERROR,
  );

  ModuleMustBeAbstract()
    : super(
        name: 'module_must_be_abstract',
        description:
            'Declare @module classes abstract — a concrete one cannot both '
            'satisfy Module.builder and pass codegen.',
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
