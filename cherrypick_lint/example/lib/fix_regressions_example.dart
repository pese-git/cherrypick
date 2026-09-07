// Fixtures reproducing the findings from the PR #40 review
// (https://github.com/pese-git/cherrypick/pull/40) — asserts each lint fires
// (or doesn't) exactly as expected, same as every other fixture in this
// directory. The *fix* behavior of the two still-firing cases below is
// checked separately in test/expect_lint_test.dart against a disposable,
// untracked scratch file, since applying --fix here would mean mutating a
// committed fixture.
import 'dart:async';

import 'package:cherrypick/cherrypick.dart';

/// The enclosing function is not `async` — AddAwaitFix must not offer
/// "Add await" here, since inserting `await` outside an async function
/// is a compile error.
void disposeScopeSync(Scope scope) {
  // expect_lint: avoid_unawaited_scope_dispose
  scope.dispose();
}

/// Both calls are already collected and awaited together via
/// `Future.wait`. AddAwaitFix must only ever edit the exact node it was
/// asked to fix — never a method invocation (like the outer `Future.wait`
/// call itself) whose range merely contains that node.
Future<void> batchCloseSubScopes(Scope child) async {
  // expect_lint: avoid_unawaited_close_sub_scope
  await Future.wait([child.closeSubScope('1'), child.closeSubScope('2')]);
}

/// The Future is stored and awaited later in the same block — not dropped,
/// just not awaited inline. No diagnostic expected.
Future<void> storeThenAwaitSeparately(Scope child) async {
  final job = child.closeSubScope('1');
  await job;
}

/// The Future is handed back to the caller, whose responsibility it becomes.
/// No diagnostic expected, in either a block or an arrow body.
Future<void> delegateToCaller(Scope child) {
  return child.closeSubScope('1');
}

Future<void> delegateToCallerArrow(Scope child) => child.closeSubScope('1');

/// Control case: stored but genuinely never awaited anywhere — must still
/// fire, so the two "handled" cases above aren't just switching the rule off.
Future<void> storedButNeverAwaited(Scope child) async {
  // expect_lint: avoid_unawaited_close_sub_scope
  final job = child.closeSubScope('1');
  print(job);
}
