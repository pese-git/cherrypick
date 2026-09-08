import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags `class Foo extends SilentCherryPickObserver`.
///
/// `Scope` fast-paths `if (_observer is SilentCherryPickObserver)`, so a
/// subclass silently receives none of the 14 observer callbacks. Use
/// `implements CherryPickObserver` instead.
class AvoidExtendsSilentObserver extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_extends_silent_observer',
    'Extending SilentCherryPickObserver silently drops every observer '
        'callback — Scope fast-paths past it.',
    correctionMessage: 'Use implements CherryPickObserver instead.',
    severity: DiagnosticSeverity.WARNING,
  );

  AvoidExtendsSilentObserver()
    : super(
        name: 'avoid_extends_silent_observer',
        description:
            'Implement CherryPickObserver instead of extending '
            'SilentCherryPickObserver, which Scope fast-paths past.',
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
    final extendsClause = node.extendsClause;
    final type = extendsClause?.superclass.type;
    if (!isExactlyType(type, 'SilentCherryPickObserver', 'cherrypick')) return;

    rule.reportAtNode(extendsClause!);
  }
}
