// Fixtures reproducing the AddAwaitFix safety findings from PR #40 review
// (https://github.com/pese-git/cherrypick/pull/40) — asserts the lints still
// fire on these patterns, same as every other fixture in this directory.
// The *fix* behavior on the same two patterns is checked separately in
// test/expect_lint_test.dart against a disposable, untracked scratch file,
// since applying --fix here would mean mutating a committed fixture.
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
