import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/module_must_be_abstract.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ModuleMustBeAbstractTest);
  });
}

@reflectiveTest
class ModuleMustBeAbstractTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addAnnotationsStub(this);
    rule = ModuleMustBeAbstract();
    super.setUp();
  }

  test_module_abstract() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {}
''');
  }

  test_module_concrete() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
class AppModule {}
''',
      [lint(86, 9)],
    );
  }

  test_notAModule() async {
    await assertNoDiagnostics(r'''
class Plain {}
''');
  }
}
