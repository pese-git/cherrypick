/// Every scope path used by the app, in one place.
///
/// The paths are dot-separated, which is exactly what
/// `CherryPick.openScope(scopeName: ...)` expects: it walks the path and opens
/// each missing subscope along the way.
///
/// ```text
/// root                              platform: config, clock, instruments, feeds
///  └── session                      the signed-in user: session, watchlist
///       └── market                  market data layer: the selected PriceFeed
///            ├── BTCUSD             one tab: SymbolTicker + warm-up history
///            └── ETHUSD
/// ```
abstract final class ScopeNames {
  /// User session. Closing it drops the watchlist and every open tab.
  static const String session = 'session';

  /// Market data layer. Owns the currently selected [PriceFeed] binding.
  static const String market = '$session.market';

  /// Throwaway scope used by the Inspector's circular-dependency experiment.
  static const String cycleLab = '$session.cycle-lab';

  /// Scope path of a single instrument tab.
  static String symbol(String symbol) => '$market.$symbol';
}
