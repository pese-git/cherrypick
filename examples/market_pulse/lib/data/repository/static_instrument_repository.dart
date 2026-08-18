import 'dart:math';

import 'package:fpdart/fpdart.dart';

import '../../domain/entity/instrument.dart';
import '../../domain/failure.dart';
import '../../domain/repository/instrument_repository.dart';

/// In-memory [InstrumentRepository] with artificial latency.
///
/// Keeps the example backend-free while still exercising the asynchronous
/// binding APIs — and the failure branch, which `DELISTED` reaches on purpose.
class StaticInstrumentRepository implements InstrumentRepository {
  /// Instruments whose history cannot be loaded, so the failure path is
  /// reachable by clicking rather than only in tests.
  static const delistedSymbol = 'DELISTED';

  static const _universe = <Instrument>[
    Instrument(
      symbol: 'BTCUSD',
      title: 'Bitcoin / US Dollar',
      basePrice: 64200,
      volatility: 0.004,
    ),
    Instrument(
      symbol: 'ETHUSD',
      title: 'Ethereum / US Dollar',
      basePrice: 3150,
      volatility: 0.006,
    ),
    Instrument(
      symbol: 'AAPL',
      title: 'Apple Inc.',
      basePrice: 228.5,
      volatility: 0.002,
    ),
    Instrument(
      symbol: 'EURUSD',
      title: 'Euro / US Dollar',
      basePrice: 1.087,
      volatility: 0.0008,
    ),
    Instrument(
      symbol: 'GOLD',
      title: 'Gold Spot',
      basePrice: 2412.0,
      volatility: 0.0015,
    ),
    Instrument(
      symbol: delistedSymbol,
      title: 'Delisted Corp. — history unavailable',
      basePrice: 12.0,
      volatility: 0.003,
    ),
  ];

  @override
  TaskEither<AppFailure, List<Instrument>> loadAll() =>
      TaskEither.tryCatch(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return _universe;
      }, (error, _) => AppFailure.unavailable('Instrument universe ($error)'));

  @override
  TaskEither<AppFailure, List<double>> loadHistory(String symbol) {
    if (symbol == delistedSymbol) {
      return TaskEither.left(AppFailure.unavailable('History for $symbol'));
    }

    final instrument = _universe.where((i) => i.symbol == symbol).firstOrNull;
    if (instrument == null) {
      return TaskEither.left(AppFailure.unknownSymbol(symbol));
    }

    return TaskEither.tryCatch(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Deterministic per symbol, so reopening a tab shows the same warm-up.
      final random = Random(symbol.hashCode);
      var price = instrument.basePrice;
      return List<double>.generate(30, (_) {
        price *= 1 + (random.nextDouble() - 0.5) * instrument.volatility * 4;
        return price;
      });
    }, (error, _) => AppFailure.unavailable('History for $symbol ($error)'));
  }
}
