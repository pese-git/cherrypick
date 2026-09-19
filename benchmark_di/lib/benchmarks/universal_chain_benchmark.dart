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
        // Родитель держит всю цепочку; ребёнок переопределяет только
        // последнее звено. Так резолв проходит через границу scope, а не
        // остаётся внутри полной копии графа — раньше ребёнок регистрировал
        // копию всей цепочки, и override повторял chainSingleton.
        _childDi = _di.openSubScope('child');
        _childDi!.setupDependencies(_childDi!.universalRegistration(
          chainCount: chainCount,
          nestingDepth: nestingDepth,
          bindingMode: UniversalBindingMode.singletonStrategy,
          scenario: UniversalScenario.override,
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
  void teardown() {
    // BenchmarkBase требует синхронную сигнатуру. Раннер её не использует —
    // он вызывает teardownAsync, чтобы дождаться освобождения контейнера.
    // Пустое тело оставлено, чтобы наследуемый measure() из benchmark_harness
    // не падал, если его когда-нибудь вызовут.
  }

  /// Освобождает контейнер и ждёт завершения.
  ///
  /// Без ожидания CherryPick.closeRootScope() не успевает обнулить root scope
  /// до следующего setup(), и модули накапливаются в одном scope.
  Future<void> teardownAsync() async {
    await _childDi?.teardown();
    await _di.teardown();
  }

  void prewarm() {
    run();
  }

  /// Резолвит голову [chain]-й цепочки по имени.
  ///
  /// В окне первых резолвов вызывается по одному разу для каждой из
  /// chainCount независимых цепочек: каждая голова резолвится ровно один раз,
  /// поэтому измерение остаётся честным первым резолвом, а шаг таймера
  /// делится на размер окна. Для override голова ищется через границу
  /// дочернего scope к регистрации родителя.
  void runHead(int chain) {
    switch (scenario) {
      case UniversalScenario.chain:
        _di.resolve<UniversalService>(named: '${chain}_$nestingDepth');
        break;
      case UniversalScenario.named:
        // У named цепочек нет: головой служит сам именованный биндинг
        // impl$chain. Каждый биндинг резолвится ровно один раз, поэтому
        // окно остаётся честным первым резолвом именованной фабрики.
        _di.resolve<UniversalService>(named: 'impl$chain');
        break;
      case UniversalScenario.override:
        _childDi!.resolve<UniversalService>(named: '${chain}_$nestingDepth');
        break;
      default:
        throw UnsupportedError(
            'Окно первых резолвов применимо только к цепочечным и named-сценариям, '
            'получен $scenario');
    }
  }

  @override
  void run() {
    switch (scenario) {
      case UniversalScenario.register:
        _di.resolve<UniversalService>();
        break;
      case UniversalScenario.named:
        // Steady-цель named — последняя из chainCount именованных фабрик
        // (по конвенции цепочки резолвится голова с наибольшим индексом).
        // Фабрика строит новый экземпляр на каждый вызов, кеша нет.
        _di.resolve<UniversalService>(named: 'impl$chainCount');
        break;
      case UniversalScenario.chain:
        final serviceName = '${chainCount}_$nestingDepth';
        _di.resolve<UniversalService>(named: serviceName);
        break;
      case UniversalScenario.override:
        _childDi!.resolve<UniversalService>();
        break;
      case UniversalScenario.asyncChain:
        throw UnsupportedError(
            'asyncChain supported only in UniversalChainAsyncBenchmark');
    }
  }
}
