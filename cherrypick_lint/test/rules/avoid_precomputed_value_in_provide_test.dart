import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/avoid_precomputed_value_in_provide.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidPrecomputedValueInProvideTest);
  });
}

@reflectiveTest
class AvoidPrecomputedValueInProvideTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addCherryPickStub(this);
    rule = AvoidPrecomputedValueInProvide();
    super.setUp();
  }

  test_provide_constructsInsideClosure() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

class Sample {
  Sample(this.count);
  final int count;
}

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    final count = 1;
    bind<Sample>().toProvide(() => Sample(count));
  }
}
''');
  }

  test_provide_returnsPrecomputedVariable() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';

class Sample {}

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    final sample = Sample();
    bind<Sample>().toProvide(() => sample);
  }
}
''',
      [lint(203, 12)],
    );
  }

  test_provideAsync_returnsPrecomputedVariable() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';

class Sample {}

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    final sample = Sample();
    bind<Sample>().toProvideAsync(() async => sample);
  }
}
''',
      [lint(208, 18)],
    );
  }

  test_toInstance_withPrecomputedVariable() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

class Sample {}

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    final sample = Sample();
    bind<Sample>().toInstance(sample);
  }
}
''');
  }
}
