import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/avoid_singleton_on_provide_with_params.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidSingletonOnProvideWithParamsTest);
  });
}

@reflectiveTest
class AvoidSingletonOnProvideWithParamsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addCherryPickStub(this);
    rule = AvoidSingletonOnProvideWithParams();
    super.setUp();
  }

  test_provideWithParams_withoutSingleton() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<String>().toProvideWithParams((params) => 'x');
  }
}
''');
  }

  test_singleton_afterProvideAsyncWithParams() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<String>().toProvideAsyncWithParams((params) async => 'x').singleton();
  }
}
''',
      [lint(132, 74)],
    );
  }

  test_singleton_afterProvideWithParams() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<String>().toProvideWithParams((params) => 'x').singleton();
  }
}
''',
      [lint(132, 63)],
    );
  }
}
