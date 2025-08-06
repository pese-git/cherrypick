import 'dart:io';

import 'package:args/args.dart';
import 'package:benchmark_cherrypick/scenarios/universal_chain_module.dart';

enum UniversalBenchmark {
  registerSingleton,
  chainSingleton,
  chainFactory,
  chainAsync,
  named,
  override,
}

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

T parseEnum<T>(String value, List<T> values, T defaultValue) {
  return values.firstWhere(
    (v) => v.toString().split('.').last.toLowerCase() == value.toLowerCase(),
    orElse: () => defaultValue,
  );
}

List<int> parseIntList(String s) =>
    s.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((x) => x > 0).toList();

class BenchmarkCliConfig {
  final List<UniversalBenchmark> benchesToRun;
  final List<int> chainCounts;
  final List<int> nestDepths;
  final int repeats;
  final int warmups;
  final String format;
  BenchmarkCliConfig({
    required this.benchesToRun,
    required this.chainCounts,
    required this.nestDepths,
    required this.repeats,
    required this.warmups,
    required this.format,
  });
}

BenchmarkCliConfig parseBenchmarkCli(List<String> args) {
  final parser = ArgParser()
    ..addOption('benchmark', abbr: 'b', defaultsTo: 'chainSingleton')
    ..addOption('chainCount', abbr: 'c', defaultsTo: '10')
    ..addOption('nestingDepth', abbr: 'd', defaultsTo: '5')
    ..addOption('repeat', abbr: 'r', defaultsTo: '2')
    ..addOption('warmup', abbr: 'w', defaultsTo: '1')
    ..addOption('format', abbr: 'f', defaultsTo: 'pretty')
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
  );
}