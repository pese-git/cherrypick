import 'package:cherrypick/cherrypick.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_pulse/core/format/quote_formatter.dart';
import 'package:market_pulse/core/observability/di_event.dart';
import 'package:market_pulse/domain/entity/instrument.dart';

import 'di_harness.dart';

/// The Inspector is only as truthful as the observer feeding it, so the
/// observer gets its own tests.
///
/// Note the `pump` helper: the cubit publishes on a microtask, because observer
/// callbacks fire synchronously from inside `resolve()` — including resolves
/// that happen during a widget build.
void main() {
  late TestHarness harness;

  setUp(() async {
    harness = await TestHarness.bootstrap();
  });

  tearDown(TestHarness.tearDown);

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('a singleton is resolved many times but constructed once', () async {
    final root = CherryPick.openRootScope();

    root.resolve<QuoteFormatter>();
    root.resolve<QuoteFormatter>();
    root.resolve<QuoteFormatter>();
    await pump();

    final stats = harness.inspector.state.resolveStats['QuoteFormatter'];
    expect(stats, isNotNull);
    expect(stats!.resolves, 3);
    expect(stats.instances, 1, reason: '.singleton() is doing its job');
    expect(stats.reused, 2);
  });

  test(
    'a provider without .singleton() constructs one instance per resolve',
    () async {
      final scope = CherryPick.openRootScope().openSubScope('stats-probe')
        ..installModules([_ProbeModule()]);

      scope.resolve<_Probe>();
      scope.resolve<_Probe>();
      await pump();

      final stats = harness.inspector.state.resolveStats['_Probe'];
      expect(stats, isNotNull);
      expect(stats!.resolves, 2);
      expect(stats.instances, 2, reason: 'a fresh object on every resolve');
      expect(stats.reused, 0);
    },
  );

  test('the counters measure identity, not equality', () async {
    harness.signIn();
    await harness.workspace.openSymbol('BTCUSD');

    final scope = CherryPick.openScope(scopeName: 'session.market.BTCUSD');
    final first = scope.resolve<Option<Instrument>>(params: 'BTCUSD');
    final second = scope.resolve<Option<Instrument>>(params: 'BTCUSD');
    await pump();

    // Two `Some`s wrapping the same canonicalised const Instrument: equal by
    // value, but distinct objects. The Inspector reports two instances, which
    // is the truthful answer — the provider really did build a wrapper twice.
    expect(first, second);
    expect(identical(first, second), isFalse);

    final stats = harness.inspector.state.resolveStats['Option<Instrument>'];
    expect(stats, isNotNull);
    expect(stats!.resolves, greaterThanOrEqualTo(2));
    expect(stats.instances, 2);

    await harness.workspace.closeSymbol('BTCUSD');
  });

  test('scope transitions reach the event feed', () async {
    harness.signIn();
    await harness.workspace.openSymbol('BTCUSD');
    await harness.workspace.closeSymbol('BTCUSD');
    await pump();

    final kinds = harness.inspector.state.events.map((e) => e.kind).toSet();
    expect(kinds, contains(DiEventKind.scope));
    expect(kinds, contains(DiEventKind.created));
    expect(kinds, contains(DiEventKind.module));
  });

  test('a detected cycle is recorded with its chain', () async {
    harness.signIn();

    await harness.workspace.runCycleExperiment();
    await pump();

    expect(harness.inspector.state.lastCycle, isNotEmpty);
  });
}

/// A type bound without `.singleton()`, used to prove the counters can tell a
/// factory from a singleton.
class _Probe {}

class _ProbeModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<_Probe>().toProvide(_Probe.new);
  }
}
