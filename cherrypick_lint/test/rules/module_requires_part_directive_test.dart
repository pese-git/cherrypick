import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/module_requires_part_directive.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ModuleRequiresPartDirectiveTest);
  });
}

@reflectiveTest
class ModuleRequiresPartDirectiveTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addCherryPickStub(this);
    addAnnotationsStub(this);
    rule = ModuleRequiresPartDirective();
    super.setUp();
  }

  test_module_withPartDirective() async {
    newFile(
      '$testPackageLibPath/test.module.cherrypick.g.dart',
      "part of 'test.dart';",
    );
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test.module.cherrypick.g.dart';

@module()
abstract class AppModule extends Module {
  @provide()
  String value() => 'x';
}
''');
  }

  test_module_withoutPartDirective() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule extends Module {
  @provide()
  String value() => 'x';
}
''',
      [lint(140, 9)],
    );
  }

  test_module_withUnrelatedPartDirective() async {
    newFile('$testPackageLibPath/other.g.dart', "part of 'test.dart';");
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'other.g.dart';

@module()
abstract class AppModule extends Module {
  @provide()
  String value() => 'x';
}
''',
      [lint(162, 9)],
    );
  }

  test_notAModule() async {
    await assertNoDiagnostics(r'''
abstract class Plain {}
''');
  }
}
