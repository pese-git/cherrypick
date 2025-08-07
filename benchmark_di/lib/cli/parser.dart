import 'dart:io';

import 'package:args/args.dart';
import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';

/// Enum describing all supported Universal DI benchmark types.
enum UniversalBenchmark {
  /// Simple singleton registration benchmark
  registerSingleton,
  /// Chain of singleton dependencies
  chainSingleton,
  /// Chain using factories
  chainFactory,
  /// Async chain resolution
  chainAsync,
  /// Named registration benchmark
  named,
  /// Override/child-scope benchmark
  override,
}

/// Maps [UniversalBenchmark] to the scenario enum for DI chains.
UniversalScenario toScenario(UniversalBenchmark b) {
  switch (b) {
    case UniversalBenchmark.registerSingleton:
      return UniversalScenario.register;
    case UniversalBenchmark.chainSingleton:
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

/// Maps benchmark to registration mode (singleton/factory/async).
UniversalBindingMode toMode(UniversalBenchmark b) {
  switch (b) {
    case UniversalBenchmark.registerSingleton:
      return UniversalBindingMode.singletonStrategy;
    case UniversalBenchmark.chainSingleton:
      return UniversalBindingMode.singletonStrategy;
    case UniversalBenchmark.chainFactory:
      return UniversalBindingMode.factoryStrategy;
    case UniversalBenchmark.chainAsync:
      return UniversalBindingMode.asyncStrategy;
    case UniversalBenchmark.named:
      return UniversalBindingMode.singletonStrategy;
    case UniversalBenchmark.override:
      return UniversalBindingMode.singletonStrategy;
  }
}

/// Utility to parse a string into its corresponding enum value [T].
T parseEnum<T>(String value, List<T> values, T defaultValue) {
  return values.firstWhere(
    (v) => v.toString().split('.').last.toLowerCase() == value.toLowerCase(),
    orElse: () => defaultValue,
  );
}

/// Parses comma-separated integer list from [s].
List<int> parseIntList(String s) =>
    s.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((x) => x > 0).toList();

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
  BenchmarkCliConfig({
    required this.benchesToRun,
    required this.chainCounts,
    required this.nestDepths,
    required this.repeats,
    required this.warmups,
    required this.format,
    required this.di,
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
    ..addOption('di', defaultsTo: 'cherrypick', help: 'DI implementation: cherrypick, getit or riverpod')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');
  final result = parser.parse(args);
  if (result['help'] == true) {
    print(parser.usage);
    exit(0);
  }
  final benchName = result['benchmark'] as String;
  final isAll = benchName == 'all';
  final allBenches = UniversalBenchmark.values;
  final benchesToRun = isAll
      ? allBenches
      : [parseEnum(benchName, allBenches, UniversalBenchmark.chainSingleton)];
  return BenchmarkCliConfig(
    benchesToRun: benchesToRun,
    chainCounts: parseIntList(result['chainCount'] as String),
    nestDepths: parseIntList(result['nestingDepth'] as String),
    repeats: int.tryParse(result['repeat'] as String? ?? "") ?? 2,
    warmups: int.tryParse(result['warmup'] as String? ?? "") ?? 1,
    format: result['format'] as String,
    di: result['di'] as String? ?? 'cherrypick',
  );
}