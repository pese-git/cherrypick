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
import 'package:cherrypick/cherrypick.dart';

/// GlobalCycleDetector detects and prevents circular dependencies across an entire DI scope hierarchy.
///
/// This is particularly important for modular/feature-based applications
/// where subscopes can introduce indirect cycles that span different scopes.
///
/// The detector tracks resolution chains and throws [CircularDependencyException]
/// when a cycle is found, showing the full chain (including scope context).
///
/// Example usage via [GlobalCycleDetectionMixin]:
/// ```dart
/// class MyScope with GlobalCycleDetectionMixin { /* ... */ }
///
/// final scope = MyScope();
/// scope.setScopeId('feature');
/// scope.enableGlobalCycleDetection();
///
/// scope.withGlobalCycleDetection(String, null, () {
///   // ... resolve dependencies here, will detect cross-scope cycles
/// });
/// ```
class GlobalCycleDetector {
  static GlobalCycleDetector? _instance;

  final CherryPickObserver _observer;

  /// Chain bracketed by hand through [startGlobalResolving] /
  /// [finishGlobalResolving]. [withGlobalCycleDetection] uses the zone-scoped
  /// chain instead — see [_chainZoneKey].
  final Set<String> _globalResolutionStack = HashSet<String>();
  final List<String> _globalResolutionHistory = [];

  /// Zone key under which [withGlobalCycleDetection] keeps the cross-scope
  /// chain it is resolving.
  ///
  /// A single detector serves the whole scope tree, so a field-based stack is
  /// shared by every resolution in the process at once: one async resolution
  /// suspending at an `await` would leave its entries visible to unrelated
  /// resolutions, and the pop that removes them runs as soon as the provider
  /// returns its future rather than when it completes. Keeping the chain in the
  /// [Zone] ties it to one logical resolution instead — it follows that
  /// resolution across scopes and across `await`s, and no other sees it.
  final Object _chainZoneKey = Object();

  // Map of active detectors for subscopes (rarely used directly)
  final Map<String, CycleDetector> _scopeDetectors =
      HashMap<String, CycleDetector>();

  GlobalCycleDetector._internal({required CherryPickObserver observer})
      : _observer = observer;

  /// Cross-scope chain of the resolution running on this call path, outermost
  /// first. Empty outside [withGlobalCycleDetection].
  List<String> get _zoneChain =>
      (Zone.current[_chainZoneKey] as List<String>?) ?? const <String>[];

  /// Same chain, as the raw list stored in the zone (null outside a resolution),
  /// so the hot path can test membership without allocating.
  List<String>? get _rawZoneChain =>
      Zone.current[_chainZoneKey] as List<String>?;

  /// Returns the singleton global detector instance, initializing it if needed.
  static GlobalCycleDetector get instance {
    _instance ??=
        GlobalCycleDetector._internal(observer: CherryPick.globalObserver);
    return _instance!;
  }

  /// Reset internal state (useful for testing).
  static void reset() {
    _instance?._globalResolutionStack.clear();
    _instance?._globalResolutionHistory.clear();
    _instance?._scopeDetectors.clear();
    _instance = null;
  }

  /// Start tracking resolution of dependency [T] with optional [named] and [scopeId].
  /// Throws [CircularDependencyException] on cycle.
  void startGlobalResolving<T>({String? named, String? scopeId}) {
    final dependencyKey = _createDependencyKeyFromType(T, named, scopeId);

    _throwIfResolving(dependencyKey, scopeId);
    _globalResolutionStack.add(dependencyKey);
    _globalResolutionHistory.add(dependencyKey);
  }

  /// Finish tracking a dependency. Should always be called after [startGlobalResolving].
  void finishGlobalResolving<T>({String? named, String? scopeId}) {
    final dependencyKey = _createDependencyKeyFromType(T, named, scopeId);
    _globalResolutionStack.remove(dependencyKey);

    if (_globalResolutionHistory.isNotEmpty &&
        _globalResolutionHistory.last == dependencyKey) {
      _globalResolutionHistory.removeLast();
    }
  }

  /// Internally execute [action] with global cycle detection for [dependencyType], [named], [scopeId].
  /// Throws [CircularDependencyException] on cycle.
  T withGlobalCycleDetection<T>(
    Type dependencyType,
    String? named,
    String? scopeId,
    T Function() action,
  ) {
    final dependencyKey =
        _createDependencyKeyFromType(dependencyType, named, scopeId);
    final chain = _rawZoneChain;
    if (_globalResolutionStack.contains(dependencyKey) ||
        (chain != null && chain.contains(dependencyKey))) {
      _throwCycle(dependencyKey, scopeId);
    }
    return Zone.current.fork(zoneValues: {
      _chainZoneKey: <String>[...?chain, dependencyKey],
    }).run(action);
  }

  /// Throws [CircularDependencyException] if [dependencyKey] is already being
  /// resolved — in the manually bracketed chain or in the zone-scoped one.
  void _throwIfResolving(String dependencyKey, String? scopeId) {
    if (_globalResolutionStack.contains(dependencyKey) ||
        _zoneChain.contains(dependencyKey)) {
      _throwCycle(dependencyKey, scopeId);
    }
  }

  /// Reports the cross-scope cycle ending at [dependencyKey] and throws.
  Never _throwCycle(String dependencyKey, String? scopeId) {
    final chain = globalResolutionChain;
    final cycleStart = chain.indexOf(dependencyKey);
    final cycle = [
      ...cycleStart < 0 ? chain : chain.sublist(cycleStart),
      dependencyKey,
    ];
    _observer.onCycleDetected(cycle, scopeName: scopeId);
    _observer.onError(
        'Global circular dependency detected for $dependencyKey', null, null);
    throw CircularDependencyException(
      'Global circular dependency detected for $dependencyKey',
      cycle,
    );
  }

  /// Get per-scope detector (not usually needed by consumers).
  CycleDetector getScopeDetector(String scopeId) {
    return _scopeDetectors.putIfAbsent(
        scopeId, () => CycleDetector(observer: CherryPick.globalObserver));
  }

  /// Remove detector for a given scope.
  void removeScopeDetector(String scopeId) {
    _scopeDetectors.remove(scopeId);
  }

  /// Returns true if dependency [T] is currently being resolved in the global scope.
  bool isGloballyResolving<T>({String? named, String? scopeId}) {
    final dependencyKey = _createDependencyKeyFromType(T, named, scopeId);
    return _globalResolutionStack.contains(dependencyKey) ||
        _zoneChain.contains(dependencyKey);
  }

  /// Get current global dependency resolution chain (for debugging or diagnostics).
  ///
  /// Concatenates the manually bracketed chain with the zone-scoped chain of
  /// the resolution running on this call path.
  List<String> get globalResolutionChain =>
      List.unmodifiable([..._globalResolutionHistory, ..._zoneChain]);

  /// Clears the manually bracketed chain and every per-scope detector.
  ///
  /// Chains created by [withGlobalCycleDetection] are scoped to their zone and
  /// unwind on their own, so there is nothing here to clear for them.
  void clear() {
    _globalResolutionStack.clear();
    _globalResolutionHistory.clear();
    _scopeDetectors.values.forEach(_detectorClear);
    _scopeDetectors.clear();
  }

  void _detectorClear(detector) => detector.clear();

  /// Creates a unique dependency key string including scope and name (for diagnostics/cycle checks).
  String _createDependencyKeyFromType(
      Type type, String? named, String? scopeId) {
    final typeName = type.toString();
    final namePrefix = named != null ? '@$named' : '';
    final scopePrefix = scopeId != null ? '[$scopeId]' : '';
    return '$scopePrefix$typeName$namePrefix';
  }
}

/// Enhanced mixin for global circular dependency detection, to be mixed into
/// DI scopes or containers that want cross-scope protection.
///
/// Typical usage pattern:
/// ```dart
/// class MySubscope with GlobalCycleDetectionMixin { ... }
///
/// final scope = MySubscope();
/// scope.setScopeId('user_profile');
/// scope.enableGlobalCycleDetection();
///
/// scope.withGlobalCycleDetection(UserService, null, () {
///   // ... resolve user service and friends, auto-detects global cycles
/// });
/// ```
mixin GlobalCycleDetectionMixin {
  String? _scopeId;
  bool _globalCycleDetectionEnabled = false;

  /// Set the scope's unique identifier for global tracking (should be called at scope initialization).
  void setScopeId(String scopeId) {
    _scopeId = scopeId;
  }

  /// Get the scope's id, if configured.
  String? get scopeId => _scopeId;

  /// Enable global cross-scope circular dependency detection.
  void enableGlobalCycleDetection() {
    _globalCycleDetectionEnabled = true;
  }

  /// Disable global cycle detection (no cycle checks will be performed globally).
  void disableGlobalCycleDetection() {
    _globalCycleDetectionEnabled = false;
  }

  /// Returns true if global cycle detection is currently enabled for this scope/container.
  bool get isGlobalCycleDetectionEnabled => _globalCycleDetectionEnabled;

  /// Executes [action] with global cycle detection for [dependencyType] and [named].
  /// Throws [CircularDependencyException] if a cycle is detected.
  ///
  /// Example:
  /// ```dart
  /// withGlobalCycleDetection(UserService, null, () => resolveUser());
  /// ```
  T withGlobalCycleDetection<T>(
    Type dependencyType,
    String? named,
    T Function() action,
  ) {
    if (!_globalCycleDetectionEnabled) {
      return action();
    }

    return GlobalCycleDetector.instance.withGlobalCycleDetection<T>(
      dependencyType,
      named,
      _scopeId,
      action,
    );
  }

  /// Access the current global dependency resolution chain for diagnostics.
  List<String> get globalResolutionChain =>
      GlobalCycleDetector.instance.globalResolutionChain;
}
