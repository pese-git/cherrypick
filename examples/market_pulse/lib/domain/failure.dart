import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Everything that can go wrong in the data layer, as a closed set.
///
/// A union rather than exceptions: the repository returns
/// `TaskEither<AppFailure, T>`, so a caller cannot forget the failure branch —
/// the compiler makes it list every case.
@freezed
sealed class AppFailure with _$AppFailure {
  /// The requested ticker is not in the loaded universe.
  const factory AppFailure.unknownSymbol(String symbol) = UnknownSymbolFailure;

  /// The (simulated) feed or config service did not answer.
  const factory AppFailure.unavailable(String what) = UnavailableFailure;

  const AppFailure._();

  /// Message shown in the UI.
  String get message => switch (this) {
    UnknownSymbolFailure(:final symbol) => 'Unknown symbol: $symbol',
    UnavailableFailure(:final what) => '$what is unavailable',
  };
}
