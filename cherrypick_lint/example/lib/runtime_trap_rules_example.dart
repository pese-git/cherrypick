// Fixtures for the runtime-trap-rules group.
// Run `dart run custom_lint` from this package to check them.
import 'package:cherrypick/cherrypick.dart';

// expect_lint: avoid_extends_silent_observer
class BadObserver extends SilentCherryPickObserver {}

/// Extending an unrelated class must not trigger the rule.
class GoodObserver extends PrintCherryPickObserver {}

void violations() {
  // expect_lint: avoid_experimental_scope_api
  CherryPick.openScope(scopeName: 'demo');
}

void correct() {
  final root = CherryPick.openRootScope();
  root.openSubScope('demo');
}
