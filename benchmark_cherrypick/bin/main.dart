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

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('benchmark', abbr: 'b', help: 'One of: registerSingleton, chainSingleton, chainFactory, chainAsync, named, override, all', defaultsTo: 'chainSingleton')
    ..addOption('chainCount', abbr: 'c', help: 'Comma-separated chainCounts', defaultsTo: '10')
    ..addOption('nestingDepth', abbr: 'd', help: 'Comma-separated depths', defaultsTo: '5')
    ..addOption('repeat', abbr: 'r', help: 'Repeats for each run (>=2)', defaultsTo: '2')
    ..addOption('warmup', abbr: 'w', help: 'Warmup runs', defaultsTo: '1')
    ..addOption('format', abbr: 'f', help: 'Output format (pretty, csv, json)', defaultsTo: 'pretty')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');

  final result = parser.parse(args);

  if (result['help'] == true) {
    print('UniversalChainBenchmark');
    print(parser.usage);
    print('Example:');
    print('  dart run bin/main.dart --benchmark=chainFactory --chainCount=10 --nestingDepth=5 --format=csv');
    return;
  }

  final benchName   = result['benchmark'] as String;
  final isAll = benchName == 'all';
  final List<UniversalBenchmark> allBenches = [
    UniversalBenchmark.registerSingleton,
    UniversalBenchmark.chainSingleton,
    UniversalBenchmark.chainFactory,
    UniversalBenchmark.chainAsync,
    UniversalBenchmark.named,
    UniversalBenchmark.override,
  ];

  final List<UniversalBenchmark> benchesToRun = isAll
    ? allBenches
    : [
        UniversalBenchmark.values.firstWhere(
          (b) => b.toString().split('.').last == benchName,
          orElse: () => UniversalBenchmark.chainSingleton,
        ),
      ];

  final chainCounts = _parseIntList(result['chainCount'] as String);
  final nestDepths  = _parseIntList(result['nestingDepth'] as String);
  final repeats     = int.tryParse(result['repeat'] as String? ?? "") ?? 2;
  final warmups     = int.tryParse(result['warmup'] as String? ?? "") ?? 1;
  final format      = result['format'] as String;

  final results = <Map<String, dynamic>>[];

  for (final bench in benchesToRun) {
    final scenario = _toScenario(bench);
    final mode     = _toMode(bench);
    for (final c in chainCounts) {
      for (final d in nestDepths) {
        // --- asyncChain special case ---
        if (scenario == UniversalScenario.asyncChain) {
          final di = CherrypickDIAdapter();
          final benchAsync = UniversalChainAsyncBenchmark(
            di,
            chainCount: c,
            nestingDepth: d,
            mode: mode,
          );
          final timings = <num>[];
          final rssValues = <int>[];
          // Warmup
          for (int i = 0; i < warmups; i++) {
            await benchAsync.setup();
            await benchAsync.run();
            await benchAsync.teardown();
          }
          final memBefore = ProcessInfo.currentRss;
          for (int i = 0; i < repeats; i++) {
            await benchAsync.setup();
            final sw = Stopwatch()..start();
            await benchAsync.run();
            sw.stop();
            timings.add(sw.elapsedMicroseconds);
            rssValues.add(ProcessInfo.currentRss);
            await benchAsync.teardown();
          }
          final memAfter = ProcessInfo.currentRss;
          final memDiffKB = ((memAfter - memBefore) / 1024).round();
          final peakRss = [...rssValues, memBefore].reduce(max);
          final deltaPeakKb = ((peakRss - memBefore) / 1024).round();
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
            'memory_diff_kb': memDiffKB,
            'delta_peak_kb': deltaPeakKb,
            'peak_rss_kb': (peakRss / 1024).round(),
          });
          continue;
        }
        // --- Sync-case ---
        final di = CherrypickDIAdapter();
        final benchSync = UniversalChainBenchmark(
          di,
          chainCount: c,
          nestingDepth: d,
          mode: mode,
          scenario: scenario,
        );
        final timings = <num>[];
        final rssValues = <int>[];
        // Warmup
        for (int i = 0; i < warmups; i++) {
          benchSync.setup();
          benchSync.run();
          benchSync.teardown();
        }
        final memBefore = ProcessInfo.currentRss;
        for (int i = 0; i < repeats; i++) {
          benchSync.setup();
          final sw = Stopwatch()..start();
          benchSync.run();
          sw.stop();
          timings.add(sw.elapsedMicroseconds);
          rssValues.add(ProcessInfo.currentRss);
          benchSync.teardown();
        }
        final memAfter = ProcessInfo.currentRss;
        final memDiffKB = ((memAfter - memBefore) / 1024).round();
        final peakRss = [...rssValues, memBefore].reduce(max);
        final deltaPeakKb = ((peakRss - memBefore) / 1024).round();
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
          'memory_diff_kb': memDiffKB,
          'delta_peak_kb': deltaPeakKb,
          'peak_rss_kb': (peakRss / 1024).round(),
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
