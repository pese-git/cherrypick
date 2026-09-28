import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/params_requires_provide.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParamsRequiresProvideTest);
  });
}

@reflectiveTest
class ParamsRequiresProvideTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addAnnotationsStub(this);
    rule = ParamsRequiresProvide();
    super.setUp();
  }

  test_params_withoutProvide() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
  @params()
  String value(dynamic params) => 'x';
}
''',
      [lint(128, 5)],
    );
  }

  test_params_withProvide() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
  @provide()
  @params()
  String value(dynamic params) => 'x';
}
''');
  }

  test_provide_withoutParams() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
  @provide()
  String value() => 'x';
}
''');
  }
}
