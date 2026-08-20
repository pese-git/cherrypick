import 'dart:io';

import 'package:benchmark_di/cli/report/markdown_report.dart';
import 'package:benchmark_di/di_adapters/yx_scope_adapter.dart';
import 'package:benchmark_di/di_adapters/yx_scope_universal_container.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:cherrypick/cherrypick.dart';
import 'package:get_it/get_it.dart';
import 'package:riverpod/riverpod.dart' as rp;

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
import 'package:benchmark_di/di_adapters/kiwi_adapter.dart';
import 'package:kiwi/kiwi.dart';

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
    // DI implementations that do not support async scenarios
    const asyncUnsupported = {'kiwi', 'yx_scope'};
    for (final phase in config.phases) {
      for (final bench in config.benchesToRun) {
        final scenario = toScenario(bench);
        final mode = toMode(bench);
        // Пропуск неподдерживаемого сценария сообщается в stderr: молчаливая
        // пустая таблица однажды уже привела к публикации числа для сценария,
        // который инструмент выполнить не может (yx_scope/chainAsync = 87.2us).
        if (asyncUnsupported.contains(config.di) &&
            scenario == UniversalScenario.asyncChain) {
          stderr.writeln(
              'пропущено: ${config.di}/$bench — контейнер не поддерживает '
              'асинхронные привязки');
          continue;
        }
        if (hierarchyUnsupported.contains(config.di) &&
            scenario == UniversalScenario.override) {
          stderr.writeln(
              'пропущено: ${config.di}/$bench — контейнер не поддерживает '
              'иерархию scope');
          continue;
        }
        for (final c in config.chainCounts) {
          for (final d in config.nestDepths) {
            BenchmarkResult benchResult;
            if (config.di == 'getit') {
              final di = GetItAdapter();
              if (scenario == UniversalScenario.asyncChain) {
                final benchAsync = UniversalChainAsyncBenchmark<GetIt>(
                  di,
                  chainCount: c,
                  nestingDepth: d,
                  mode: mode,
                );
                benchResult = await BenchmarkRunner.runAsync(
                  benchmark: benchAsync,
                  warmups: config.warmups,
                  repeats: config.repeats,
                  phase: phase,
                  opsPerSample: config.opsPerSample,
                );
              } else {
                final benchSync = UniversalChainBenchmark<GetIt>(
                  di,
                  chainCount: c,
                  nestingDepth: d,
                  mode: mode,
                  scenario: scenario,
                );
                benchResult = await BenchmarkRunner.runSync(
                  benchmark: benchSync,
                  warmups: config.warmups,
                  repeats: config.repeats,
                  phase: phase,
                  opsPerSample: config.opsPerSample,
                );
              }
            } else if (config.di == 'kiwi') {
              final di = KiwiAdapter();
              if (scenario == UniversalScenario.asyncChain) {
                final benchAsync = UniversalChainAsyncBenchmark<KiwiContainer>(
                  di,
                  chainCount: c,
                  nestingDepth: d,
                  mode: mode,
                );
                benchResult = await BenchmarkRunner.runAsync(
                  benchmark: benchAsync,
                  warmups: config.warmups,
                  repeats: config.repeats,
                  phase: phase,
                  opsPerSample: config.opsPerSample,
                );
              } else {
                final benchSync = UniversalChainBenchmark<KiwiContainer>(
                  di,
                  chainCount: c,
                  nestingDepth: d,
                  mode: mode,
                  scenario: scenario,
                );
                benchResult = await BenchmarkRunner.runSync(
                  benchmark: benchSync,
                  warmups: config.warmups,
                  repeats: config.repeats,
                  phase: phase,
                  opsPerSample: config.opsPerSample,
                );
              }
            } else if (config.di == 'riverpod') {
              final di = RiverpodAdapter();
              if (scenario == UniversalScenario.asyncChain) {
                final benchAsync = UniversalChainAsyncBenchmark<
                    Map<String, rp.ProviderBase<Object?>>>(
                  di,
                  chainCount: c,
                  nestingDepth: d,
                  mode: mode,
                );
                benchResult = await BenchmarkRunner.runAsync(
                  benchmark: benchAsync,
                  warmups: config.warmups,
                  repeats: config.repeats,
                  phase: phase,
                  opsPerSample: config.opsPerSample,
                );
              } else {
                final benchSync = UniversalChainBenchmark<
                    Map<String, rp.ProviderBase<Object?>>>(
                  di,
                  chainCount: c,
                  nestingDepth: d,
                  mode: mode,
                  scenario: scenario,
                );
                benchResult = await BenchmarkRunner.runSync(
                  benchmark: benchSync,
                  warmups: config.warmups,
                  repeats: config.repeats,
                  phase: phase,
                  opsPerSample: config.opsPerSample,
                );
              }
            } else if (config.di == 'yx_scope') {
              final di = YxScopeAdapter();
              if (scenario == UniversalScenario.asyncChain) {
                final benchAsync =
                    UniversalChainAsyncBenchmark<UniversalYxScopeContainer>(
                  di,
                  chainCount: c,
                  nestingDepth: d,
                  mode: mode,
                );
                benchResult = await BenchmarkRunner.runAsync(
                  benchmark: benchAsync,
                  warmups: config.warmups,
                  repeats: config.repeats,
                  phase: phase,
                  opsPerSample: config.opsPerSample,
                );
              } else {
                final benchSync =
                    UniversalChainBenchmark<UniversalYxScopeContainer>(
                  di,
                  chainCount: c,
                  nestingDepth: d,
                  mode: mode,
                  scenario: scenario,
                );
                benchResult = await BenchmarkRunner.runSync(
                  benchmark: benchSync,
                  warmups: config.warmups,
                  repeats: config.repeats,
                  phase: phase,
                  opsPerSample: config.opsPerSample,
                );
              }
            } else {
              final di = CherrypickDIAdapter();
              if (scenario == UniversalScenario.asyncChain) {
                final benchAsync = UniversalChainAsyncBenchmark<Scope>(
                  di,
                  chainCount: c,
                  nestingDepth: d,
                  mode: mode,
                );
                benchResult = await BenchmarkRunner.runAsync(
                  benchmark: benchAsync,
                  warmups: config.warmups,
                  repeats: config.repeats,
                  phase: phase,
                  opsPerSample: config.opsPerSample,
                );
              } else {
                final benchSync = UniversalChainBenchmark<Scope>(
                  di,
                  chainCount: c,
                  nestingDepth: d,
                  mode: mode,
                  scenario: scenario,
                );
                benchResult = await BenchmarkRunner.runSync(
                  benchmark: benchSync,
                  warmups: config.warmups,
                  repeats: config.repeats,
                  phase: phase,
                  opsPerSample: config.opsPerSample,
                );
              }
            }
            final timings = benchResult.timings;
            if (timings.isEmpty) continue; // skip failed scenarios
            final sorted = [...timings]..sort();
            final count = sorted.length;
            final median = _median(sorted);
            final p95 = sorted[((count - 1) * 0.95).round()];
            // Медианное абсолютное отклонение: устойчиво к выбросам, которых
            // в этих замерах больше, чем полезного сигнала. Среднее и stddev
            // по такому распределению описывают в основном самый неудачный
            // замер, а не поведение контейнера.
            final mad =
                _median(sorted.map((x) => (x - median).abs()).toList()..sort());

            results.add({
              'benchmark': 'Universal_$bench',
              'di': config.di,
              'phase': phase.name,
              'chainCount': c,
              'nestingDepth': d,
              'median_ns': median.toStringAsFixed(1),
              'min_ns': sorted.first.toStringAsFixed(1),
              'p95_ns': p95.toStringAsFixed(1),
              'mad_ns': mad.toStringAsFixed(1),
              'ops_per_sample': benchResult.opsPerSample,
              'trials': count,
              'timings_ns': sorted.map((t) => t.toStringAsFixed(1)).toList(),
              'memory_diff_kb': benchResult.memoryDiffKb,
              'delta_peak_kb': benchResult.deltaPeakKb,
              'peak_rss_kb': benchResult.peakRssKb,
              'baseline_rss_kb': benchResult.baselineRssKb,
              'rss_over_baseline_kb':
                  benchResult.peakRssKb - benchResult.baselineRssKb,
            });
          }
        }
      }
    }
    final reportGenerators = {
      'pretty': PrettyReport(),
      'csv': CsvReport(),
      'json': JsonReport(),
      'markdown': MarkdownReport(),
    };
    print(reportGenerators[config.format]?.render(results) ??
        PrettyReport().render(results));
  }
}

/// Медиана отсортированного списка.
double _median(List<double> sorted) => sorted.length.isOdd
    ? sorted[sorted.length ~/ 2]
    : (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2;
