import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:cherrypick_lint/src/rules/avoid_resolve_in_to_instance.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidResolveInToInstanceTest);
  });
}

@reflectiveTest
class AvoidResolveInToInstanceTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addCherryPickStub(this);
    rule = AvoidResolveInToInstance();
    super.setUp();
  }

  test_resolve_deferredInProvide() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<String>().toProvide(() => currentScope.resolve<String>());
  }
}
''');
  }

  test_resolve_insideToInstance() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<String>().toInstance(currentScope.resolve<String>());
  }
}
''',
      [lint(158, 30)],
    );
  }

  test_toInstance_withoutResolve() async {
    await assertNoDiagnostics(r'''
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<String>().toInstance('x');
  }
}
''');
  }

  test_tryResolveAsync_insideToInstanceAsync() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<String?>().toInstanceAsync(currentScope.tryResolveAsync<String>());
  }
}
''',
      [lint(164, 38)],
    );
  }

  test_twoResolves_reportedSeparately() async {
    await assertDiagnostics(
      r'''
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<String>().toInstance(
      currentScope.resolve<String>() + currentScope.resolve<String>(),
    );
  }
}
''',
      [lint(165, 30), lint(198, 30)],
    );
  }
}
