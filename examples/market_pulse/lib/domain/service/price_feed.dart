import 'package:cherrypick/cherrypick.dart';

import '../entity/quote.dart';

/// A source of live prices.
///
/// Two implementations are bound under different names (`live` / `replay`) and
/// swapped at runtime by [FeedSwitch], which is the whole point of
/// [Binding.withName] plus [Scope.dropModules] in this example.
///
/// Every implementation is [Disposable]: the DI container closes it when the
/// owning scope is closed, so a forgotten scope becomes a visible resource leak
/// in the DI Inspector instead of a silent one.
abstract class PriceFeed implements Disposable {
  /// Identifier shown in the UI, also used as the DI binding name.
  String get kind;

  /// Emits ticks for [symbol] until the returned subscription is cancelled.
  Stream<Quote> watch(String symbol);

  /// Number of streams currently open — the leak counter of the Inspector.
  int get openStreams;
}
