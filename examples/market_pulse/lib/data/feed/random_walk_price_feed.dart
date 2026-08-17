import 'dart:async';
import 'dart:math';

import '../../domain/entity/instrument.dart';
import '../../domain/entity/quote.dart';
import '../../domain/service/price_feed.dart';

/// The "live" feed: an unpredictable random walk, one timer per subscription.
///
/// Bound as `withName('live')` and registered as a singleton in the root scope.
/// Implements [Disposable] through [PriceFeed], so closing the root scope
/// cancels every timer it ever started.
class RandomWalkPriceFeed implements PriceFeed {
  final List<Instrument> _instruments;
  final Duration _tickInterval;
  final Random _random;

  final Map<String, StreamController<Quote>> _controllers = {};
  final Map<String, Timer> _timers = {};

  RandomWalkPriceFeed({
    required List<Instrument> instruments,
    required Duration tickInterval,
    Random? random,
  }) : _instruments = instruments,
       _tickInterval = tickInterval,
       _random = random ?? Random();

  @override
  String get kind => 'live';

  @override
  int get openStreams => _controllers.length;

  @override
  Stream<Quote> watch(String symbol) {
    final existing = _controllers[symbol];
    if (existing != null) return existing.stream;

    final instrument = _instruments.firstWhere(
      (i) => i.symbol == symbol,
      orElse: () => throw StateError('Unknown symbol: $symbol'),
    );

    var price = instrument.basePrice;
    final controller = StreamController<Quote>.broadcast(
      onCancel: () => _stop(symbol),
    );
    _controllers[symbol] = controller;

    _timers[symbol] = Timer.periodic(_tickInterval, (_) {
      price *= 1 + (_random.nextDouble() - 0.5) * instrument.volatility * 2;
      controller.add(
        Quote(symbol: symbol, price: price, timestamp: DateTime.now()),
      );
    });

    return controller.stream;
  }

  void _stop(String symbol) {
    _timers.remove(symbol)?.cancel();
    unawaited(_controllers.remove(symbol)?.close());
  }

  @override
  Future<void> dispose() async {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();

    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();
  }
}
