import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags `class Foo extends SilentCherryPickObserver`.
///
/// On `cherrypick` 4.x, `Scope` fast-paths
/// `if (_observer is SilentCherryPickObserver)`, so a subclass silently
/// receives none of the 14 observer callbacks. Use
/// `implements CherryPickObserver` instead.
///
/// The fast path does not exist in `cherrypick` 3.x, where a subclass still
/// receives its callbacks — the warning does not apply there and the rule
/// can be switched off. The plugin cannot tell which `cherrypick` version a
/// project uses, so it reports either way.
class AvoidExtendsSilentObserver extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_extends_silent_observer',
    'Extending SilentCherryPickObserver drops every observer callback on '
        'cherrypick 4.x — Scope fast-paths past it.',
    correctionMessage:
        'Use implements CherryPickObserver instead. (Harmless on cherrypick '
        '3.x, where this rule can be disabled.)',
    severity: DiagnosticSeverity.WARNING,
  );

  AvoidExtendsSilentObserver()
    : super(
        name: 'avoid_extends_silent_observer',
        description:
            'Implement CherryPickObserver instead of extending '
            'SilentCherryPickObserver, which cherrypick 4.x Scope fast-paths '
            'past.',
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
