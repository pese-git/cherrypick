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

  /// Имя цели и имена голов окна, вычисленные один раз в setup().
  /// Интерполяция строки внутри run() добавляла бы в секундомер ~40-50 нс
  /// аллокации, не имеющей отношения к работе контейнера, — как в
  /// синхронном бенчмарке.
  String? _targetName;
  List<String> _headNames = const [];

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
    _targetName = '${chainCount}_$nestingDepth';
    _headNames = [
      for (var chain = 1; chain <= chainCount; chain++) '${chain}_$nestingDepth'
    ];
  }

  Future<void> prewarm() async {
    await di.waitForAsyncReady();
    await run();
  }

  @override
  Future<void> teardown() => teardownAsync();

  /// Освобождает контейнер и ждёт завершения. Одноимённый метод есть и у
  /// синхронного бенчмарка — раннер вызывает его, не различая их.
  Future<void> teardownAsync() async {
    await di.teardown();
  }

  @override
  Future<void> run() async {
    // Async остаётся на named-пути у всех контейнеров: хендловая сигнатура
    // resolveNative синхронна, а отдельный async-хендл (FutureProvider.future
    // у riverpod) закрывал бы лишь ~1% lookup — меньше MAD-шума.
    await di.resolveAsync<UniversalService>(named: _targetName);
  }

  /// Резолвит голову [chain]-й цепочки по имени — окно первых резолвов.
  ///
  /// Каждая из chainCount независимых цепочек резолвится ровно один раз,
  /// поэтому измерение остаётся честным первым резолвом, а шаг таймера
  /// делится на размер окна.
  Future<void> runHeadAsync(int chain) async {
    await di.resolveAsync<UniversalService>(named: _headNames[chain - 1]);
  }
}
