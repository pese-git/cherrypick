import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/failure.dart';

part 'app_config.freezed.dart';

/// Configuration resolved before the first frame.
@freezed
abstract class AppConfig with _$AppConfig {
  const factory AppConfig({
    required String environment,
    required Duration tickInterval,
    required int historyLength,
  }) = _AppConfig;

  /// Used when the config service does not answer — see [fetchRemoteConfig].
  static const AppConfig offline = AppConfig(
    environment: 'offline',
    tickInterval: Duration(milliseconds: 900),
    historyLength: 60,
  );
}

/// Pretends to fetch configuration from a remote service.
///
/// Returns a [TaskEither]: a *description* of asynchronous work that may fail,
/// not the work itself. Nothing happens until someone calls `.run()` — which
/// here is the DI binding's job, not this function's.
TaskEither<AppFailure, AppConfig> fetchRemoteConfig() =>
    TaskEither.tryCatch(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return const AppConfig(
        environment: 'web-demo',
        tickInterval: Duration(milliseconds: 700),
        historyLength: 60,
      );
    }, (error, _) => AppFailure.unavailable('Remote config ($error)'));
