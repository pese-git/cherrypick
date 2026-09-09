import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

/// Flags a `@module` class that doesn't have `Module` anywhere in its
/// supertype chain.
///
/// The generated part is `final class $Foo extends Foo` with an
/// `@override void builder(Scope currentScope)` body full of `bind<T>()`
/// calls — both `builder` and `bind` come from `Module`, so codegen emits a
/// part that can't compile. The generator itself reports nothing: it writes
/// the file, and the failure lands on the generated code.
class ModuleMustExtendModule extends AnalysisRule {
  static const LintCode code = LintCode(
    'module_must_extend_module',
    '@module classes must extend Module — the generated part overrides '
        'builder() and calls bind<T>(), which only Module declares.',
    correctionMessage:
        'Extend Module from package:cherrypick/cherrypick.dart, or drop the '
        '@module annotation.',
    severity: DiagnosticSeverity.ERROR,
  );

  ModuleMustExtendModule()
    : super(
        name: 'module_must_extend_module',
        description:
            'Extend Module in a @module class so the generated part '
            'compiles.',
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

    // An intermediate base class is fine, as long as Module is in the chain.
    final extendsModule = element.allSupertypes.any(
      (type) => isExactlyType(type, 'Module', 'cherrypick'),
    );
    if (extendsModule) return;

    rule.reportAtToken(node.namePart.typeName);
  }
}
