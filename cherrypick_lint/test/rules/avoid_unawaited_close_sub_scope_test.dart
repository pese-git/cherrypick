import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/avoid_unawaited_close_sub_scope.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUnawaitedCloseSubScopeTest);
  });
}

@reflectiveTest
class AvoidUnawaitedCloseSubScopeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addCherryPickStub(this);
    rule = AvoidUnawaitedCloseSubScope();
    super.setUp();
  }

  test_closeSubScope_awaited() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

Future<void> f(Scope scope) async {
  await scope.closeSubScope('child');
}
''');
  }

  test_closeSubScope_notAwaited() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';

Future<void> f(Scope scope) async {
  scope.closeSubScope('child');
}
''',
      [lint(84, 28)],
    );
  }

  test_closeSubScope_returned() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

Future<void> f(Scope scope) async {
  return scope.closeSubScope('child');
}
''');
  }

  test_closeSubScope_storedButNeverAwaited() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';

Future<void> f(Scope scope) async {
  final job = scope.closeSubScope('child');
}
''',
      [lint(96, 28)],
    );
  }

  test_closeSubScope_storedThenAwaited() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

Future<void> f(Scope scope) async {
  final job = scope.closeSubScope('child');
  await job;
}
''');
  }

  test_closeSubScope_unawaited() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

import 'package:cherrypick/cherrypick.dart';

Future<void> f(Scope scope) async {
  unawaited(scope.closeSubScope('child'));
}
''');
  }
}
