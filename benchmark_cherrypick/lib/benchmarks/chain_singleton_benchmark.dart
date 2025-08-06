import 'package:benchmark_cherrypick/di_adapters/di_adapter.dart';
import 'package:benchmark_harness/benchmark_harness.dart';
import '../scenarios/chain_singleton_module.dart';
import '../scenarios/service.dart';

class ChainSingletonBenchmark extends BenchmarkBase {
  final DIAdapter di;
  final int chainCount;
  final int nestingDepth;

  ChainSingletonBenchmark(
    this.di, {
    this.chainCount = 1,
    this.nestingDepth = 3,
  }) : super(
          'ChainSingleton (A->B->C, singleton). '
          'C/D = $chainCount/$nestingDepth. ',
        );

  @override
  void setup() {
    di.setupModules([
      ChainSingletonModule(
        chainCount: chainCount,
        nestingDepth: nestingDepth,
      ),
    ]);
  }

  @override
  void teardown() => di.teardown();

  @override
  void run() {
    final serviceName = '${chainCount.toString()}_${nestingDepth.toString()}';
    di.resolve<Service>(named: serviceName);
  }
}
