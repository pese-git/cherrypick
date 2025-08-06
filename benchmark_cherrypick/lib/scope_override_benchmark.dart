// ignore: depend_on_referenced_packages
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cherrypick/cherrypick.dart';
import 'benchmark_utils.dart';

class Shared {}

class ParentImpl extends Shared {}

class ChildImpl extends Shared {}

class ParentModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Shared>().toProvide(() => ParentImpl()).singleton();
  }
}

class ChildOverrideModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Shared>().toProvide(() => ChildImpl()).singleton();
  }
}

class ScopeOverrideBenchmark extends BenchmarkBase with BenchmarkWithScope {
  ScopeOverrideBenchmark() : super('ScopeOverride (child overrides parent)');
  late Scope child;

  @override
  void setup() {
    setupScope([ParentModule()]);
    child = scope.openSubScope('child');
    child.installModules([ChildOverrideModule()]);
  }

  @override
  void teardown() {
    teardownScope();
  }

  @override
  void run() {
    // Должен возвращать ChildImpl, а не ParentImpl
    final resolved = child.resolve<Shared>();
    assert(resolved is ChildImpl);
  }
}
