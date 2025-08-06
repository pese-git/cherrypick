import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:benchmark_cherrypick/di_adapters/di_adapter.dart';
import 'package:benchmark_cherrypick/scenarios/chain_factory_module.dart';
import 'package:benchmark_cherrypick/scenarios/service.dart';

class ChainFactoryBenchmark extends BenchmarkBase {
  final DIAdapter di;
  final int chainCount;
  final int nestingDepth;

  ChainFactoryBenchmark(
    this.di, {
    this.chainCount = 1,
    this.nestingDepth = 3,
  }) : super(
          'ChainFactory (A->B->C, factory). '
          'C/D = $chainCount/$nestingDepth. ',
        );

  @override
  void setup() {
    di.setupModules([
      ChainFactoryModule(
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
