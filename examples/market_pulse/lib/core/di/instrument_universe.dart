import 'package:fpdart/fpdart.dart';

import '../../domain/entity/instrument.dart';

/// The loaded instrument list, wrapped in a nominal type.
///
/// Binding `List<Instrument>` directly works too (see `BootstrapModule`), but a
/// named wrapper keeps generated provider signatures unambiguous and reads
/// better at the call site than a bare collection type.
class InstrumentUniverse {
  final List<Instrument> items;

  const InstrumentUniverse(this.items);

  /// Lookup that may legitimately fail — a URL can name anything.
  ///
  /// Deep links made this the important one: `/market/NOPE` must render a tab
  /// that says so, not throw its way out of a route builder.
  Option<Instrument> find(String symbol) =>
      Option.fromNullable(items.where((i) => i.symbol == symbol).firstOrNull);

  /// Lookup for callers that treat an unknown symbol as a bug.
  Instrument bySymbol(String symbol) =>
      find(symbol).getOrElse(() => throw StateError('Unknown symbol: $symbol'));
}
