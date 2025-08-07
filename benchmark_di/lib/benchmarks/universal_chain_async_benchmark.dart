import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:benchmark_di/di_adapters/di_adapter.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';

class UniversalChainAsyncBenchmark<TContainer> extends AsyncBenchmarkBase {
  final DIAdapter<TContainer> di;
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
    di.setupDependencies(di.universalRegistration(
      chainCount: chainCount,
      nestingDepth: nestingDepth,
      bindingMode: mode,
      scenario: UniversalScenario.asyncChain,
    ));
    await di.waitForAsyncReady();
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
