// ignore: depend_on_referenced_packages
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cherrypick/cherrypick.dart';

// === DI graph: A -> B -> C (singleton) ===
class ServiceA {}
class ServiceB {
  final ServiceA a;
  ServiceB(this.a);
}
class ServiceC {
  final ServiceB b;
  ServiceC(this.b);
}

class ChainSingletonModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ServiceA>().toProvide(() => ServiceA()).singleton();
    bind<ServiceB>().toProvide((() => ServiceB(currentScope.resolve<ServiceA>()))).singleton();
    bind<ServiceC>().toProvide((() => ServiceC(currentScope.resolve<ServiceB>()))).singleton();
  }
}

class ChainSingletonBenchmark extends BenchmarkBase {
  ChainSingletonBenchmark() : super('ChainSingleton (A->B->C, singleton)');
  late Scope scope;
  @override
  void setup() {
    scope = CherryPick.openRootScope();
    scope.installModules([ChainSingletonModule()]);
  }
  @override
  void teardown() => CherryPick.closeRootScope();
  @override
  void run() {
    scope.resolve<ServiceC>();
  }
}

// === DI graph: A -> B -> C (factory/no singleton) ===
class ChainFactoryModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ServiceA>().toProvide(() => ServiceA());
    bind<ServiceB>().toProvide((() => ServiceB(currentScope.resolve<ServiceA>())));
    bind<ServiceC>().toProvide((() => ServiceC(currentScope.resolve<ServiceB>())));
  }
}

class ChainFactoryBenchmark extends BenchmarkBase {
  ChainFactoryBenchmark() : super('ChainFactory (A->B->C, factory)');
  late Scope scope;
  @override
  void setup() {
    CherryPick.disableGlobalCycleDetection();
    CherryPick.disableGlobalCrossScopeCycleDetection();
    scope = CherryPick.openRootScope();
    scope.installModules([ChainFactoryModule()]);
  }
  @override
  void teardown() => CherryPick.closeRootScope();
  @override
  void run() {
    scope.resolve<ServiceC>();
  }
}

// === Named bindings: Multiple implementations ===
class Impl1 {}
class Impl2 {}
class NamedModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Object>().toProvide(() => Impl1()).withName('impl1');
    bind<Object>().toProvide(() => Impl2()).withName('impl2');
  }
}

class NamedResolveBenchmark extends BenchmarkBase {
  NamedResolveBenchmark() : super('NamedResolve (by name)');
  late Scope scope;
  @override
  void setup() {
    scope = CherryPick.openRootScope();
    scope.installModules([NamedModule()]);
  }
  @override
  void teardown() => CherryPick.closeRootScope();
  @override
  void run() {
    // Switch name for comparison
    scope.resolve<Object>(named: 'impl2');
  }
}
