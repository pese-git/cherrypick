// ignore: depend_on_referenced_packages
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
      bind<FooService>().toProvide(() => FooService());
  }

}

// Dummy service for DI
class FooService {}

class RegisterAndResolveBenchmark extends BenchmarkBase {
  RegisterAndResolveBenchmark() : super('RegisterAndResolve');
  late final Scope scope;

  @override
  void setup() {
    CherryPick.disableGlobalCycleDetection();
    CherryPick.disableGlobalCrossScopeCycleDetection();
    scope = CherryPick.openRootScope();
    scope.installModules([AppModule()]);

  }

  @override
  void run() {
    scope.resolve<FooService>();
  }

  @override
  void teardown() => CherryPick.closeRootScope();
}

void main() {
  RegisterAndResolveBenchmark().report();
}
