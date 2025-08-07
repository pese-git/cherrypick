import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:benchmark_di/di_adapters/di_adapter.dart';
import 'package:benchmark_di/scenarios/universal_chain_module.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';
import 'package:benchmark_di/scenarios/di_universal_registration.dart';

class UniversalChainBenchmark extends BenchmarkBase {
  final DIAdapter _di;
  final int chainCount;
  final int nestingDepth;
  final UniversalBindingMode mode;
  final UniversalScenario scenario;
  DIAdapter? _childDi;

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
        _di.setupDependencies(getUniversalRegistration(
          _di,
          chainCount: chainCount,
          nestingDepth: nestingDepth,
          bindingMode: UniversalBindingMode.singletonStrategy,
          scenario: UniversalScenario.chain,
        ));
        _childDi = _di.openSubScope('child');
        _childDi!.setupDependencies(getUniversalRegistration(
          _childDi!,
          chainCount: chainCount,
          nestingDepth: nestingDepth,
          bindingMode: UniversalBindingMode.singletonStrategy,
          scenario: UniversalScenario.chain, // критично: цепочку, а не просто alias!
        ));
        break;
      default:
        _di.setupDependencies(getUniversalRegistration(
          _di,
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
