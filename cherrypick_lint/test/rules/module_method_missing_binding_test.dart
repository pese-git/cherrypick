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

  test_getter_withoutAnnotation() async {
    // Getters and setters are not part of `ClassElement.methods`, so the
    // generator never validates them.
    await assertNoDiagnostics(r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
  String get value => 'x';

  set value(String _) {}
}
''');
  }

  test_privateMethod_withoutAnnotation() async {
    // The generator hands every non-abstract method to its validator without
    // filtering by visibility, so a private helper fails the build too.
    await assertDiagnostics(
      r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
  String _helper() => 'x';
}
''',
      [lint(116, 7)],
    );
  }

  test_privateMethod_withProvide() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
  @provide()
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

  test_staticMethod_withoutAnnotation() async {
    // Static methods are in `ClassElement.methods` as well, so they reach the
    // generator's validator and fail the build.
    await assertDiagnostics(
      r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
  static String helper() => 'x';
}
''',
      [lint(123, 6)],
    );
  }
}
