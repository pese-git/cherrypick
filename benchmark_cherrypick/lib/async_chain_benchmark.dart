// ignore: depend_on_referenced_packages
import 'package:benchmark_cherrypick/di_adapter.dart';
// ignore: depend_on_referenced_packages
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
    bind<AsyncB>()
        .toProvideAsync(
            () async => AsyncB(await currentScope.resolveAsync<AsyncA>()))
        .singleton();
    bind<AsyncC>()
        .toProvideAsync(
            () async => AsyncC(await currentScope.resolveAsync<AsyncB>()))
        .singleton();
  }
}

class AsyncChainBenchmark extends AsyncBenchmarkBase {
  final DIAdapter di;
  AsyncChainBenchmark(this.di) : super('AsyncChain (A->B->C, async)');

  @override
  Future<void> setup() async {
    di.setupModules([AsyncChainModule()]);
  }

  @override
  Future<void> teardown() async {
    di.teardown();
  }

  @override
  Future<void> run() async {
    await di.resolveAsync<AsyncC>();
  }
}
