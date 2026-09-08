import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/module_method_missing_binding.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ModuleMethodMissingBindingTest);
  });
}

@reflectiveTest
class ModuleMethodMissingBindingTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addAnnotationsStub(this);
    rule = ModuleMethodMissingBinding();
    super.setUp();
  }

  test_privateMethod_withoutAnnotation() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
  String _helper() => 'x';
}
''');
  }

  test_publicMethod_withInstance() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
  @instance()
  String value() => 'x';
}
''');
  }

  test_publicMethod_withProvide() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
  @provide()
  String value() => 'x';
}
''');
  }

  test_publicMethod_withoutAnnotation() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
  String value() => 'x';
}
''',
      [lint(116, 5)],
    );
  }

  test_publicMethod_outsideModule() async {
    await assertNoDiagnostics(r'''
class Plain {
  String value() => 'x';
}
''');
  }
}
