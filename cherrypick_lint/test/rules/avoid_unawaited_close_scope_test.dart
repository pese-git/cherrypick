import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/avoid_unawaited_close_scope.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUnawaitedCloseScopeTest);
  });
}

@reflectiveTest
class AvoidUnawaitedCloseScopeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addCherryPickStub(this);
    rule = AvoidUnawaitedCloseScope();
    super.setUp();
  }

  test_closeScope_awaited() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

Future<void> f() async {
  await CherryPick.closeScope(scopeName: 'a');
}
''');
  }

  test_closeScope_notAwaited() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';

Future<void> f() async {
  CherryPick.closeScope(scopeName: 'a');
}
''',
      [lint(73, 37)],
    );
  }

  test_closeScope_onUnrelatedClass() async {
    await assertNoDiagnostics(r'''
class Other {
  static Future<void> closeScope() async {}
}

Future<void> f() async {
  Other.closeScope();
}
''');
  }

  test_closeScope_returned() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

Future<void> f() async {
  return CherryPick.closeScope(scopeName: 'a');
}
''');
  }

  test_closeScope_storedThenAwaited() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

Future<void> f() async {
  final job = CherryPick.closeScope(scopeName: 'a');
  await job;
}
''');
  }

  test_closeScope_unawaited() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

import 'package:cherrypick/cherrypick.dart';

Future<void> f() async {
  unawaited(CherryPick.closeScope(scopeName: 'a'));
}
''');
  }
}
