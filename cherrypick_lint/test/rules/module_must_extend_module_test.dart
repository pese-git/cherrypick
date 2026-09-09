import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/module_must_extend_module.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ModuleMustExtendModuleTest);
  });
}

@reflectiveTest
class ModuleMustExtendModuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addCherryPickStub(this);
    addAnnotationsStub(this);
    rule = ModuleMustExtendModule();
    super.setUp();
  }

  test_module_extendsModule() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule extends Module {
  @provide()
  String value() => 'x';
}
''');
  }

  test_module_extendsModuleIndirectly() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

abstract class BaseModule extends Module {}

@module()
abstract class AppModule extends BaseModule {
  @provide()
  String value() => 'x';
}
''');
  }

  test_module_extendsNothing() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
  @provide()
  String value() => 'x';
}
''',
      [lint(95, 9)],
    );
  }

  test_module_extendsUnrelatedClass() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

abstract class Base {}

@module()
abstract class AppModule extends Base {
  @provide()
  String value() => 'x';
}
''',
      [lint(119, 9)],
    );
  }

  test_notAModule() async {
    await assertNoDiagnostics(r'''
abstract class Plain {}
''');
  }
}
