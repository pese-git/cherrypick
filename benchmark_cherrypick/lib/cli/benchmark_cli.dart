import 'dart:math';

import '../scenarios/universal_chain_module.dart';
import 'report/pretty_report.dart';
import 'report/csv_report.dart';
import 'report/json_report.dart';
import 'parser.dart';
import 'runner.dart';
import 'package:benchmark_cherrypick/benchmarks/universal_chain_benchmark.dart';
import 'package:benchmark_cherrypick/benchmarks/universal_chain_async_benchmark.dart';
import 'package:benchmark_cherrypick/di_adapters/cherrypick_adapter.dart';

class BenchmarkCliRunner {
  Future<void> run(List<String> args) async {
    final config = parseBenchmarkCli(args);
    final results = <Map<String, dynamic>>[];
    for (final bench in config.benchesToRun) {
      final scenario = toScenario(bench);
      final mode = toMode(bench);
      for (final c in config.chainCounts) {
        for (final d in config.nestDepths) {
          BenchmarkResult benchResult;
          if (scenario == UniversalScenario.asyncChain) {
            final di = CherrypickDIAdapter();
            final benchAsync = UniversalChainAsyncBenchmark(di,
              chainCount: c, nestingDepth: d, mode: mode,
            );
            benchResult = await BenchmarkRunner.runAsync(
              benchmark: benchAsync,
              warmups: config.warmups,
              repeats: config.repeats,
            );
          } else {
            final di = CherrypickDIAdapter();
            final benchSync = UniversalChainBenchmark(di,
              chainCount: c, nestingDepth: d, mode: mode, scenario: scenario,
            );
            benchResult = await BenchmarkRunner.runSync(
              benchmark: benchSync,
              warmups: config.warmups,
              repeats: config.repeats,
            );
          }
          final timings = benchResult.timings;
          timings.sort();
          var mean = timings.reduce((a, b) => a + b) / timings.length;
          var median = timings[timings.length ~/ 2];
          var minVal = timings.first;
          var maxVal = timings.last;
          var stddev = timings.isEmpty ? 0 : sqrt(timings.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / timings.length);
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
    final reportGenerators = {
      'pretty': PrettyReport(),
      'csv': CsvReport(),
      'json': JsonReport(),
    };
    print(reportGenerators[config.format]?.render(results) ?? PrettyReport().render(results));
  }
}