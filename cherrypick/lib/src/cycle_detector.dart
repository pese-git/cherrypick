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
  final Set<String> _resolutionStack = HashSet<String>();
  final List<String> _resolutionHistory = [];

  CycleDetector({required CherryPickObserver observer}) : _observer = observer;

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
    if (_resolutionStack.contains(dependencyKey)) {
      final cycleStartIndex = _resolutionHistory.indexOf(dependencyKey);
      final cycle = _resolutionHistory.sublist(cycleStartIndex)..add(dependencyKey);
      _observer.onCycleDetected(cycle);
      _observer.onError('Cycle detected for $dependencyKey', null, null);
      throw CircularDependencyException(
        'Circular dependency detected for $dependencyKey',
        cycle,
      );
    }
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
    if (_resolutionHistory.isNotEmpty && _resolutionHistory.last == dependencyKey) {
      _resolutionHistory.removeLast();
    }
  }

  /// Clears all resolution state and resets the cycle detector.
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
    return _resolutionStack.contains(dependencyKey);
  }

  /// Gets the current dependency resolution chain (for diagnostics or debugging).
  List<String> get currentResolutionChain => List.unmodifiable(_resolutionHistory);

  /// Returns a unique string key for type [T] (+name).
  String _createDependencyKey<T>(String? named) {
    final typeName = T.toString();
    return named != null ? '$typeName@$named' : typeName;
  }
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
    if (_cycleDetector == null) {
      return action();
    }

    final dependencyKey = named != null 
        ? '${dependencyType.toString()}@$named' 
        : dependencyType.toString();

    if (_cycleDetector!._resolutionStack.contains(dependencyKey)) {
      final cycleStartIndex = _cycleDetector!._resolutionHistory.indexOf(dependencyKey);
      final cycle = _cycleDetector!._resolutionHistory.sublist(cycleStartIndex)
        ..add(dependencyKey);
      observer.onCycleDetected(cycle);
      observer.onError('Cycle detected for $dependencyKey', null, null);
      throw CircularDependencyException(
        'Circular dependency detected for $dependencyKey',
        cycle,
      );
    }

    _cycleDetector!._resolutionStack.add(dependencyKey);
    _cycleDetector!._resolutionHistory.add(dependencyKey);

    try {
      return action();
    } finally {
      _cycleDetector!._resolutionStack.remove(dependencyKey);
      if (_cycleDetector!._resolutionHistory.isNotEmpty && 
          _cycleDetector!._resolutionHistory.last == dependencyKey) {
        _cycleDetector!._resolutionHistory.removeLast();
      }
    }
  }

  /// Gets the current active dependency resolution chain.
  List<String> get currentResolutionChain => 
      _cycleDetector?.currentResolutionChain ?? [];
}
