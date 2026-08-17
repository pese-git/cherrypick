import 'package:freezed_annotation/freezed_annotation.dart';

part 'di_event.freezed.dart';

/// Kind of DI event, used for colouring and filtering in the Inspector.
enum DiEventKind {
  binding,
  request,
  created,
  reused,
  disposed,
  module,
  scope,
  cacheHit,
  cacheMiss,
  cycle,
  diagnostic,
  warning,
  error,
}

/// One line in the Inspector's event feed.
///
/// A flattened, UI-friendly projection of the `CherryPickObserver` callbacks.
@freezed
abstract class DiEvent with _$DiEvent {
  const factory DiEvent({
    required DiEventKind kind,
    required String message,
    required DateTime at,
    String? scopeName,
  }) = _DiEvent;

  const DiEvent._();

  /// Short label shown in the leading chip.
  String get label => switch (kind) {
    DiEventKind.binding => 'BIND',
    DiEventKind.request => 'REQ',
    DiEventKind.created => 'NEW',
    DiEventKind.reused => 'REUSE',
    DiEventKind.disposed => 'DISPOSE',
    DiEventKind.module => 'MODULE',
    DiEventKind.scope => 'SCOPE',
    DiEventKind.cacheHit => 'HIT',
    DiEventKind.cacheMiss => 'MISS',
    DiEventKind.cycle => 'CYCLE',
    DiEventKind.diagnostic => 'DIAG',
    DiEventKind.warning => 'WARN',
    DiEventKind.error => 'ERROR',
  };
}

/// Per-type resolution counters.
///
/// Immutable on purpose. The Inspector's state is compared by value, so a
/// counter mutated in place would leave the state `==` to the previous one and
/// the cubit would skip the emit — a bug that freezed makes impossible here.
@freezed
abstract class ResolveStats with _$ResolveStats {
  const factory ResolveStats({
    required String typeName,
    @Default(0) int resolves,
    @Default(0) int instances,
  }) = _ResolveStats;

  const ResolveStats._();

  /// Resolves that were served by an object created earlier.
  int get reused => resolves - instances;
}
