import 'dart:io';
import 'dart:math';
import 'package:benchmark_di/benchmarks/universal_chain_benchmark.dart';
import 'package:benchmark_di/benchmarks/universal_chain_async_benchmark.dart';

/// Holds the results for a single benchmark execution.
class BenchmarkResult {
  /// List of timings for each run (in microseconds).
  final List<num> timings;

  /// Difference in memory (RSS, in KB) after running.
  final int memoryDiffKb;

  /// Difference between peak RSS and initial RSS (in KB).
  final int deltaPeakKb;

  /// Peak RSS memory observed (in KB).
  final int peakRssKb;
  BenchmarkResult({
    required this.timings,
    required this.memoryDiffKb,
    required this.deltaPeakKb,
    required this.peakRssKb,
  });

  /// Computes a BenchmarkResult instance from run timings and memory data.
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

/// Static methods to execute and time benchmarks for DI containers.
class BenchmarkRunner {
  /// Runs a synchronous benchmark ([UniversalChainBenchmark]) for a given number of [warmups] and [repeats].
  /// Collects execution time and observed memory.
  static Future<BenchmarkResult> runSync({
    required UniversalChainBenchmark benchmark,
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
        timings: timings, rssValues: rssValues, memBefore: memBefore);
  }

  /// Runs an asynchronous benchmark ([UniversalChainAsyncBenchmark]) for a given number of [warmups] and [repeats].
  /// Collects execution time and observed memory.
  static Future<BenchmarkResult> runAsync({
    required UniversalChainAsyncBenchmark benchmark,
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
        timings: timings, rssValues: rssValues, memBefore: memBefore);
  }
}
