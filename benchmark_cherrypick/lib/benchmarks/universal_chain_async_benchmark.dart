import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:benchmark_cherrypick/di_adapters/di_adapter.dart';
import 'package:benchmark_cherrypick/scenarios/universal_chain_module.dart';
import 'package:benchmark_cherrypick/scenarios/universal_service.dart';

class UniversalChainAsyncBenchmark extends AsyncBenchmarkBase {
  final DIAdapter di;
  final int chainCount;
  final int nestingDepth;
  final UniversalBindingMode mode;

  UniversalChainAsyncBenchmark(
    this.di, {
    this.chainCount = 1,
    this.nestingDepth = 3,
    this.mode = UniversalBindingMode.asyncStrategy,
  }) : super('UniversalAsync: asyncChain/$mode CD=$chainCount/$nestingDepth');

  @override
  Future<void> setup() async {
    di.setupDependencies((scope) {
      scope.installModules([
        UniversalChainModule(
          chainCount: chainCount,
          nestingDepth: nestingDepth,
          bindingMode: mode,
          scenario: UniversalScenario.asyncChain,
        ),
      ]);
    });
  }

  @override
  Future<void> teardown() async {
    di.teardown();
  }

  @override
  Future<void> run() async {
    final serviceName = '${chainCount}_$nestingDepth';
    await di.resolveAsync<UniversalService>(named: serviceName);
  }
}
