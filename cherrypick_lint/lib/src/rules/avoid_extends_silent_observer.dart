import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../fixes/replace_extends_with_implements_fix.dart';

const _observerChecker = TypeChecker.fromName(
  'SilentCherryPickObserver',
  packageName: 'cherrypick',
);

/// Flags `class Foo extends SilentCherryPickObserver`.
///
/// `Scope` fast-paths `if (_observer is SilentCherryPickObserver)`, so a
/// subclass silently receives none of the 14 observer callbacks. Use
/// `implements CherryPickObserver` instead.
class AvoidExtendsSilentObserver extends DartLintRule {
  const AvoidExtendsSilentObserver() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_extends_silent_observer',
    problemMessage:
        'Extending SilentCherryPickObserver silently drops every observer '
        'callback — Scope fast-paths past it.',
    correctionMessage: 'Use implements CherryPickObserver instead.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final superclass = node.extendsClause?.superclass;
      final type = superclass?.type;
      if (type == null || !_observerChecker.isExactlyType(type)) return;

      reporter.atNode(node.extendsClause!, _code);
    });
  }

  @override
  List<Fix> getFixes() => [ReplaceExtendsWithImplementsFix()];
}
