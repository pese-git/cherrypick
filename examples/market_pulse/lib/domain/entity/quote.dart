import 'package:freezed_annotation/freezed_annotation.dart';

part 'quote.freezed.dart';

/// A single price tick produced by a `PriceFeed`.
@freezed
abstract class Quote with _$Quote {
  const factory Quote({
    required String symbol,
    required double price,
    required DateTime timestamp,
  }) = _Quote;

  const Quote._();

  /// Signed change relative to [previous], or `0` when there is no history yet.
  double changeFrom(Quote? previous) =>
      previous == null ? 0 : price - previous.price;
}
