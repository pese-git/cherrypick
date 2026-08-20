import 'package:benchmark_di/benchmarks/universal_chain_benchmark.dart';
import 'package:benchmark_di/cli/parser.dart';
import 'package:benchmark_di/cli/runner.dart';
import 'package:benchmark_di/di_adapters/cherrypick_adapter.dart';
import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:cherrypick/cherrypick.dart';
import 'package:test/test.dart';

/// Записывает, какой root scope видит каждая итерация раннера.
///
/// Проверять состояние после прогона бесполезно: вызывающий делает await, и к
/// этому моменту отложенное закрытие успевает отработать. Загрязнение живёт
/// между итерациями, и увидеть его можно только изнутри цикла.
class _ObservingBenchmark extends UniversalChainBenchmark<Scope> {
  final List<Scope> seenScopes = [];

  _ObservingBenchmark()
      : super(
          CherrypickDIAdapter(),
          chainCount: 2,
          nestingDepth: 3,
          mode: UniversalBindingMode.lazySingletonStrategy,
          scenario: UniversalScenario.chain,
        );

  @override
  void setup() {
    super.setup();
    seenScopes.add(CherryPick.openRootScope());
  }
}

void main() {
  test('каждая итерация раннера получает свежий root scope', () async {
    final benchmark = _ObservingBenchmark();

    await BenchmarkRunner.runSync(
      benchmark: benchmark,
      warmups: 1,
      repeats: 2,
      phase: ResolvePhase.firstResolve,
    );

    expect(benchmark.seenScopes, hasLength(3));
    final distinct = <Scope>[];
    for (final scope in benchmark.seenScopes) {
      if (!distinct.any((s) => identical(s, scope))) distinct.add(scope);
    }
    expect(distinct, hasLength(3),
        reason: 'root scope переиспользован между итерациями: teardown '
            'вызывался без await, модули накапливались в одном scope, '
            'состояние контейнера невоспроизводимо');
  });
}
