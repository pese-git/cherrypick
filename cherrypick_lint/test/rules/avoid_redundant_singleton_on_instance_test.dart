import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/avoid_redundant_singleton_on_instance.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidRedundantSingletonOnInstanceTest);
  });
}

@reflectiveTest
class AvoidRedundantSingletonOnInstanceTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addCherryPickStub(this);
    rule = AvoidRedundantSingletonOnInstance();
    super.setUp();
  }

  test_singleton_afterProvide() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<String>().toProvide(() => 'x').singleton();
  }
}
''');
  }

  test_singleton_afterToInstance() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<String>().toInstance('x').singleton();
  }
}
''',
      [lint(132, 42)],
    );
  }

  test_singleton_afterToInstanceAsync() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<String>().toInstanceAsync('x').singleton();
  }
}
''',
      [lint(132, 47)],
    );
  }

  test_toInstance_withoutSingleton() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<String>().toInstance('x');
  }
}
''');
  }
}
