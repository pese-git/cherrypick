import 'package:benchmark_di/di_adapters/di_adapter.dart';
import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';
import 'package:test/test.dart';

import 'support/adapters.dart';

const chainCount = 5;
const nestingDepth = 10;

/// Сколько экземпляров построил контейнер, отвечая на один первый резолв.
///
/// Это и есть объём работы, который сравнивают таблицы отчёта. Если он
/// различается между контейнерами, сравнивать их время нельзя — измеряется
/// разная задача.
Future<int> instancesCreatedOnFirstResolve<T>(
  DIAdapter<T> adapter, {
  required UniversalScenario scenario,
  required UniversalBindingMode mode,
  required bool isAsync,
}) async {
  UniversalServiceImpl.countingEnabled = true;
  UniversalServiceImpl.resetCounter();
  try {
    adapter.setupDependencies(adapter.universalRegistration(
      scenario: scenario,
      chainCount: chainCount,
      nestingDepth: nestingDepth,
      bindingMode: mode,
    ));
    final name = '${chainCount}_$nestingDepth';
    if (isAsync) {
      await adapter.resolveAsync<UniversalService>(named: name);
    } else {
      adapter.resolve<UniversalService>(named: name);
    }
    return UniversalServiceImpl.createdCount;
  } finally {
    UniversalServiceImpl.countingEnabled = false;
    await adapter.teardown();
  }
}

void main() {
  group('первый резолв строит одинаковый граф во всех DI', () {
    for (final name in adapterNames) {
      test('$name / chainLazySingleton: ровно $nestingDepth экземпляров',
          () async {
        final count = await withAdapter(
          name,
          <T>(DIAdapter<T> adapter) => instancesCreatedOnFirstResolve(
            adapter,
            scenario: UniversalScenario.chain,
            mode: UniversalBindingMode.lazySingletonStrategy,
            isAsync: false,
          ),
        );
        expect(count, nestingDepth,
            reason: '$name построил $count экземпляров вместо $nestingDepth — '
                'сценарии не эквивалентны');
      });
    }

    for (final name in asyncCapable) {
      test('$name / asyncChain: ровно $nestingDepth экземпляров', () async {
        final count = await withAdapter(
          name,
          <T>(DIAdapter<T> adapter) => instancesCreatedOnFirstResolve(
            adapter,
            scenario: UniversalScenario.asyncChain,
            mode: UniversalBindingMode.asyncStrategy,
            isAsync: true,
          ),
        );
        expect(count, nestingDepth,
            reason: '$name построил $count экземпляров вместо $nestingDepth — '
                'сравнение времени между DI недействительно');
      });
    }
  });
}
