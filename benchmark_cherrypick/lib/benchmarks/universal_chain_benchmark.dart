import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:benchmark_cherrypick/di_adapters/di_adapter.dart';
import 'package:benchmark_cherrypick/scenarios/universal_chain_module.dart';
import 'package:benchmark_cherrypick/scenarios/universal_service.dart';

class UniversalChainBenchmark extends BenchmarkBase {
  final DIAdapter di;
  final int chainCount;
  final int nestingDepth;
  final UniversalBindingMode mode;

  UniversalChainBenchmark(
      this.di, {
      this.chainCount = 1,
      this.nestingDepth = 3,
      this.mode = UniversalBindingMode.singletonStrategy,
    }) : super(
          'UniversalChain: $mode. C/D = $chainCount/$nestingDepth',
        );

  @override
  void setup() {
    di.setupModules([
      UniversalChainModule(
        chainCount: chainCount,
        nestingDepth: nestingDepth,
        bindingMode: mode,
      ),
    ]);
  }

  @override
  void teardown() => di.teardown();

  @override
  void run() {
    final serviceName = '${chainCount}_$nestingDepth';
    di.resolve<UniversalService>(named: serviceName);
  }
}
