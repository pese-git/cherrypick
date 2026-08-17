/// Every location in the app, in one place.
///
/// On the web these are real URLs, which is the point: `/market/BTCUSD` in the
/// address bar is a request to open the DI subscope `session.market.BTCUSD`.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String market = '/market';
  static const String logs = '/logs';

  /// Location of a single instrument tab.
  static String symbol(String symbol) => '$market/$symbol';

  /// Query parameter carrying the location a guard bounced the user away from.
  static const String fromParam = 'from';
}
