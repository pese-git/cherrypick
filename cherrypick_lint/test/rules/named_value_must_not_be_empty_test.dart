import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/named_value_must_not_be_empty.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NamedValueMustNotBeEmptyTest);
  });
}

@reflectiveTest
class NamedValueMustNotBeEmptyTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addAnnotationsStub(this);
    rule = NamedValueMustNotBeEmpty();
    super.setUp();
  }

  test_named_empty() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
  @provide()
  @named('')
  String value() => 'x';
}
''',
      [lint(122, 10)],
    );
  }

  test_named_nonEmpty() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
  @provide()
  @named('api')
  String value() => 'x';
}
''');
  }

  test_unrelatedAnnotation() async {
    await assertNoDiagnostics(r'''
class named {
  final String value;
  const named(this.value);
}

@named('')
class Other {}
''');
  }
}
