import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/avoid_unawaited_scope_dispose.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUnawaitedScopeDisposeTest);
  });
}

@reflectiveTest
class AvoidUnawaitedScopeDisposeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    // Stub sources for the types the rule matches on; the real `cherrypick`
    // package is deliberately not a dependency of the plugin.
    newPackage('cherrypick').addFile('lib/cherrypick.dart', r'''
class Scope {
  Future<void> dispose() async {}
}

class MyService {
  void dispose() {}
}
''');
    rule = AvoidUnawaitedScopeDispose();
    super.setUp();
  }

  test_dispose_awaited() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

Future<void> f(Scope scope) async {
  await scope.dispose();
}
''');
  }

  test_dispose_notAwaited() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';

Future<void> f(Scope scope) async {
  scope.dispose();
}
''',
      [lint(84, 15)],
    );
  }

  test_dispose_onUserDisposable() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

Future<void> f(MyService service) async {
  service.dispose();
}
''');
  }

  test_dispose_returned() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

Future<void> f(Scope scope) async {
  return scope.dispose();
}
''');
  }

  test_dispose_storedThenAwaited() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

Future<void> f(Scope scope) async {
  final job = scope.dispose();
  await job;
}
''');
  }

  test_dispose_unawaited() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

import 'package:cherrypick/cherrypick.dart';

Future<void> f(Scope scope) async {
  unawaited(scope.dispose());
}
''');
  }
}
