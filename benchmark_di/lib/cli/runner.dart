import 'dart:io';
import 'dart:math';
import 'package:benchmark_di/benchmarks/universal_chain_benchmark.dart';
import 'package:benchmark_di/benchmarks/universal_chain_async_benchmark.dart';
import 'package:benchmark_di/cli/parser.dart';

int? _baselineRssKb;

/// Снимает RSS процесса до первой регистрации. Вызывается первой строкой
/// прогона.
///
/// Пустой Dart-процесс занимает порядка 169 MB под VM и JIT-код. Без
/// вычитания этого основания таблицы памяти показывают рантайм, а не
/// контейнер: разница между DI тонет в общем фоне.
///
/// Ленивый `final` здесь не годится: Dart инициализирует его при первом
/// обращении, то есть уже после прогона, и «baseline» получался бы замером
/// финального состояния.
void captureProcessBaseline() {
  _baselineRssKb ??= (ProcessInfo.currentRss / 1024).round();
}

/// RSS процесса до первой регистрации.
int get processBaselineRssKb =>
    _baselineRssKb ?? (ProcessInfo.currentRss / 1024).round();

/// Holds the results for a single benchmark execution.
class BenchmarkResult {
  /// Наносекунды на одну операцию, по одному значению на сэмпл.
  final List<double> timings;

  /// Сколько резолвов уместилось в один замер (1 для фазы first-resolve).
  final int opsPerSample;

  /// Difference in memory (RSS, in KB) after running.
  final int memoryDiffKb;

  /// Difference between peak RSS and initial RSS (in KB).
  final int deltaPeakKb;

  /// Peak RSS memory observed (in KB).
  final int peakRssKb;

  /// RSS процесса до первой регистрации.
  final int baselineRssKb;

  BenchmarkResult({
    required this.timings,
    required this.opsPerSample,
    required this.memoryDiffKb,
    required this.deltaPeakKb,
    required this.peakRssKb,
    required this.baselineRssKb,
  });

  /// Computes a BenchmarkResult instance from run timings and memory data.
  factory BenchmarkResult.collect({
    required List<double> timings,
    required List<int> rssValues,
    required int memBefore,
    required int opsPerSample,
  }) {
    final memAfter = ProcessInfo.currentRss;
    final memDiffKB = ((memAfter - memBefore) / 1024).round();
    final peakRss = [...rssValues, memBefore].reduce(max);
    final deltaPeakKb = ((peakRss - memBefore) / 1024).round();
    return BenchmarkResult(
      timings: timings,
      opsPerSample: opsPerSample,
      memoryDiffKb: memDiffKB,
      deltaPeakKb: deltaPeakKb,
      peakRssKb: (peakRss / 1024).round(),
      baselineRssKb: processBaselineRssKb,
    );
  }
}

/// Static methods to execute and time benchmarks for DI containers.
class BenchmarkRunner {
  /// Синхронный прогон.
  ///
  /// [opsPerSample] действует только в фазе steady-state: там один резолв
  /// стоит десятки наносекунд, и единичный замер тонет в разрешении таймера,
  /// поэтому меряется пачка и делится на её размер. В фазе first-resolve
  /// пачка невозможна по определению — второй вызов уже попадёт в кеш, —
  /// поэтому там меряется один вызов, но в тиках (наносекундах).
  static Future<BenchmarkResult> runSync({
    required UniversalChainBenchmark benchmark,
    required int warmups,
    required int repeats,
    required ResolvePhase phase,
    required int opsPerSample,
  }) async {
    final steady = phase == ResolvePhase.steadyStateResolve;
    final ops = steady ? opsPerSample : 1;
    final timings = <double>[];
    final rssValues = <int>[];

    for (int i = 0; i < warmups; i++) {
      benchmark.setup();
      if (steady) benchmark.prewarm();
      for (int k = 0; k < ops; k++) {
        benchmark.run();
      }
      await benchmark.teardownAsync();
    }

    final memBefore = ProcessInfo.currentRss;
    for (int i = 0; i < repeats; i++) {
      benchmark.setup();
      if (steady) benchmark.prewarm();
      final sw = Stopwatch()..start();
      for (int k = 0; k < ops; k++) {
        benchmark.run();
      }
      sw.stop();
      timings.add(_nanosPerOp(sw, ops));
      rssValues.add(ProcessInfo.currentRss);
      await benchmark.teardownAsync();
    }
    return BenchmarkResult.collect(
      timings: timings,
      rssValues: rssValues,
      memBefore: memBefore,
      opsPerSample: ops,
    );
  }

  /// Асинхронный прогон. Смысл [opsPerSample] тот же.
  static Future<BenchmarkResult> runAsync({
    required UniversalChainAsyncBenchmark benchmark,
    required int warmups,
    required int repeats,
    required ResolvePhase phase,
    required int opsPerSample,
  }) async {
    final steady = phase == ResolvePhase.steadyStateResolve;
    final ops = steady ? opsPerSample : 1;
    final timings = <double>[];
    final rssValues = <int>[];

    for (int i = 0; i < warmups; i++) {
      await benchmark.setup();
      if (steady) await benchmark.prewarm();
      for (int k = 0; k < ops; k++) {
        await benchmark.run();
      }
      await benchmark.teardownAsync();
    }

    final memBefore = ProcessInfo.currentRss;
    for (int i = 0; i < repeats; i++) {
      await benchmark.setup();
      if (steady) await benchmark.prewarm();
      final sw = Stopwatch()..start();
      for (int k = 0; k < ops; k++) {
        await benchmark.run();
      }
      sw.stop();
      timings.add(_nanosPerOp(sw, ops));
      rssValues.add(ProcessInfo.currentRss);
      await benchmark.teardownAsync();
    }
    return BenchmarkResult.collect(
      timings: timings,
      rssValues: rssValues,
      memBefore: memBefore,
      opsPerSample: ops,
    );
  }

  /// Наносекунды на одну операцию.
  ///
  /// elapsedMicroseconds округляет до целых микросекунд, а один резолв стоит
  /// десятки наносекунд — на такой шкале 18 замеров из 20 давали ровно ноль.
  /// Пересчёт из тиков через frequency делает разрешение явным.
  static double _nanosPerOp(Stopwatch sw, int ops) =>
      sw.elapsedTicks * 1e9 / sw.frequency / ops;
}
