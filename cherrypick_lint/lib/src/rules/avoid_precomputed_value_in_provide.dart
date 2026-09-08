import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../utils.dart';

const _provideMethodNames = {
  'toProvide',
  'toProvideAsync',
  'toProvideWithParams',
  'toProvideAsyncWithParams',
};

/// Flags `.toProvide(...)` (and its `Async`/`WithParams` variants) whose
/// closure body does nothing but return a variable computed outside the
/// closure, instead of constructing a value.
///
/// A provider closure exists to be re-invoked on every `resolve<T>()` — the
/// value should be built there, that's the whole difference from
/// `toInstance()`. If the closure merely returns an already-built value, that
/// value was actually constructed once, at `Module.builder()` time, and every
/// `resolve<T>()` silently gets that same instance back — an unintended
/// pseudo-singleton that bypasses `.singleton()`'s explicit, documented
/// opt-in.
class AvoidPrecomputedValueInProvide extends DartLintRule {
  const AvoidPrecomputedValueInProvide() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_precomputed_value_in_provide',
    problemMessage:
        'This provider closure just returns a value computed outside of '
        'it instead of constructing one — the value was built once, at '
        "Module.builder() time, so every resolve<T>() silently returns "
        "the same instance, bypassing .singleton()'s explicit opt-in.",
    correctionMessage:
        'Construct the value inside the closure, e.g. '
        '.toProvide(() => Sample()), or use .toInstance(...) if a single '
        'shared instance is actually intended.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!_provideMethodNames.contains(node.methodName.name)) return;
      if (!isCallOn(node, 'Binding', 'cherrypick')) return;

      final arguments = node.argumentList.arguments;
      if (arguments.length != 1) return;
      final closure = arguments.single;
      if (closure is! FunctionExpression) return;

      final returned = _bareReturnedExpression(closure.body);
      if (returned is! SimpleIdentifier) return;
      if (returned.element is! LocalVariableElement) return;

      reporter.atNode(closure, _code);
    });
  }
}

/// If [body] does nothing but return a single expression — `=> expr` or
/// `{ return expr; }` — returns that expression; otherwise `null`.
Expression? _bareReturnedExpression(FunctionBody body) {
  if (body is ExpressionFunctionBody) return body.expression;
  if (body is BlockFunctionBody) {
    final statements = body.block.statements;
    if (statements.length != 1) return null;
    final statement = statements.single;
    if (statement is ReturnStatement) return statement.expression;
  }
  return null;
}
