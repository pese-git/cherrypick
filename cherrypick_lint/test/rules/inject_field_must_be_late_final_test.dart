import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/inject_field_must_be_late_final.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InjectFieldMustBeLateFinalTest);
  });
}

@reflectiveTest
class InjectFieldMustBeLateFinalTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addAnnotationsStub(this);
    rule = InjectFieldMustBeLateFinal();
    super.setUp();
  }

  test_injectField_lateFinal() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@injectable()
class Service {
  @inject()
  late final String value;
}
''');
  }

  test_injectField_lateOnly() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@injectable()
class Service {
  @inject()
  late String value;
}
''',
      [lint(126, 5)],
    );
  }

  test_injectField_plain() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@injectable()
class Service {
  @inject()
  String? value;
}
''',
      [lint(122, 5)],
    );
  }

  test_plainField() async {
    await assertNoDiagnostics(r'''
class Service {
  String? value;
}
''');
  }
}
