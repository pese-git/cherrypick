import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils.dart';

const _resolveMethodNames = {
  'resolve',
  'resolveAsync',
  'tryResolve',
  'tryResolveAsync',
};

/// Flags `scope.resolve<T>()` (or `resolveAsync`/`tryResolve`/
/// `tryResolveAsync`) called eagerly inside `.toInstance(...)` /
/// `.toInstanceAsync(...)`.
///
/// `toInstance` bindings are applied sequentially while a `Module`'s
/// `builder` runs; a sibling binding registered earlier in that same
/// builder isn't resolvable yet, so this throws `Can't resolve dependency
/// ...` at runtime if the resolved type was also registered in the same
/// builder. Deferring the resolve — via `.toProvide(() => ...)` — or
/// manually constructing the dependency chain before registering with
/// `.toInstance()` avoids it. See `Binding.toInstance()`'s doc comment for
/// the full explanation and "Correct"/"Wrong" examples.
class AvoidResolveInToInstance extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_resolve_in_to_instance',
    'Calling scope.resolve()/resolveAsync()/tryResolve()/'
        'tryResolveAsync() inside .toInstance()/.toInstanceAsync() can '
        "throw \"Can't resolve dependency ...\" if the resolved type is "
        'registered in the same Module builder — toInstance bindings apply '
        "sequentially, so a sibling binding isn't available yet.",
    correctionMessage:
        'Defer the resolve with .toProvide(() => ...), or manually '
        'construct the dependency chain before registering with '
        '.toInstance().',
    severity: DiagnosticSeverity.WARNING,
  );

  AvoidResolveInToInstance()
    : super(
        name: 'avoid_resolve_in_to_instance',
        description:
            'Do not resolve dependencies eagerly inside .toInstance() — '
            'sibling bindings are not registered yet.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'toInstance' &&
        node.methodName.name != 'toInstanceAsync') {
      return;
    }
    if (!isCallOn(node, 'Binding', 'cherrypick')) return;

    // A recursive visitor is fine here: it walks only this argument list,
    // not the whole unit, so it can't cause the performance problems that
    // make RecursiveAstVisitor a bad choice for a registered rule visitor.
    final visitor = _ScopeResolveVisitor();
    node.argumentList.accept(visitor);
    for (final match in visitor.matches) {
      rule.reportAtNode(match);
    }
  }
}

class _ScopeResolveVisitor extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> matches = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_resolveMethodNames.contains(node.methodName.name)) {
      if (isExactlyType(node.target?.staticType, 'Scope', 'cherrypick')) {
        matches.add(node);
      }
    }
    super.visitMethodInvocation(node);
  }
}
