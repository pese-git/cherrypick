import 'package:benchmark_di/benchmarks/universal_chain_benchmark.dart';
import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';
import 'package:test/test.dart';

import 'support/adapters.dart';

const chainCount = 5;
const nestingDepth = 10;

/// Сколько экземпляров строит один вызов [UniversalChainBenchmark.run] после
/// очередного setup() бенчмарка.
Future<int> instancesCreatedOnMeasuredRun<T>(
  dynamic adapter,
  UniversalScenario scenario,
) async {
  final benchmark = UniversalChainBenchmark<T>(
    adapter,
    chainCount: chainCount,
    nestingDepth: nestingDepth,
    mode: UniversalBindingMode.lazySingletonStrategy,
    scenario: scenario,
  );
  try {
    // Два setup(): первый — прогревочный, второй имитирует итерацию замера.
    // Контейнер между ними освобождается, как это делает раннер.
    benchmark.setup();
    await benchmark.teardownAsync();
    benchmark.setup();
    UniversalServiceImpl.countingEnabled = true;
    UniversalServiceImpl.resetCounter();
    try {
      benchmark.run();
      return UniversalServiceImpl.createdCount;
    } finally {
      UniversalServiceImpl.countingEnabled = false;
    }
  } finally {
    await benchmark.teardownAsync();
  }
}

void main() {
  // Страховка «хендл резолвит тот же биндинг, что named» в
  // _prepareAccessors однажды резолвила target-биндинг при каждом setup() —
  // до включения таймера. Измеряемый «первый резолв» после этого читал кеш,
  // построенный валидацией: для register это 0 построений вместо одного,
  // для ленивой цепочки — 0 вместо nestingDepth. Сверка обязана выполняться
  // один раз на прогреве и по голове, не являющейся целью.
  group('подготовка доступа не резолвит измеряемую цель', () {
    for (final name in adapterNames) {
      test('$name / register: первый run() строит ровно 1 экземпляр', () async {
        final count = await withAdapter(
          name,
          <T>(adapter) => instancesCreatedOnMeasuredRun<T>(
              adapter, UniversalScenario.register),
        );
        expect(count, 1,
            reason: '$name: цель построена до секундомера — измеряемый '
                'первый резолв читает кеш валидации');
      });

      test(
          '$name / chainLazySingleton: первый run() строит ровно '
          '$nestingDepth экземпляров', () async {
        final count = await withAdapter(
          name,
          <T>(adapter) => instancesCreatedOnMeasuredRun<T>(
              adapter, UniversalScenario.chain),
        );
        expect(count, nestingDepth,
            reason: '$name: цепочка цели построена до секундомера — '
                'измеряемый первый резолв читает кеш валидации');
      });
    }
  });
}
