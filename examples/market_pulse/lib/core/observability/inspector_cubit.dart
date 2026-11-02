import 'dart:async';

import 'package:cherrypick/cherrypick.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'di_event.dart';

part 'inspector_cubit.freezed.dart';

/// Everything the Inspector renders.
@freezed
abstract class InspectorState with _$InspectorState {
  const factory InspectorState({
    @Default(<DiEvent>[]) List<DiEvent> events,
    @Default(<String, ResolveStats>{}) Map<String, ResolveStats> resolveStats,
    @Default(<String>[]) List<String> lastCycle,
    @Default(0) int liveInstances,
  }) = _InspectorState;
}

/// Holds the Inspector's view of the container.
///
/// Fed by [InspectorObserver], which is a separate object for a concrete
/// reason: `BlocBase` already declares `onError(Object, StackTrace)`, and
/// `CherryPickObserver.onError(String, Object?, StackTrace?)` cannot override
/// it. One class cannot be both — so the observer adapts, and this cubit
/// stores.
///
/// **Emission is deferred.** Observer callbacks fire synchronously from inside
/// `resolve()`, and widgets do resolve during `build`. Emitting right there
/// would mark another subtree dirty mid-build, so state is accumulated eagerly
/// and published on a microtask.
class InspectorCubit extends Cubit<InspectorState> implements Disposable {
  final int maxEvents;

  List<DiEvent> _events = const [];
  Map<String, ResolveStats> _stats = const {};
  List<String> _cycle = const [];
  int _live = 0;

  /// Objects already reported for a type, compared by identity.
  ///
  /// Kept out of the state: it exists to answer "have I seen this exact object
  /// before", and nothing renders it.
  final Map<String, Set<Object>> _seen = {};

  bool _publishScheduled = false;

  /// Set to false to stop recording without detaching the observer.
  bool recording = true;

  InspectorCubit({this.maxEvents = 300}) : super(const InspectorState());

  void _publishLater() {
    if (_publishScheduled || isClosed) return;
    _publishScheduled = true;

    scheduleMicrotask(() {
      _publishScheduled = false;
      if (isClosed) return;

      emit(
        InspectorState(
          events: _events,
          resolveStats: _stats,
          lastCycle: _cycle,
          liveInstances: _live,
        ),
      );
    });
  }

  /// Appends one line to the event feed.
  void push(DiEventKind kind, String message, {String? scopeName}) {
    if (!recording || isClosed) return;

    final next = [
      DiEvent(
        kind: kind,
        message: message,
        scopeName: scopeName,
        at: DateTime.now(),
      ),
      ..._events,
    ];
    _events = List.unmodifiable(
      next.length > maxEvents ? next.sublist(0, maxEvents) : next,
    );

    _publishLater();
  }

  /// Records a resolve and reports whether this object is one we had not seen.
  ///
  /// Identity is the signal: the container reports every successful resolve,
  /// not only construction, so a repeated instance means reuse.
  bool recordResolve(Type type, Object instance) {
    final typeName = type.toString();
    final seen = _seen.putIfAbsent(typeName, Set<Object>.identity);
    final isNew = seen.add(instance);

    final previous = _stats[typeName] ?? ResolveStats(typeName: typeName);
    _stats = Map.unmodifiable({
      ..._stats,
      typeName: previous.copyWith(
        resolves: previous.resolves + 1,
        instances: isNew ? previous.instances + 1 : previous.instances,
      ),
    });

    if (isNew) _live++;
    return isNew;
  }

  /// Records that the container disposed an instance.
  void recordDispose() {
    if (_live > 0) _live--;
  }

  /// Stores the chain of the most recent circular dependency.
  void recordCycle(List<String> chain) => _cycle = List.unmodifiable(chain);

  /// Clears the feed and every counter — the Inspector's "clear" button.
  void reset() {
    _events = const [];
    _stats = const {};
    _seen.clear();
    _cycle = const [];
    _live = 0;
    _publishLater();
  }

  /// Bridges CherryPick's [Disposable] to `Cubit.close()`.
  @override
  Future<void> dispose() => close();
}
