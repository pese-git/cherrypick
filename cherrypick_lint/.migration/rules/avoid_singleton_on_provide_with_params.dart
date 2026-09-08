import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../utils.dart';

/// Flags `.singleton()` chained after `.toProvideWithParams(...)` /
/// `.toProvideAsyncWithParams(...)`.
///
/// Per `Binding.singleton()`'s own doc comment, only the very first
/// `resolve<T>(params: ...)` call uses its parameters — every later resolve,
/// regardless of params, returns the same cached instance. That's sometimes
/// exactly what's wanted (a "master singleton"), so unlike
/// `avoid_redundant_singleton_on_instance` this rule offers no quick fix —
/// it's a nudge to double-check intent, not a mistake to auto-correct.
class AvoidSingletonOnProvideWithParams extends DartLintRule {
  const AvoidSingletonOnProvideWithParams() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_singleton_on_provide_with_params',
    problemMessage:
        '.singleton() after .toProvideWithParams()/.toProvideAsyncWithParams() '
        'only applies params on the very first resolve — every later resolve '
        'returns the same cached instance regardless of params.',
    correctionMessage:
        'If you want a new instance per params, remove .singleton(). If a '
        'single master instance shared across all params is intended, this '
        'is fine as-is.',
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
      if (target.methodName.name != 'toProvideWithParams' &&
          target.methodName.name != 'toProvideAsyncWithParams') {
        return;
      }
      if (!isCallOn(target, 'Binding', 'cherrypick')) return;

      reporter.atNode(node, _code);
    });
  }
}
