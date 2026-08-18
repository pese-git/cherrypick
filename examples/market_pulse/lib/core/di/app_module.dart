import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

import '../../data/config/app_config.dart';
import '../../data/feed/random_walk_price_feed.dart';
import '../../data/feed/replay_price_feed.dart';
import '../../domain/service/price_feed.dart';
import '../format/quote_formatter.dart';
import 'instrument_universe.dart';

part 'app_module.module.cherrypick.g.dart';

/// The generated half of the root scope.
///
/// `build_runner` turns this abstract class into `$AppModule`, a real [Module]
/// whose `builder` contains the `bind<...>()` calls — including resolving every
/// provider argument from `currentScope`. Compare with [PlatformModule], which
/// does the same thing by hand for values that must be passed in.
@module()
abstract class AppModule extends Module {
  /// Two implementations of one abstraction, told apart by `@named`.
  ///
  /// Nothing in the UI depends on which one is live — the market scope resolves
  /// whichever name is currently selected.
  @provide()
  @singleton()
  @named('live')
  PriceFeed liveFeed(AppConfig config, InstrumentUniverse universe) =>
      RandomWalkPriceFeed(
        instruments: universe.items,
        tickInterval: config.tickInterval,
      );

  @provide()
  @singleton()
  @named('replay')
  PriceFeed replayFeed(AppConfig config, InstrumentUniverse universe) =>
      ReplayPriceFeed(
        instruments: universe.items,
        tickInterval: config.tickInterval,
      );

  /// A ready value rather than a factory — `@instance` maps to `toInstance`.
  @instance()
  @named('appName')
  String appName() => 'Market Pulse';

  /// Resolved once and cached; every later resolve is a cache hit.
  @provide()
  @singleton()
  QuoteFormatter quoteFormatter(AppConfig config) => QuoteFormatter(config);

  /// Runtime arguments reach a generated provider through `@params`.
  ///
  /// Resolved as `resolve<String>(named: 'instrumentTitle', params: 'BTCUSD')`.
  /// Tolerates an unknown ticker, because a deep link can carry one.
  @provide()
  @named('instrumentTitle')
  String instrumentTitle(
    InstrumentUniverse universe,
    @params() dynamic params,
  ) => universe
      .find(params as String)
      .match(() => 'Unknown instrument', (instrument) => instrument.title);
}
