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
  ScopeOverrideBenchmark() : super('ScopeOverride (child overrides parent)');
  late Scope parent;
  late Scope child;
  @override
  void setup() {
    CherryPick.disableGlobalCycleDetection();
    CherryPick.disableGlobalCrossScopeCycleDetection();
    parent = CherryPick.openRootScope();
    parent.installModules([ParentModule()]);
    child = parent.openSubScope('child');
    child.installModules([ChildOverrideModule()]);
  }
  @override
  void teardown() {
    CherryPick.closeRootScope();
  }
  @override
  void run() {
    // Должен возвращать ChildImpl, а не ParentImpl
    final resolved = child.resolve<Shared>();
    assert(resolved is ChildImpl);
  }
}
