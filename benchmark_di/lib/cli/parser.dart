import 'dart:io';

import 'package:args/args.dart';
import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';

/// Enum describing all supported Universal DI benchmark types.
enum UniversalBenchmark {
  /// Simple singleton registration benchmark (eager, where supported)
  registerSingleton,

  /// Simple lazy singleton registration benchmark
  registerLazySingleton,

  /// Chain of eager singleton dependencies
  chainSingleton,

  /// Chain of lazy singleton dependencies
  chainLazySingleton,

  /// Chain using factories
  chainFactory,

  /// Async chain resolution
  chainAsync,

  /// Named registration benchmark
  named,

  /// Override/child-scope benchmark
  override,
}

enum ResolvePhase {
  firstResolve,
  steadyStateResolve,
}

/// Maps [UniversalBenchmark] to the scenario enum for DI chains.
UniversalScenario toScenario(UniversalBenchmark b) {
  switch (b) {
    case UniversalBenchmark.registerSingleton:
    case UniversalBenchmark.registerLazySingleton:
      return UniversalScenario.register;
    case UniversalBenchmark.chainSingleton:
    case UniversalBenchmark.chainLazySingleton:
      return UniversalScenario.chain;
    case UniversalBenchmark.chainFactory:
      return UniversalScenario.chain;
    case UniversalBenchmark.chainAsync:
      return UniversalScenario.asyncChain;
    case UniversalBenchmark.named:
      return UniversalScenario.named;
    case UniversalBenchmark.override:
      return UniversalScenario.override;
  }
}

/// Maps benchmark to registration mode (singleton/lazySingleton/factory/async).
UniversalBindingMode toMode(UniversalBenchmark b) {
  switch (b) {
    case UniversalBenchmark.registerSingleton:
    case UniversalBenchmark.chainSingleton:
    case UniversalBenchmark.named:
    case UniversalBenchmark.override:
      return UniversalBindingMode.singletonStrategy;
    case UniversalBenchmark.registerLazySingleton:
    case UniversalBenchmark.chainLazySingleton:
      return UniversalBindingMode.lazySingletonStrategy;
    case UniversalBenchmark.chainFactory:
      return UniversalBindingMode.factoryStrategy;
    case UniversalBenchmark.chainAsync:
      return UniversalBindingMode.asyncStrategy;
  }
}

/// Ошибка конфигурации командной строки. Бросается вместо тихого возврата
/// пустого списка — пустая матрица означала бы отчёт без единого замера.
class BenchmarkCliException implements Exception {
  final String message;
  BenchmarkCliException(this.message);
  @override
  String toString() => 'BenchmarkCliException: $message';
}

/// Строго разбирает значение перечисления [T]. Без fallback: подмена опечатки
/// на chainSingleton давала бы отчёт с чужими числами под чужим именем.
T parseEnumStrict<T>(String value, List<T> values, String optionName) {
  for (final v in values) {
    if (v.toString().split('.').last.toLowerCase() == value.toLowerCase()) {
      return v;
    }
  }
  final known = values.map((v) => v.toString().split('.').last).join(', ');
  throw BenchmarkCliException(
      'Опция --$optionName: неизвестное значение "$value". Допустимые: $known.');
}

/// Разбирает список положительных целых из [s]. Любой невалидный элемент —
/// ошибка: "-c=100" приходит сюда как "=100", и молчаливый пропуск такого
/// значения оставлял бы пользователя с пустой таблицей и кодом возврата 0.
List<int> parseIntList(String s, String optionName) {
  final parts = s.split(',').map((e) => e.trim()).toList();
  final result = <int>[];
  for (final part in parts) {
    final value = int.tryParse(part);
    if (value == null || value <= 0) {
      throw BenchmarkCliException(
          'Опция --$optionName: "$part" не является положительным целым. '
          'Короткие флаги пишутся через пробел: -c 100, а не -c=100.');
    }
    result.add(value);
  }
  if (result.isEmpty) {
    throw BenchmarkCliException('Опция --$optionName не может быть пустой.');
  }
  return result;
}

/// CLI config describing what and how to benchmark.
class BenchmarkCliConfig {
  /// Benchmarks enabled to run (scenarios).
  final List<UniversalBenchmark> benchesToRun;

  /// List of chain counts (parallel, per test).
  final List<int> chainCounts;

  /// List of nesting depths (max chain length, per test).
  final List<int> nestDepths;

  /// How many times to repeat each trial.
  final int repeats;

  /// How many times to warm-up before measuring.
  final int warmups;

  /// Output report format.
  final String format;

  /// Name of DI implementation ("cherrypick" or "getit")
  final String di;

  /// Which resolve phase(s) to measure.
  final List<ResolvePhase> phases;

  BenchmarkCliConfig({
    required this.benchesToRun,
    required this.chainCounts,
    required this.nestDepths,
    required this.repeats,
    required this.warmups,
    required this.format,
    required this.di,
    required this.phases,
  });
}

/// Parses CLI arguments [args] into a [BenchmarkCliConfig].
/// Supports --benchmark, --chainCount, --nestingDepth, etc.
BenchmarkCliConfig parseBenchmarkCli(List<String> args) {
  final parser = ArgParser()
    ..addOption('benchmark', abbr: 'b', defaultsTo: 'chainSingleton')
    ..addOption('chainCount', abbr: 'c', defaultsTo: '10')
    ..addOption('nestingDepth', abbr: 'd', defaultsTo: '5')
    ..addOption('repeat', abbr: 'r', defaultsTo: '2')
    ..addOption('warmup', abbr: 'w', defaultsTo: '1')
    ..addOption('format', abbr: 'f', defaultsTo: 'pretty')
    ..addOption('resolvePhase',
        defaultsTo: 'all', help: 'Resolve phase: first, steady, or all')
    ..addOption('di',
        defaultsTo: 'cherrypick',
        help: 'DI implementation: cherrypick, getit or riverpod')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');
  final result = parser.parse(args);
  if (result['help'] == true) {
    print(parser.usage);
    exit(0);
  }
  final benchNameInput = result['benchmark'] as String;
  final isAll = benchNameInput.trim() == 'all';
  final allBenches = UniversalBenchmark.values;

  String normalizeBenchName(String name) {
    final n = name.trim().toLowerCase();
    return switch (n) {
      'register' ||
      'registersingleton' ||
      'registereager' =>
        'registerSingleton',
      'registerlazy' ||
      'registerlazysingleton' ||
      'registerlazysingle' =>
        'registerLazySingleton',
      'chain' || 'chainsingleton' || 'chaineager' => 'chainSingleton',
      'chainlazy' ||
      'chainlazysingleton' ||
      'lazysingleton' =>
        'chainLazySingleton',
      'chainfactory' || 'factory' => 'chainFactory',
      'async' || 'asyncchain' || 'chainasync' => 'chainAsync',
      'named' => 'named',
      'override' => 'override',
      _ => n,
    };
  }

  const knownDi = {'cherrypick', 'getit', 'riverpod', 'kiwi', 'yx_scope'};
  final di = result['di'] as String? ?? 'cherrypick';
  if (!knownDi.contains(di)) {
    throw BenchmarkCliException(
        'Опция --di: неизвестное значение "$di". Допустимые: ${knownDi.join(', ')}.');
  }

  final benchesToRun = isAll
      ? allBenches
      : benchNameInput
          .split(',')
          .map((n) =>
              parseEnumStrict(normalizeBenchName(n), allBenches, 'benchmark'))
          .toSet()
          .toList();
  final phaseName = (result['resolvePhase'] as String).toLowerCase();
  final phases = switch (phaseName) {
    'first' => [ResolvePhase.firstResolve],
    'steady' => [ResolvePhase.steadyStateResolve],
    _ => ResolvePhase.values,
  };
  return BenchmarkCliConfig(
    benchesToRun: benchesToRun,
    chainCounts: parseIntList(result['chainCount'] as String, 'chainCount'),
    nestDepths: parseIntList(result['nestingDepth'] as String, 'nestingDepth'),
    repeats: int.tryParse(result['repeat'] as String? ?? "") ?? 2,
    warmups: int.tryParse(result['warmup'] as String? ?? "") ?? 1,
    format: result['format'] as String,
    di: di,
    phases: phases,
  );
}
