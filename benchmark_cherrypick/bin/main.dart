import 'package:benchmark_cherrypick/cherrypick_benchmark.dart';
import 'package:benchmark_cherrypick/complex_bindings_benchmark.dart';
import 'package:benchmark_cherrypick/async_chain_benchmark.dart';
import 'package:benchmark_cherrypick/scope_override_benchmark.dart';
import 'package:args/args.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('benchmark', abbr: 'b', help: 'Benchmark name (register, chain_singleton, chain_factory, named, override, async_chain, all)', defaultsTo: 'all')
    ..addOption('chainCount', abbr: 'c', help: 'Comma-separated chainCounts (используется в chain_singleton/factory)', defaultsTo: '100')
    ..addOption('nestingDepth', abbr: 'd', help: 'Comma-separated depths (используется в chain_singleton/factory)', defaultsTo: '100')
    ..addOption('format', abbr: 'f', help: 'Output format (pretty, csv, json)', defaultsTo: 'pretty')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');

  final result = parser.parse(args);

  if (result['help'] == true) {
    print('Dart DI benchmarks');
    print(parser.usage);
    return;
  }

  final benchmark = result['benchmark'] as String;
  final format = result['format'] as String;

  final chainCounts = _parseIntList(result['chainCount'] as String);
  final nestDepths  = _parseIntList(result['nestingDepth'] as String);

  final results = <Map<String, dynamic>>[];
  void addResult(String name, int? chainCount, int? nestingDepth, num elapsed) {
    results.add({
      'benchmark': name,
      'chainCount': chainCount,
      'nestingDepth': nestingDepth,
      'elapsed_us': elapsed.round()
    });
  }

  Future<void> runAndCollect(String name, Future<num> Function() fn, {int? chainCount, int? nestingDepth}) async {
    final elapsed = await fn();
    addResult(name, chainCount, nestingDepth, elapsed);
  }

  if (benchmark == 'all' || benchmark == 'register') {
    await runAndCollect('RegisterAndResolve', () async {
      return _captureReport(RegisterAndResolveBenchmark().report);
    });
  }
  if (benchmark == 'all' || benchmark == 'chain_singleton') {
    for (final c in chainCounts) { 
      for (final d in nestDepths) {
        await runAndCollect('ChainSingleton', () async {
          return _captureReport(() => ChainSingletonBenchmark(chainCount: c, nestingDepth: d).report());
        }, chainCount: c, nestingDepth: d);
      }
    }
  }
  if (benchmark == 'all' || benchmark == 'chain_factory') {
    for (final c in chainCounts) { 
      for (final d in nestDepths) {
        await runAndCollect('ChainFactory', () async {
          return _captureReport(() => ChainFactoryBenchmark(chainCount: c, nestingDepth: d).report());
        }, chainCount: c, nestingDepth: d);
      }
    }
  }
  if (benchmark == 'all' || benchmark == 'named') {
    await runAndCollect('NamedResolve', () async {
      return _captureReport(NamedResolveBenchmark().report);
    });
  }
  if (benchmark == 'all' || benchmark == 'override') {
    await runAndCollect('ScopeOverride', () async {
      return _captureReport(ScopeOverrideBenchmark().report);
    });
  }
  if (benchmark == 'all' || benchmark == 'async_chain') {
    await runAndCollect('AsyncChain', () async {
      return _captureReportAsync(AsyncChainBenchmark().report);
    });
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
Future<num> _captureReportAsync(Future<void> Function() fn) async {
  final sw = Stopwatch()..start();
  await fn();
  sw.stop();
  return sw.elapsedMicroseconds;
}

String _toPretty(List<Map<String, dynamic>> rows) {
  final keys = ['benchmark','chainCount','nestingDepth','elapsed_us'];
  final header = keys.join('\t');
  final lines = rows.map((r) => keys.map((k) => (r[k] ?? '').toString()).join('\t')).toList();
  return ([header] + lines).join('\n');
}

String _toCsv(List<Map<String, dynamic>> rows) {
  final keys = ['benchmark','chainCount','nestingDepth','elapsed_us'];
  final header = keys.join(',');
  final lines = rows.map((r) => keys.map((k) => (r[k] ?? '').toString()).join(',')).toList();
  return ([header] + lines).join('\n');
}

String _toJson(List<Map<String, dynamic>> rows) {
  return '[\n${rows.map((r) => '  $r').join(',\n')}\n]';
}
// --- end helpers ---
