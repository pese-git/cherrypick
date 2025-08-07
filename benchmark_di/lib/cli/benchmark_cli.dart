import 'dart:math';

import 'package:benchmark_di/cli/report/markdown_report.dart';

import '../scenarios/universal_chain_module.dart';
import 'report/pretty_report.dart';
import 'report/csv_report.dart';
import 'report/json_report.dart';
import 'parser.dart';
import 'runner.dart';
import 'package:benchmark_di/benchmarks/universal_chain_benchmark.dart';
import 'package:benchmark_di/benchmarks/universal_chain_async_benchmark.dart';
import 'package:benchmark_di/di_adapters/cherrypick_adapter.dart';
import 'package:benchmark_di/di_adapters/get_it_adapter.dart';
import 'package:benchmark_di/di_adapters/riverpod_adapter.dart';

/// Command-line interface (CLI) runner for benchmarks.
///
/// Parses CLI arguments, orchestrates benchmarks for different
/// scenarios and configurations, collects results, and generates reports
/// in the desired output format.
class BenchmarkCliRunner {
  /// Runs benchmarks based on CLI [args], configuring different test scenarios.
  Future<void> run(List<String> args) async {
    final config = parseBenchmarkCli(args);
    final results = <Map<String, dynamic>>[];
    for (final bench in config.benchesToRun) {
      final scenario = toScenario(bench);
      final mode = toMode(bench);
      for (final c in config.chainCounts) {
        for (final d in config.nestDepths) {
          BenchmarkResult benchResult;
          final di = config.di == 'getit'
              ? GetItAdapter()
              : config.di == 'riverpod'
                  ? RiverpodAdapter()
                  : CherrypickDIAdapter();
          if (scenario == UniversalScenario.asyncChain) {
            final benchAsync = UniversalChainAsyncBenchmark(di,
              chainCount: c, nestingDepth: d, mode: mode,
            );
            benchResult = await BenchmarkRunner.runAsync(
              benchmark: benchAsync,
              warmups: config.warmups,
              repeats: config.repeats,
            );
          } else {
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
            'mean_us': mean.toStringAsFixed(2),
            'median_us': median.toStringAsFixed(2),
            'stddev_us': stddev.toStringAsFixed(2),
            'min_us': minVal.toStringAsFixed(2),
            'max_us': maxVal.toStringAsFixed(2),
            'trials': timings.length,
            'timings_us': timings.map((t) => t.toStringAsFixed(2)).toList(),
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
      'markdown': MarkdownReport(),
    };
    print(reportGenerators[config.format]?.render(results) ?? PrettyReport().render(results));
  }
}