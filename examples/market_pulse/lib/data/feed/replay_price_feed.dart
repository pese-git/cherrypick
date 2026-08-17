import 'dart:async';

import '../../domain/entity/instrument.dart';
import '../../domain/entity/quote.dart';
import '../../domain/service/price_feed.dart';

/// The "replay" feed: a deterministic loop over a canned sine-like series.
///
/// Same abstraction as [RandomWalkPriceFeed], bound under a different name.
/// Deterministic output is what makes it usable from widget tests, and it is
/// the second half of the `withName` demonstration in the UI.
class ReplayPriceFeed implements PriceFeed {
  final List<Instrument> _instruments;
  final Duration _tickInterval;

  final Map<String, StreamController<Quote>> _controllers = {};
  final Map<String, Timer> _timers = {};

  ReplayPriceFeed({
    required List<Instrument> instruments,
    required Duration tickInterval,
  }) : _instruments = instruments,
       _tickInterval = tickInterval;

  @override
  String get kind => 'replay';

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

    final controller = StreamController<Quote>.broadcast(
      onCancel: () => _stop(symbol),
    );
    _controllers[symbol] = controller;

    var step = 0;
    _timers[symbol] = Timer.periodic(_tickInterval, (_) {
      // A repeating 20-step saw wave: predictable, easy to assert on.
      final phase = (step % 20) / 20;
      final swing = (phase < 0.5 ? phase : 1 - phase) * 4 - 1;
      final price = instrument.basePrice * (1 + swing * instrument.volatility);
      step++;
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
