//
// Copyright 2021 Sergey Penkovsky (sergey.penkovsky@gmail.com)
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//      https://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import 'dart:async';
import 'dart:collection';
import 'package:cherrypick/src/observer.dart';

/// Exception thrown when a circular dependency is detected during dependency resolution.
///
/// Contains a [message] and the [dependencyChain] showing the resolution cycle.
///
/// Example diagnostic:
/// ```
/// CircularDependencyException: Circular dependency detected for A
/// Dependency chain: A -> B -> C -> A
/// ```
class CircularDependencyException implements Exception {
  final String message;
  final List<String> dependencyChain;

  CircularDependencyException(this.message, this.dependencyChain);

  @override
  String toString() {
    final chain = dependencyChain.join(' -> ');
    return 'CircularDependencyException: $message\nDependency chain: $chain';
  }
}

/// One link of a resolution chain: a dependency key and the chain it extends.
///
/// Chains are immutable and shared — extending one allocates a single link that
/// points at the existing chain instead of copying it, so nesting a resolve
/// costs the same whatever the depth. Links are only ever materialised into a
/// [List] for diagnostics and for the exception message.
class _ChainLink {
  final String key;
  final _ChainLink? parent;

  _ChainLink(this.key, this.parent);

  /// Whether [candidate] is anywhere in this chain.
  bool contains(String candidate) {
    for (_ChainLink? link = this; link != null; link = link.parent) {
      if (link.key == candidate) return true;
    }
    return false;
  }

  /// The chain outermost first.
  List<String> toList() {
    final keys = <String>[];
    for (_ChainLink? link = this; link != null; link = link.parent) {
      keys.add(link.key);
    }
    return keys.reversed.toList();
  }
}

/// Builds the key a dependency is tracked under: its type, plus the qualifier
/// when the binding is named.
///
/// Shared so the generic ([CycleDetector.startResolving]) and reified
/// ([CycleDetectionMixin.withCycleDetection]) entry points cannot drift apart.
String _dependencyKeyFor(Type type, String? named) {
  final typeName = type.toString();
  return named != null ? '$typeName@$named' : typeName;
}

/// Circular dependency detector for CherryPick DI containers.
///
/// Tracks dependency resolution chains to detect and prevent infinite recursion caused by cycles.
/// Whenever a resolve chain re-enters a started dependency, a [CircularDependencyException] is thrown with the full chain.
///
/// This class is used internally, but you can interact with it through [CycleDetectionMixin].
///
/// Example usage (pseudocode):
/// ```dart
/// final detector = CycleDetector(observer: myObserver);
/// try {
///   detector.startResolving<A>();
///   // ... resolving A which depends on B, etc
///   detector.startResolving<B>();
///   detector.startResolving<A>(); // BOOM: throws exception
/// } finally {
///   detector.finishResolving<B>();
///   detector.finishResolving<A>();
/// }
/// ```
class CycleDetector {
  final CherryPickObserver _observer;

  /// Chain bracketed by hand through [startResolving] / [finishResolving].
  ///
  /// That API hands the bracketing to the caller, so its chain has to live in
  /// the detector. [runGuarded] does not use it — see [_chainZoneKey].
  final Set<String> _resolutionStack = HashSet<String>();
  final List<String> _resolutionHistory = [];

  /// Zone key under which [runGuarded] keeps the chain it is resolving.
  ///
  /// The chain belongs in the [Zone] rather than in a field because a
  /// resolution is not confined to one synchronous call: an async provider
  /// suspends at every `await`, and a field-based stack must be popped when the
  /// provider *returns its future* — which happens before it has resolved
  /// anything at all. A zone value survives that suspension, is inherited by
  /// every continuation the resolution spawns, and stays invisible to other
  /// resolutions running concurrently beside it.
  final Object _chainZoneKey = Object();

  CycleDetector({required CherryPickObserver observer}) : _observer = observer;

  /// Chain of the resolution running on this call path, innermost link first.
  /// Null outside [runGuarded].
  _ChainLink? get _zoneChain => Zone.current[_chainZoneKey] as _ChainLink?;

  /// Starts tracking dependency resolution for type [T] and optional [named] qualifier.
  ///
  /// Throws [CircularDependencyException] if a cycle is found.
  void startResolving<T>({String? named}) {
    final dependencyKey = _createDependencyKey<T>(named);
    _observer.onDiagnostic(
      'CycleDetector startResolving: $dependencyKey',
      details: {
        'event': 'startResolving',
        'stackSize': _resolutionStack.length,
      },
    );
    _throwIfResolving(dependencyKey);
    _resolutionStack.add(dependencyKey);
    _resolutionHistory.add(dependencyKey);
  }

  /// Stops tracking dependency resolution for type [T] and optional [named] qualifier.
  /// Should always be called after [startResolving], including for errors.
  void finishResolving<T>({String? named}) {
    final dependencyKey = _createDependencyKey<T>(named);
    _observer.onDiagnostic(
      'CycleDetector finishResolving: $dependencyKey',
      details: {'event': 'finishResolving'},
    );
    _resolutionStack.remove(dependencyKey);
    // Only remove from history if it's the last one
    if (_resolutionHistory.isNotEmpty &&
        _resolutionHistory.last == dependencyKey) {
      _resolutionHistory.removeLast();
    }
  }

  /// Runs [action] with [dependencyKey] appended to the zone-scoped resolution
  /// chain, throwing [CircularDependencyException] if it is already there.
  ///
  /// Unlike [startResolving] / [finishResolving] there is no pop: the chain is
  /// carried by a forked [Zone], so it covers the whole logical resolution —
  /// including everything that happens after an `await` inside [action] — and
  /// unwinds by itself once that zone falls out of use. This is what makes
  /// detection work for asynchronous providers, and why two resolutions running
  /// at the same time cannot be mistaken for a cycle in each other.
  ///
  /// [action] may return a value or a [Future]; nothing is awaited here, since
  /// the zone, not the call, is what delimits the chain.
  R runGuarded<R>(String dependencyKey, R Function() action) {
    final chain = _zoneChain;
    if (_resolutionStack.contains(dependencyKey) ||
        (chain?.contains(dependencyKey) ?? false)) {
      _throwCycle(dependencyKey);
    }
    return Zone.current.fork(zoneValues: {
      _chainZoneKey: _ChainLink(dependencyKey, chain)
    }).run(action);
  }

  /// Throws [CircularDependencyException] if [dependencyKey] is already being
  /// resolved — in the manually bracketed chain or in the zone-scoped one.
  void _throwIfResolving(String dependencyKey) {
    if (_resolutionStack.contains(dependencyKey) ||
        (_zoneChain?.contains(dependencyKey) ?? false)) {
      _throwCycle(dependencyKey);
    }
  }

  /// Reports the cycle ending at [dependencyKey] and throws.
  Never _throwCycle(String dependencyKey) {
    final chain = currentResolutionChain;
    final cycleStart = chain.indexOf(dependencyKey);
    final cycle = [
      ...cycleStart < 0 ? chain : chain.sublist(cycleStart),
      dependencyKey,
    ];
    _observer.onCycleDetected(cycle);
    _observer.onError('Cycle detected for $dependencyKey', null, null);
    throw CircularDependencyException(
      'Circular dependency detected for $dependencyKey',
      cycle,
    );
  }

  /// Clears the manually bracketed resolution state.
  ///
  /// Chains created by [runGuarded] are scoped to their zone and unwind on
  /// their own, so there is nothing to clear for them — and nothing this could
  /// clear, since a zone value is not reachable from outside its zone.
  void clear() {
    _observer.onDiagnostic(
      'CycleDetector clear',
      details: {
        'event': 'clear',
        'description': 'resolution stack cleared',
      },
    );
    _resolutionStack.clear();
    _resolutionHistory.clear();
  }

  /// Returns true if dependency [T] (and [named], if specified) is being resolved right now.
  bool isResolving<T>({String? named}) {
    final dependencyKey = _createDependencyKey<T>(named);
    return _resolutionStack.contains(dependencyKey) ||
        (_zoneChain?.contains(dependencyKey) ?? false);
  }

  /// Gets the current dependency resolution chain (for diagnostics or debugging).
  ///
  /// Concatenates the manually bracketed chain with the zone-scoped chain of
  /// the resolution running on this call path, so reading it from inside a
  /// provider — including after an `await` — shows how that provider was
  /// reached.
  List<String> get currentResolutionChain =>
      List.unmodifiable([..._resolutionHistory, ...?_zoneChain?.toList()]);

  /// Returns a unique string key for type [T] (+name).
  String _createDependencyKey<T>(String? named) => _dependencyKeyFor(T, named);
}

/// Mixin for adding circular dependency detection support to custom DI containers/classes.
///
/// Fields:
///   - `observer`: must be implemented by your class (used for diagnostics and error reporting)
///
/// Example usage:
/// ```dart
/// class MyContainer with CycleDetectionMixin {
///   @override
///   CherryPickObserver get observer => myObserver;
/// }
///
/// final c = MyContainer();
/// c.enableCycleDetection();
/// c.withCycleDetection(String, null, () {
///   // ... dependency resolution code
/// });
/// ```
mixin CycleDetectionMixin {
  CycleDetector? _cycleDetector;
  CherryPickObserver get observer;

  /// Turns on circular dependency detection for this class/container.
  void enableCycleDetection() {
    _cycleDetector = CycleDetector(observer: observer);
    observer.onDiagnostic(
      'CycleDetection enabled',
      details: {
        'event': 'enable',
        'description': 'cycle detection enabled',
      },
    );
  }

  /// Shuts off detection and clears any cycle history for this container.
  void disableCycleDetection() {
    _cycleDetector?.clear();
    observer.onDiagnostic(
      'CycleDetection disabled',
      details: {
        'event': 'disable',
        'description': 'cycle detection disabled',
      },
    );
    _cycleDetector = null;
  }

  /// Returns true if detection is currently enabled.
  bool get isCycleDetectionEnabled => _cycleDetector != null;

  /// Executes [action] while tracking for circular DI cycles for [dependencyType] and [named].
  ///
  /// Throws [CircularDependencyException] if a dependency cycle is detected.
  ///
  /// Example:
  /// ```dart
  /// withCycleDetection(String, 'api', () => resolveApi());
  /// ```
  T withCycleDetection<T>(
    Type dependencyType,
    String? named,
    T Function() action,
  ) {
    final detector = _cycleDetector;
    if (detector == null) {
      return action();
    }
    return detector.runGuarded(
      _dependencyKeyFor(dependencyType, named),
      action,
    );
  }

  /// Gets the current active dependency resolution chain.
  List<String> get currentResolutionChain =>
      _cycleDetector?.currentResolutionChain ?? [];
}
