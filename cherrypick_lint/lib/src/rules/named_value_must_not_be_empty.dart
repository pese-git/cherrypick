import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags `@named('')` — an empty name is indistinguishable from no name and
/// leads to unpredictable resolution.
class NamedValueMustNotBeEmpty extends AnalysisRule {
  static const LintCode code = LintCode(
    'named_value_must_not_be_empty',
    '@named must not be given an empty string.',
    correctionMessage: 'Provide a non-empty name, or remove the annotation.',
    severity: DiagnosticSeverity.ERROR,
  );

  NamedValueMustNotBeEmpty()
    : super(
        name: 'named_value_must_not_be_empty',
        description: 'Give @named a non-empty name.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addAnnotation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitAnnotation(Annotation node) {
    final owner = enclosingElementOf(node.element);
    if (owner?.name != 'named' ||
        !isDeclaredInPackage(owner, 'cherrypick_annotations')) {
      return;
    }

    final arguments = node.arguments?.arguments;
    if (arguments == null || arguments.isEmpty) return;

    final valueArg = arguments.first;
    if (valueArg is! StringLiteral) return;
    if (valueArg.stringValue != '') return;

    rule.reportAtNode(node);
  }
}
