import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cherrypick/cherrypick.dart';

class AsyncA {}
class AsyncB {
  final AsyncA a;
  AsyncB(this.a);
}
class AsyncC {
  final AsyncB b;
  AsyncC(this.b);
}

class AsyncChainModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<AsyncA>().toProvideAsync(() async => AsyncA()).singleton();
    bind<AsyncB>().toProvideAsync(() async => AsyncB(await currentScope.resolveAsync<AsyncA>())).singleton();
    bind<AsyncC>().toProvideAsync(() async => AsyncC(await currentScope.resolveAsync<AsyncB>())).singleton();
  }
}

class AsyncChainBenchmark extends AsyncBenchmarkBase {
  AsyncChainBenchmark() : super('AsyncChain (A->B->C, async)');
  late Scope scope;

  @override
  Future<void> setup() async {
    CherryPick.disableGlobalCycleDetection();
    CherryPick.disableGlobalCrossScopeCycleDetection();
    scope = CherryPick.openRootScope();
    scope.installModules([AsyncChainModule()]);
  }
  @override
  Future<void> teardown() async {
    CherryPick.closeRootScope();
  }
  @override
  Future<void> run() async {
    await scope.resolveAsync<AsyncC>();
  }
}
