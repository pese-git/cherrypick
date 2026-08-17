import 'dart:async';

import 'package:cherrypick/cherrypick.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/quote.dart';
import '../../domain/failure.dart';
import '../../domain/service/price_feed.dart';

part 'market_tab_bloc.freezed.dart';

/// Events of a single instrument tab.
@freezed
sealed class MarketTabEvent with _$MarketTabEvent {
  /// A tick arrived from the [PriceFeed] this bloc subscribed to.
  const factory MarketTabEvent.quoteReceived(Quote quote) =
      MarketTabQuoteReceived;
}

/// State of a single instrument tab.
///
/// A union, not a nullable-field bag: a tab either has a price series or it has
/// a failure, and `switch` in the widget makes the compiler check both.
@freezed
sealed class MarketTabState with _$MarketTabState {
  /// The warm-up history loaded; ticks are flowing.
  const factory MarketTabState.live({
    required String symbol,
    required List<double> prices,
    Quote? lastQuote,
    @Default(0) int tickCount,
  }) = MarketTabLive;

  /// The warm-up history could not be loaded — see the `DELISTED` instrument.
  const factory MarketTabState.failure({
    required String symbol,
    required AppFailure failure,
  }) = MarketTabFailure;

  const MarketTabState._();

  // `symbol` needs no getter here: freezed hoists fields common to every
  // constructor of a union onto the base class automatically.

  /// Prices so far, empty when the tab failed to load.
  List<double> get prices => switch (this) {
    MarketTabLive(:final prices) => prices,
    MarketTabFailure() => const [],
  };

  /// Last price, `0` before the first tick.
  double get last => prices.isEmpty ? 0 : prices.last;

  /// Change against the previous point, `0` when there is no previous one.
  double get delta =>
      prices.length < 2 ? 0 : prices.last - prices[prices.length - 2];
}

/// The bloc behind one instrument tab — and the reason this example exists.
///
/// It is created inside `session.market.<SYMBOL>` and implements [Disposable],
/// so **the DI container closes it**, not the widget tree. The UI receives it
/// through `BlocProvider.value`, which deliberately does not manage lifetime.
///
/// That is the opposite of the usual `BlocProvider(create: ...)` arrangement
/// (see the sibling `postly` example, where the widget owns its bloc). Here the
/// bloc holds a live subscription that must die exactly when the tab's scope
/// does — not when some widget happens to be rebuilt or removed.
class MarketTabBloc extends Bloc<MarketTabEvent, MarketTabState>
    implements Disposable {
  final int _historyLength;

  StreamSubscription<Quote>? _subscription;

  /// [warmUpHistory] arrives as an [Either] straight from the repository.
  ///
  /// Folding it into the initial state is the whole error-handling story of the
  /// tab: no try/catch, no nullable history, no "did this load?" flag.
  MarketTabBloc({
    required String symbol,
    required PriceFeed feed,
    required Either<AppFailure, List<double>> warmUpHistory,
    required int historyLength,
  }) : _historyLength = historyLength,
       super(
         warmUpHistory.match(
           (failure) =>
               MarketTabState.failure(symbol: symbol, failure: failure),
           (prices) => MarketTabState.live(
             symbol: symbol,
             prices: List<double>.unmodifiable(prices),
           ),
         ),
       ) {
    on<MarketTabQuoteReceived>(_onQuoteReceived);

    // A tab that failed to load history subscribes to nothing: there is no
    // resource to leak and nothing to show.
    if (state is MarketTabLive) {
      _subscription = feed
          .watch(symbol)
          .listen((quote) => add(MarketTabEvent.quoteReceived(quote)));
    }
  }

  void _onQuoteReceived(
    MarketTabQuoteReceived event,
    Emitter<MarketTabState> emit,
  ) {
    if (state case final MarketTabLive live) {
      final next = [...live.prices, event.quote.price];

      emit(
        live.copyWith(
          prices: List<double>.unmodifiable(
            next.length > _historyLength
                ? next.sublist(next.length - _historyLength)
                : next,
          ),
          lastQuote: event.quote,
          tickCount: live.tickCount + 1,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }

  /// Bridges CherryPick's [Disposable] to `Bloc.close()`.
  ///
  /// This one line is what puts the bloc's lifetime under the container's
  /// control: closing the scope closes the bloc and cancels its subscription.
  @override
  Future<void> dispose() => close();
}
