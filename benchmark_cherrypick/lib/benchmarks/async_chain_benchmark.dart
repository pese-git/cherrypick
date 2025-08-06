import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:benchmark_cherrypick/di_adapters/di_adapter.dart';
import 'package:benchmark_cherrypick/scenarios/async_chain_module.dart';

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
