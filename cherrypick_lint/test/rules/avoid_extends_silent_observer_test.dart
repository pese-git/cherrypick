import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/avoid_extends_silent_observer.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidExtendsSilentObserverTest);
  });
}

@reflectiveTest
class AvoidExtendsSilentObserverTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addCherryPickStub(this);
    rule = AvoidExtendsSilentObserver();
    super.setUp();
  }

  test_extendsSilentObserver() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';

class MyObserver extends SilentCherryPickObserver {}
''',
      [lint(63, 32)],
    );
  }

  test_extendsUnrelatedClass() async {
    await assertNoDiagnostics(r'''
class Base {}

class MyObserver extends Base {}
''');
  }

  test_implementsObserver() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

class MyObserver implements CherryPickObserver {}
''');
  }
}
