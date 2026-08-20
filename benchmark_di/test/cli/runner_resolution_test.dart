import 'package:benchmark_di/benchmarks/universal_chain_benchmark.dart';
import 'package:benchmark_di/cli/parser.dart';
import 'package:benchmark_di/cli/runner.dart';
import 'package:benchmark_di/di_adapters/cherrypick_adapter.dart';
import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:cherrypick/cherrypick.dart';
import 'package:test/test.dart';

void main() {
  test('быстрая операция не измеряется нулями', () async {
    final benchmark = UniversalChainBenchmark<Scope>(
      CherrypickDIAdapter(),
      chainCount: 1,
      nestingDepth: 1,
      mode: UniversalBindingMode.singletonStrategy,
      scenario: UniversalScenario.named,
    );
    final result = await BenchmarkRunner.runSync(
      benchmark: benchmark,
      warmups: 2,
      repeats: 20,
      phase: ResolvePhase.steadyStateResolve,
      opsPerSample: 1000,
    );

    expect(result.timings, hasLength(20));
    expect(result.timings.where((t) => t == 0), isEmpty,
        reason: 'нулевые замеры означают, что разрешение таймера крупнее '
            'измеряемой величины — числа в отчёте были бы шумом');
  });

  test('first-resolve меряет один вызов, steady — пачку', () async {
    UniversalChainBenchmark<Scope> makeBenchmark() =>
        UniversalChainBenchmark<Scope>(
          CherrypickDIAdapter(),
          chainCount: 1,
          nestingDepth: 1,
          mode: UniversalBindingMode.singletonStrategy,
          scenario: UniversalScenario.named,
        );

    final first = await BenchmarkRunner.runSync(
      benchmark: makeBenchmark(),
      warmups: 1,
      repeats: 5,
      phase: ResolvePhase.firstResolve,
      opsPerSample: 1000,
    );
    expect(first.opsPerSample, 1,
        reason: 'пачка в first-resolve невозможна: второй вызов уже кеширован');

    final steady = await BenchmarkRunner.runSync(
      benchmark: makeBenchmark(),
      warmups: 1,
      repeats: 5,
      phase: ResolvePhase.steadyStateResolve,
      opsPerSample: 1000,
    );
    expect(steady.opsPerSample, 1000);
  });
}
