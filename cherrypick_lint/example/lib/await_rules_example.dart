// Fixtures for the await-rules group.
// Run `dart run custom_lint` from this package to check them.
import 'dart:async';

import 'package:cherrypick/cherrypick.dart';

Future<void> violations() async {
  final root = CherryPick.openRootScope();
  final child = root.openSubScope('demo');

  // expect_lint: avoid_unawaited_close_sub_scope
  child.closeSubScope('grandchild');

  // expect_lint: avoid_unawaited_scope_dispose
  child.dispose();
}

Future<void> closeScopeViolation() async {
  // expect_lint: avoid_unawaited_close_scope
  CherryPick.closeScope(scopeName: 'demo');
}

Future<void> correct() async {
  final root = CherryPick.openRootScope();
  final child = root.openSubScope('demo2');

  await child.closeSubScope('grandchild');
  await child.dispose();
  unawaited(child.closeSubScope('grandchild2'));
}
