import 'package:benchmark_cherrypick/benchmarks/universal_chain_benchmark.dart';
import 'package:benchmark_cherrypick/di_adapters/cherrypick_adapter.dart';
import 'package:benchmark_cherrypick/scenarios/universal_chain_module.dart';
import 'package:args/args.dart';
import 'dart:io';
import 'dart:math';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('chainCount', abbr: 'c', help: 'Comma-separated chainCounts', defaultsTo: '10')
    ..addOption('nestingDepth', abbr: 'd', help: 'Comma-separated depths', defaultsTo: '5')
    ..addOption('mode', abbr: 'm', help: 'Mode (singletonStrategy,factoryStrategy,asyncStrategy)', defaultsTo: 'singletonStrategy')
    ..addOption('repeat', abbr: 'r', help: 'Repeats for each run (>=2)', defaultsTo: '2')
    ..addOption('warmup', abbr: 'w', help: 'Warmup runs', defaultsTo: '1')
    ..addOption('format', abbr: 'f', help: 'Output format (pretty, csv, json)', defaultsTo: 'pretty')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');

  final result = parser.parse(args);

  if (result['help'] == true) {
    print('UniversalChainBenchmark');
    print(parser.usage);
    return;
  }

  final chainCounts = _parseIntList(result['chainCount'] as String);
  final nestDepths  = _parseIntList(result['nestingDepth'] as String);
  final modeName    = result['mode'] as String;
  final mode        = UniversalBindingMode.values.firstWhere(
    (m) => m.toString().split('.').last == modeName,
    orElse: () => UniversalBindingMode.singletonStrategy,
  );
  final repeats     = int.tryParse(result['repeat'] as String? ?? "") ?? 2;
  final warmups     = int.tryParse(result['warmup'] as String? ?? "") ?? 1;
  final format      = result['format'] as String;

  final di = CherrypickDIAdapter();
  final results = <Map<String, dynamic>>[];

  void addResult(
    String name,
    int chainCount,
    int nestingDepth,
    List<num> timings,
    int? memoryDiffKb,
    int? deltaPeakKb,
    int? peakRssKb,
  ) {
    timings.sort();
    var mean = timings.reduce((a, b) => a + b) / timings.length;
    var median = timings[timings.length ~/ 2];
    var minVal = timings.first;
    var maxVal = timings.last;
    var stddev = sqrt(timings.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / timings.length);
    results.add({
      'benchmark': name,
      'chainCount': chainCount,
      'nestingDepth': nestingDepth,
      'mean_us': mean.round(),
      'median_us': median.round(),
      'stddev_us': stddev.round(),
      'min_us': minVal.round(),
      'max_us': maxVal.round(),
      'trials': timings.length,
      'timings_us': timings.map((t) => t.round()).toList(),
      'memory_diff_kb': memoryDiffKb,
      'delta_peak_kb': deltaPeakKb,
      'peak_rss_kb': peakRssKb,
    });
  }

  Future<void> runAndCollect(
    String name,
    Future<num> Function() fn, {
    required int chainCount,
    required int nestingDepth,
  }) async {
    for (int i = 0; i < warmups; i++) {
      await fn();
    }
    final timings = <num>[];
    final rssValues = <int>[];
    final memBefore = ProcessInfo.currentRss;
    for (int i = 0; i < repeats; i++) {
      timings.add(await fn());
      rssValues.add(ProcessInfo.currentRss);
    }
    final memAfter = ProcessInfo.currentRss;
    final memDiffKB = ((memAfter - memBefore) / 1024).round();
    final peakRss = [...rssValues, memBefore].reduce(max);
    final deltaPeakKb = ((peakRss - memBefore) / 1024).round();
    addResult(name, chainCount, nestingDepth, timings, memDiffKB, deltaPeakKb, (peakRss/1024).round());
  }

  for (final c in chainCounts) {
    for (final d in nestDepths) {
      await runAndCollect('UniversalChain_$mode', () async {
        return _captureReport(() => UniversalChainBenchmark(
          di,
          chainCount: c,
          nestingDepth: d,
          mode: mode,
        ).report());
      }, chainCount: c, nestingDepth: d);
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

Future<num> _captureReport(void Function() fn) async {
  final sw = Stopwatch()..start();
  fn();
  sw.stop();
  return sw.elapsedMicroseconds;
}

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
