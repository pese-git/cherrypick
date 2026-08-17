import 'package:fpdart/fpdart.dart';

import '../entity/instrument.dart';
import '../failure.dart';

/// Loads the instrument universe and per-symbol price history.
///
/// Both methods return [TaskEither] rather than a bare `Future`: failure is
/// part of the signature, so a caller cannot accidentally ignore it, and the
/// work is deferred until `.run()`.
abstract class InstrumentRepository {
  /// Instrument universe, awaited once during bootstrap.
  TaskEither<AppFailure, List<Instrument>> loadAll();

  /// Warm-up history for [symbol], awaited when a market tab opens.
  TaskEither<AppFailure, List<double>> loadHistory(String symbol);
}
