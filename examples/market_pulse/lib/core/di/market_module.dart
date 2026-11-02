import 'package:cherrypick/cherrypick.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/config/app_config.dart';
import '../../domain/entity/instrument.dart';
import '../../domain/failure.dart';
import '../../domain/repository/instrument_repository.dart';
import '../../domain/service/price_feed.dart';
import '../../presentation/market/market_tab_bloc.dart';
import 'instrument_universe.dart';

part 'market_module.freezed.dart';

/// The feed currently selected in the UI.
///
/// A nominal wrapper instead of an unnamed `PriceFeed` binding: resolving
/// `PriceFeed` from inside a `PriceFeed` provider would be self-referential and
/// would (correctly) upset the cycle detector.
@freezed
abstract class SelectedFeed with _$SelectedFeed {
  const factory SelectedFeed({required PriceFeed feed, required String kind}) =
      _SelectedFeed;
}

/// Installed into `session.market`, and swapped at runtime.
///
/// `WorkspaceCubit.switchFeed` closes every symbol subscope, calls
/// [Scope.dropModules] here and installs this module again with the other
/// [kind] — the runtime-reconfiguration path that `dropModules` exists for.
class MarketDataModule extends Module {
  /// Name of the [PriceFeed] binding to delegate to: `live` or `replay`.
  final String kind;

  MarketDataModule({required this.kind});

  @override
  void builder(Scope currentScope) {
    bind<SelectedFeed>()
        .toProvide(
          () => SelectedFeed(
            feed: currentScope.resolve<PriceFeed>(named: kind),
            kind: kind,
          ),
        )
        .singleton();
  }
}

/// Installed into `session.market.<SYMBOL>` — one instance per open tab.
///
/// Shows both parameterised binding forms:
/// * [Binding.toProvideWithParams]      — sync, looks the instrument up
/// * [Binding.toProvideAsyncWithParams] — async, loads warm-up history
///
/// The bloc is a singleton *within this subscope*, so two tabs never share one,
/// and closing the tab closes exactly one bloc and one subscription.
class SymbolModule extends Module {
  final String symbol;

  SymbolModule(this.symbol);

  @override
  void builder(Scope currentScope) {
    // Option, not Instrument: a deep link can name a ticker that does not
    // exist, and "absent" is a normal answer rather than an exception.
    bind<Option<Instrument>>().toProvideWithParams(
      (params) =>
          currentScope.resolve<InstrumentUniverse>().find(params as String),
    );

    // The binding's type is the Either itself: failure is carried through the
    // container as a value, not thrown past it.
    bind<Either<AppFailure, List<double>>>()
        .withName('history')
        .toProvideAsyncWithParams(
          (params) => currentScope
              .resolve<InstrumentRepository>()
              .loadHistory(params as String)
              .run(),
        );

    bind<MarketTabBloc>().toProvideAsyncWithParams((params) async {
      final symbol = params as String;
      final config = currentScope.resolve<AppConfig>();
      final history = await currentScope
          .resolveAsync<Either<AppFailure, List<double>>>(
            named: 'history',
            params: symbol,
          );

      return MarketTabBloc(
        symbol: symbol,
        feed: currentScope.resolve<SelectedFeed>().feed,
        warmUpHistory: history,
        historyLength: config.historyLength,
      );
    }).singleton();
  }
}
