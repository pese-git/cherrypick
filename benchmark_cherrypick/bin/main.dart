import 'package:benchmark_cherrypick/benchmarks/universal_chain_benchmark.dart';
import 'package:benchmark_cherrypick/benchmarks/universal_chain_async_benchmark.dart';
import 'package:benchmark_cherrypick/di_adapters/cherrypick_adapter.dart';
import 'package:benchmark_cherrypick/scenarios/universal_chain_module.dart';
import 'package:args/args.dart';
import 'dart:io';
import 'dart:math';

enum UniversalBenchmark {
  registerSingleton,
  chainSingleton,
  chainFactory,
  chainAsync,
  named,
  override,
}

UniversalScenario _toScenario(UniversalBenchmark b) {
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
UniversalBindingMode _toMode(UniversalBenchmark b) {
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

typedef SyncBench = UniversalChainBenchmark;
typedef AsyncBench = UniversalChainAsyncBenchmark;

class BenchmarkResult {
  final List<num> timings;
  final int memoryDiffKb;
  final int deltaPeakKb;
  final int peakRssKb;
  BenchmarkResult({
    required this.timings,
    required this.memoryDiffKb,
    required this.deltaPeakKb,
    required this.peakRssKb,
  });
  factory BenchmarkResult.collect({
    required List<num> timings,
    required List<int> rssValues,
    required int memBefore,
  }) {
    final memAfter = ProcessInfo.currentRss;
    final memDiffKB = ((memAfter - memBefore) / 1024).round();
    final peakRss = [...rssValues, memBefore].reduce(max);
    final deltaPeakKb = ((peakRss - memBefore) / 1024).round();
    return BenchmarkResult(
      timings: timings,
      memoryDiffKb: memDiffKB,
      deltaPeakKb: deltaPeakKb,
      peakRssKb: (peakRss / 1024).round(),
    );
  }
}

class BenchmarkRunner {
  static Future<BenchmarkResult> runSync({
    required SyncBench benchmark,
    required int warmups,
    required int repeats,
  }) async {
    final timings = <num>[];
    final rssValues = <int>[];
    for (int i = 0; i < warmups; i++) {
      benchmark.setup();
      benchmark.run();
      benchmark.teardown();
    }
    final memBefore = ProcessInfo.currentRss;
    for (int i = 0; i < repeats; i++) {
      benchmark.setup();
      final sw = Stopwatch()..start();
      benchmark.run();
      sw.stop();
      timings.add(sw.elapsedMicroseconds);
      rssValues.add(ProcessInfo.currentRss);
      benchmark.teardown();
    }
    return BenchmarkResult.collect(
      timings: timings,
      rssValues: rssValues,
      memBefore: memBefore,
    );
  }
  static Future<BenchmarkResult> runAsync({
    required AsyncBench benchmark,
    required int warmups,
    required int repeats,
  }) async {
    final timings = <num>[];
    final rssValues = <int>[];
    for (int i = 0; i < warmups; i++) {
      await benchmark.setup();
      await benchmark.run();
      await benchmark.teardown();
    }
    final memBefore = ProcessInfo.currentRss;
    for (int i = 0; i < repeats; i++) {
      await benchmark.setup();
      final sw = Stopwatch()..start();
      await benchmark.run();
      sw.stop();
      timings.add(sw.elapsedMicroseconds);
      rssValues.add(ProcessInfo.currentRss);
      await benchmark.teardown();
    }
    return BenchmarkResult.collect(
      timings: timings,
      rssValues: rssValues,
      memBefore: memBefore,
    );
  }
}

T parseEnum<T>(String value, List<T> values, T defaultValue) {
  return values.firstWhere(
    (v) => v.toString().split('.').last.toLowerCase() == value.toLowerCase(),
    orElse: () => defaultValue,
  );
}

Future<void> main(List<String> args) async {
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
    print('UniversalChainBenchmark');
    print(parser.usage);
    print('Example:');
    print('  dart run bin/main.dart --benchmark=chainFactory --chainCount=10 --nestingDepth=5 --format=csv');
    return;
  }
  final benchName = result['benchmark'] as String;
  final isAll = benchName == 'all';
  final List<UniversalBenchmark> allBenches = UniversalBenchmark.values;
  final List<UniversalBenchmark> benchesToRun = isAll
    ? allBenches
    : [parseEnum(benchName, UniversalBenchmark.values, UniversalBenchmark.chainSingleton)];
  final chainCounts = _parseIntList(result['chainCount'] as String);
  final nestDepths = _parseIntList(result['nestingDepth'] as String);
  final repeats = int.tryParse(result['repeat'] as String? ?? "") ?? 2;
  final warmups = int.tryParse(result['warmup'] as String? ?? "") ?? 1;
  final format = result['format'] as String;

  final results = <Map<String, dynamic>>[];
  for (final bench in benchesToRun) {
    final scenario = _toScenario(bench);
    final mode = _toMode(bench);
    for (final c in chainCounts) {
      for (final d in nestDepths) {
        BenchmarkResult benchResult;
        if (scenario == UniversalScenario.asyncChain) {
          final di = CherrypickDIAdapter();
          final benchAsync = UniversalChainAsyncBenchmark(
            di,
            chainCount: c,
            nestingDepth: d,
            mode: mode,
          );
          benchResult = await BenchmarkRunner.runAsync(
            benchmark: benchAsync,
            warmups: warmups,
            repeats: repeats,
          );
        } else {
          final di = CherrypickDIAdapter();
          final benchSync = UniversalChainBenchmark(
            di,
            chainCount: c,
            nestingDepth: d,
            mode: mode,
            scenario: scenario,
          );
          benchResult = await BenchmarkRunner.runSync(
            benchmark: benchSync,
            warmups: warmups,
            repeats: repeats,
          );
        }
        final timings = benchResult.timings;
        timings.sort();
        var mean = timings.reduce((a, b) => a + b) / timings.length;
        var median = timings[timings.length ~/ 2];
        var minVal = timings.first;
        var maxVal = timings.last;
        var stddev = sqrt(timings.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / timings.length);
        results.add({
          'benchmark': 'Universal_$bench',
          'chainCount': c,
          'nestingDepth': d,
          'mean_us': mean.round(),
          'median_us': median.round(),
          'stddev_us': stddev.round(),
          'min_us': minVal.round(),
          'max_us': maxVal.round(),
          'trials': timings.length,
          'timings_us': timings.map((t) => t.round()).toList(),
          'memory_diff_kb': benchResult.memoryDiffKb,
          'delta_peak_kb': benchResult.deltaPeakKb,
          'peak_rss_kb': benchResult.peakRssKb,
        });
      }
    }
  }
  if (format == 'json') {
    print(_toJson(results));
  } else if (format == 'csv') {
    print(_toCsv(results));
  } else {
    print(_toPretty(results));
  }
}

// --- helpers ---
List<int> _parseIntList(String s) => s.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((x) => x > 0).toList();
String _toPretty(List<Map<String, dynamic>> rows) {
  final keys = [
    'benchmark','chainCount','nestingDepth','mean_us','median_us','stddev_us',
    'min_us','max_us','trials','memory_diff_kb','delta_peak_kb','peak_rss_kb'
  ];
  final header = keys.join('\t');
  final lines = rows.map((r) => keys.map((k) => (r[k] ?? '').toString()).join('\t')).toList();
  return ([header] + lines).join('\n');
}
String _toCsv(List<Map<String, dynamic>> rows) {
  final keys = [
    'benchmark','chainCount','nestingDepth','mean_us','median_us','stddev_us',
    'min_us','max_us','trials','timings_us','memory_diff_kb','delta_peak_kb','peak_rss_kb'
  ];
  final header = keys.join(',');
  final lines = rows.map((r) =>
    keys.map((k) {
      final v = r[k];
      if (v is List) return '"${v.join(';')}"';
      return (v ?? '').toString();
    }).join(',')
  ).toList();
  return ([header] + lines).join('\n');
}
String _toJson(List<Map<String, dynamic>> rows) {
  return '[\n${rows.map((r) => '  $r').join(',\n')}\n]';
}
// --- end helpers ---
