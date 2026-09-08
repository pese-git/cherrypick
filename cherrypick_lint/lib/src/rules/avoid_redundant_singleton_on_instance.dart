import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../fixes/remove_redundant_singleton_fix.dart';
import '../utils.dart';

/// Flags `.singleton()` chained directly after `.toInstance(...)` /
/// `.toInstanceAsync(...)`.
///
/// Per `Binding.singleton()`'s own doc comment, the call is a no-op there:
/// the value passed to `toInstance` is already a single, constant instance
/// returned on every resolve. `.singleton()` only does something meaningful
/// after a provider (`toProvide`, `toProvideAsync`, ...).
class AvoidRedundantSingletonOnInstance extends DartLintRule {
  const AvoidRedundantSingletonOnInstance() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_redundant_singleton_on_instance',
    problemMessage:
        '.singleton() has no effect after .toInstance()/.toInstanceAsync() '
        '— the bound value is already a single, constant instance.',
    correctionMessage: 'Remove the redundant .singleton() call.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'singleton') return;
      if (!isCallOn(node, 'Binding', 'cherrypick')) return;

      final target = node.target;
      if (target is! MethodInvocation) return;
      if (target.methodName.name != 'toInstance' &&
          target.methodName.name != 'toInstanceAsync') {
        return;
      }
      if (!isCallOn(target, 'Binding', 'cherrypick')) return;

      reporter.atNode(node, _code);
    });
  }

  @override
  List<Fix> getFixes() => [RemoveRedundantSingletonFix()];
}
