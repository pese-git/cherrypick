import 'package:cherrypick/cherrypick.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_pulse/core/di/market_module.dart';
import 'package:market_pulse/core/di/scope_names.dart';
import 'package:market_pulse/data/repository/static_instrument_repository.dart';
import 'package:market_pulse/domain/repository/instrument_repository.dart';
import 'package:market_pulse/domain/service/price_feed.dart';
import 'package:market_pulse/presentation/market/market_tab_bloc.dart';
import 'package:market_pulse/presentation/session/watchlist_cubit.dart';

import 'di_harness.dart';

/// These assert the behaviour the app is built to demonstrate: closing a scope
/// really does release what was created inside it — including closing blocs
/// that no widget owns.
void main() {
  late TestHarness harness;

  setUp(() async {
    harness = await TestHarness.bootstrap();
  });

  tearDown(TestHarness.tearDown);

  PriceFeed feedNamed(String name) =>
      CherryPick.openRootScope().resolve<PriceFeed>(named: name);

  test(
    'closing a symbol scope closes its bloc and cancels the stream',
    () async {
      harness.signIn();

      final bloc = await harness.workspace.openSymbol('BTCUSD');
      expect(bloc.isClosed, isFalse);
      expect(feedNamed('live').openStreams, 1);

      await harness.workspace.closeSymbol('BTCUSD');

      expect(
        bloc.isClosed,
        isTrue,
        reason: 'the container calls dispose(), which calls Bloc.close()',
      );
      expect(
        feedNamed('live').openStreams,
        0,
        reason: 'closing the bloc must cancel its feed subscription',
      );
    },
  );

  test('signing out closes every bloc underneath the session scope', () async {
    harness.signIn();

    final btc = await harness.workspace.openSymbol('BTCUSD');
    final eth = await harness.workspace.openSymbol('ETHUSD');
    final watchlist = CherryPick.openScope(
      scopeName: ScopeNames.session,
    ).resolve<WatchlistCubit>();
    expect(feedNamed('live').openStreams, 2);

    await harness.workspace.signOut();

    expect(btc.isClosed, isTrue);
    expect(eth.isClosed, isTrue);
    expect(watchlist.isClosed, isTrue);
    expect(feedNamed('live').openStreams, 0);
  });

  test('each symbol scope owns its own bloc', () async {
    harness.signIn();

    final btc = await harness.workspace.openSymbol('BTCUSD');
    final eth = await harness.workspace.openSymbol('ETHUSD');

    expect(identical(btc, eth), isFalse);
    expect(btc.state.symbol, 'BTCUSD');
    expect(eth.state.symbol, 'ETHUSD');

    // Singleton *within* its scope: resolving again returns the same bloc.
    final scope = CherryPick.openScope(scopeName: ScopeNames.symbol('BTCUSD'));
    final again = await scope.resolveAsync<MarketTabBloc>(params: 'BTCUSD');
    expect(identical(btc, again), isTrue);
  });

  test('a new session does not inherit the previous watchlist', () async {
    harness.signIn(userId: 'desk-eu', name: 'Europe desk');
    await harness.workspace.openSymbol('BTCUSD');

    final first = CherryPick.openScope(
      scopeName: ScopeNames.session,
    ).resolve<WatchlistCubit>();
    expect(first.state.openSymbols, ['BTCUSD']);

    await harness.workspace.signOut();
    harness.signIn(userId: 'desk-us', name: 'US desk');

    final second = CherryPick.openScope(
      scopeName: ScopeNames.session,
    ).resolve<WatchlistCubit>();
    expect(identical(first, second), isFalse);
    expect(second.state.openSymbols, isEmpty);
    expect(second.session.userId, 'desk-us');
  });

  test(
    'switching the feed rebinds the market scope and moves the streams',
    () async {
      harness.signIn();
      await harness.workspace.openSymbol('BTCUSD');

      expect(feedNamed('live').openStreams, 1);
      expect(feedNamed('replay').openStreams, 0);

      await harness.workspace.switchFeed('replay');

      expect(harness.workspace.state.feedKind, 'replay');
      expect(
        feedNamed('live').openStreams,
        0,
        reason: 'tabs are closed before the module is dropped',
      );
      expect(
        feedNamed('replay').openStreams,
        1,
        reason: 'and reopened against the new binding',
      );

      final selected = CherryPick.openScope(
        scopeName: ScopeNames.market,
      ).resolve<SelectedFeed>();
      expect(selected.kind, 'replay');
    },
  );

  test('the bloc emits state as the feed ticks', () async {
    harness.signIn();

    final bloc = await harness.workspace.openSymbol('BTCUSD');
    final before = (bloc.state as MarketTabLive).tickCount;

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<MarketTabState>(
          (s) => s is MarketTabLive && s.tickCount > before,
        ),
      ),
    );

    await harness.workspace.closeSymbol('BTCUSD');
  });

  test('a failing history load produces a failure tab that subscribes to '
      'nothing', () async {
    harness.signIn();

    final bloc = await harness.workspace.openSymbol(
      StaticInstrumentRepository.delistedSymbol,
    );

    expect(bloc.state, isA<MarketTabFailure>());
    expect(
      feedNamed('live').openStreams,
      0,
      reason: 'a tab with no data must not open a stream',
    );

    // It is still a scope-owned bloc, so closing the tab still closes it.
    await harness.workspace.closeSymbol(
      StaticInstrumentRepository.delistedSymbol,
    );
    expect(bloc.isClosed, isTrue);
  });

  test('the repository reports a missing symbol as Left', () async {
    final repository = CherryPick.openRootScope()
        .resolve<InstrumentRepository>();

    final result = await repository.loadHistory('NOPE').run();

    expect(result.isLeft(), isTrue);
    expect(
      result.match((failure) => failure.message, (_) => ''),
      contains('Unknown symbol'),
    );
  });

  test(
    'the cycle experiment reports the chain instead of overflowing',
    () async {
      harness.signIn();

      final result = await harness.workspace.runCycleExperiment();

      // Left is the outcome we want: the cycle was caught, not survived.
      expect(result.isLeft(), isTrue);

      final chain = result.match((report) => report.chain, (_) => <String>[]);
      expect(chain, isNotEmpty);
      expect(chain.join(' '), contains('RiskEngine'));
    },
  );

  test('an unbound dependency becomes Option.none() rather than null', () {
    harness.signIn();

    final (tryResult, resolveResult) = harness.workspace
        .probeOptionalDependency();

    expect(tryResult, contains('Option.none()'));
    expect(resolveResult, contains('threw'));
  });
}
