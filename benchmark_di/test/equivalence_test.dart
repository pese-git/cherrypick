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

/// Сколько экземпляров построил контейнер **на самом окне**.
///
/// Счётчик включается и сбрасывается после setup(): eager-граф строится при
/// регистрации — это подготовка вне секундомера, как и во всех фазах
/// раннера. Окно обязано строить одинаковое число экземпляров у всех
/// контейнеров, иначе сравнивать его время нельзя.
Future<int> instancesCreatedOnResolveWindow<T>(
  DIAdapter<T> adapter, {
  required UniversalBindingMode mode,
}) async {
  adapter.setupDependencies(adapter.universalRegistration(
    scenario: UniversalScenario.chain,
    chainCount: chainCount,
    nestingDepth: nestingDepth,
    bindingMode: mode,
  ));
  UniversalServiceImpl.countingEnabled = true;
  UniversalServiceImpl.resetCounter();
  try {
    for (int chain = 1; chain <= chainCount; chain++) {
      adapter.resolve<UniversalService>(named: '${chain}_$nestingDepth');
    }
    return UniversalServiceImpl.createdCount;
  } finally {
    UniversalServiceImpl.countingEnabled = false;
    await adapter.teardown();
  }
}

/// Сколько экземпляров построил контейнер **на named-окне**.
///
/// Как [instancesCreatedOnResolveWindow], но для сценария named: головой
/// служит сам именованный биндинг impl$chain. named-биндинги — фабрики у
/// всех контейнеров, поэтому окно строит по экземпляру на голову у всех —
/// как lazy/factory-режимы цепочки.
Future<int> instancesCreatedOnNamedWindow<T>(
  DIAdapter<T> adapter,
) async {
  adapter.setupDependencies(adapter.universalRegistration(
    scenario: UniversalScenario.named,
    chainCount: chainCount,
    nestingDepth: nestingDepth,
    bindingMode: UniversalBindingMode.factoryStrategy,
  ));
  UniversalServiceImpl.countingEnabled = true;
  UniversalServiceImpl.resetCounter();
  try {
    for (int chain = 1; chain <= chainCount; chain++) {
      adapter.resolve<UniversalService>(named: 'impl$chain');
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

  group('окно первых резолвов строит одинаковый граф во всех DI', () {
    // Контейнеры делятся на две группы по месту построения графа при
    // singletonStrategy, и обе группы честны для окна, пока объём работы
    // согласован внутри группы:
    // - cherrypick и get_it строят eager-граф при регистрации (в setup, вне
    //   секундомера) — на окне ноль построений, чистое чтение кеша;
    // - kiwi, riverpod и yx_scope ленивы по природе: их singleton строится
    //   при первом резолве (это задокументировано в kiwi_adapter), поэтому
    //   на окне они строят chainCount × nestingDepth — столько же, сколько
    //   lazy- и factory-режимы у всех контейнеров.
    // Ожидание задаётся для каждого контейнера по его группе.
    final eager = {'cherrypick', 'getit'};
    for (final entry in {
      'singletonStrategy': true,
      'lazySingletonStrategy': false,
      'factoryStrategy': false,
    }.entries) {
      final mode = switch (entry.key) {
        'singletonStrategy' => UniversalBindingMode.singletonStrategy,
        'lazySingletonStrategy' => UniversalBindingMode.lazySingletonStrategy,
        _ => UniversalBindingMode.factoryStrategy,
      };
      for (final name in adapterNames) {
        final expected = entry.value && !eager.contains(name)
            ? chainCount * nestingDepth
            : entry.value
                ? 0
                : chainCount * nestingDepth;
        test(
            '$name / ${entry.key}: ровно $expected экземпляров на окно '
            'из $chainCount голов', () async {
          final count = await withAdapter(
            name,
            <T>(DIAdapter<T> adapter) =>
                instancesCreatedOnResolveWindow(adapter, mode: mode),
          );
          expect(count, expected,
              reason: '$name построил $count экземпляров вместо '
                  '$expected — окно измеряет разный объём работы');
        });
      }
    }
  });

  group('named-окно первых резолвов строит одинаковый граф во всех DI', () {
    // named-биндинги — фабрики у всех контейнеров (задокументировано в
    // адаптерах), поэтому на окне каждый контейнер строит ровно по
    // экземпляру на голову, как lazy/factory-режимы цепочки. Eager-группа
    // здесь ничем не отличается: eager-регистрации у named нет.
    for (final name in adapterNames) {
      test(
          '$name / named: ровно $chainCount экземпляров на окно '
          'из $chainCount голов', () async {
        final count = await withAdapter(
          name,
          <T>(DIAdapter<T> adapter) => instancesCreatedOnNamedWindow(adapter),
        );
        expect(count, chainCount,
            reason: '$name построил $count экземпляров вместо $chainCount — '
                'named-окно измеряет разный объём работы');
      });
    }
  });
}
