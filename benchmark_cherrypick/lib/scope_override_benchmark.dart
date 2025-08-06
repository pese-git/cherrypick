// ignore: depend_on_referenced_packages
import 'package:benchmark_cherrypick/di_adapter.dart';
// ignore: depend_on_referenced_packages
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cherrypick/cherrypick.dart';

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

class ScopeOverrideBenchmark extends BenchmarkBase {
  final DIAdapter di;
  late DIAdapter childDi;

  ScopeOverrideBenchmark(this.di) : super('ScopeOverride (child overrides parent)');

  @override
  void setup() {
    di.setupModules([ParentModule()]);
    childDi = di.openSubScope('child');
    childDi.setupModules([ChildOverrideModule()]);
  }

  @override
  void teardown() => di.teardown();

  @override
  void run() {
    // Should return ChildImpl, not ParentImpl
    final resolved = childDi.resolve<Shared>();
    assert(resolved is ChildImpl);
  }
}
