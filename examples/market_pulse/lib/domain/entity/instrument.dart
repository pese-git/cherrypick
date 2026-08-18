import 'package:freezed_annotation/freezed_annotation.dart';

part 'instrument.freezed.dart';

/// A tradable instrument shown in the watchlist.
///
/// Instruments are loaded asynchronously at startup, which is what makes
/// `toProvideAsync` / `resolveAsync` a natural fit rather than a decoration.
@freezed
abstract class Instrument with _$Instrument {
  const factory Instrument({
    /// Ticker used as the DI subscope name, e.g. `BTCUSD`.
    required String symbol,

    /// Human readable name shown in the watchlist.
    required String title,

    /// Price the synthetic feed starts from.
    required double basePrice,

    /// Relative volatility of the synthetic feed, `0.01` == 1% per tick.
    required double volatility,
  }) = _Instrument;
}
