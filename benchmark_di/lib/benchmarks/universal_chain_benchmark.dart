import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:benchmark_di/di_adapters/di_adapter.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';

class UniversalChainBenchmark<TContainer> extends BenchmarkBase {
  final DIAdapter<TContainer> _di;
  final int chainCount;
  final int nestingDepth;
  final UniversalBindingMode mode;
  final UniversalScenario scenario;
  DIAdapter<TContainer>? _childDi;

  UniversalChainBenchmark(
    this._di, {
    this.chainCount = 1,
    this.nestingDepth = 3,
    this.mode = UniversalBindingMode.singletonStrategy,
    this.scenario = UniversalScenario.chain,
  }) : super('Universal: $scenario/$mode CD=$chainCount/$nestingDepth');

  @override
  void setup() {
    switch (scenario) {
      case UniversalScenario.override:
        _di.setupDependencies(_di.universalRegistration(
          chainCount: chainCount,
          nestingDepth: nestingDepth,
          bindingMode: UniversalBindingMode.singletonStrategy,
          scenario: UniversalScenario.chain,
        ));
        _childDi = _di.openSubScope('child');
        _childDi!.setupDependencies(_childDi!.universalRegistration(
          chainCount: chainCount,
          nestingDepth: nestingDepth,
          bindingMode: UniversalBindingMode.singletonStrategy,
          scenario: UniversalScenario.chain,
        ));
        break;
      default:
        _di.setupDependencies(_di.universalRegistration(
          chainCount: chainCount,
          nestingDepth: nestingDepth,
          bindingMode: mode,
          scenario: scenario,
        ));
        break;
    }
  }

  @override
  void teardown() => _di.teardown();

  @override
  void run() {
    switch (scenario) {
      case UniversalScenario.register:
        _di.resolve<UniversalService>();
        break;
      case UniversalScenario.named:
        if (_di.runtimeType.toString().contains('GetItAdapter')) {
          _di.resolve<UniversalService>(named: 'impl2');
        } else {
          _di.resolve<UniversalService>(named: 'impl2');
        }
        break;
      case UniversalScenario.chain:
        final serviceName = '${chainCount}_$nestingDepth';
        _di.resolve<UniversalService>(named: serviceName);
        break;
      case UniversalScenario.override:
        _childDi!.resolve<UniversalService>();
        break;
      case UniversalScenario.asyncChain:
        throw UnsupportedError('asyncChain supported only in UniversalChainAsyncBenchmark');
    }
  }
}
