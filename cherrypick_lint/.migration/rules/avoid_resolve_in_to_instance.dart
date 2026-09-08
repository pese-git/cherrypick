import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../utils.dart';

const _scopeChecker = TypeChecker.fromName('Scope', packageName: 'cherrypick');

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
class AvoidResolveInToInstance extends DartLintRule {
  const AvoidResolveInToInstance() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_resolve_in_to_instance',
    problemMessage:
        'Calling scope.resolve()/resolveAsync()/tryResolve()/'
        'tryResolveAsync() inside .toInstance()/.toInstanceAsync() can '
        "throw \"Can't resolve dependency ...\" if the resolved type is "
        'registered in the same Module builder — toInstance bindings apply '
        "sequentially, so a sibling binding isn't available yet.",
    correctionMessage:
        'Defer the resolve with .toProvide(() => ...), or manually '
        'construct the dependency chain before registering with '
        '.toInstance().',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'toInstance' &&
          node.methodName.name != 'toInstanceAsync') {
        return;
      }
      if (!isCallOn(node, 'Binding', 'cherrypick')) return;

      final visitor = _ScopeResolveVisitor();
      node.argumentList.accept(visitor);
      for (final match in visitor.matches) {
        reporter.atNode(match, _code);
      }
    });
  }
}

class _ScopeResolveVisitor extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> matches = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_resolveMethodNames.contains(node.methodName.name)) {
      final targetType = node.target?.staticType;
      if (targetType != null && _scopeChecker.isExactlyType(targetType)) {
        matches.add(node);
      }
    }
    super.visitMethodInvocation(node);
  }
}
