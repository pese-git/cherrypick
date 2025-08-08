//
// Copyright 2021 Sergey Penkovsky (sergey.penkovsky@gmail.com)
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//      http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import 'package:cherrypick/src/scope.dart';
import 'package:cherrypick/src/global_cycle_detector.dart';
import 'package:cherrypick/src/logger.dart';
import 'package:meta/meta.dart';

/// Global logger for all [Scope]s managed by [CherryPick].
///
/// Defaults to [SilentLogger] unless set via [setGlobalLogger].
CherryPickLogger _globalLogger = const SilentLogger();

/// Whether global local-cycle detection is enabled for all Scopes ([Scope.enableCycleDetection]).
bool _globalCycleDetectionEnabled = false;

/// Whether global cross-scope cycle detection is enabled ([Scope.enableGlobalCycleDetection]).
bool _globalCrossScopeCycleDetectionEnabled = false;

/// Static facade for managing dependency graph, root scope, subscopes, logger, and global settings in the CherryPick DI container.
///
/// - Provides a singleton root scope for simple integration.
/// - Supports hierarchical/named subscopes by string path.
/// - Manages global/protected logging and DI diagnostics.
/// - Suitable for most application & CLI scenarios. For test isolation, manually create [Scope]s instead.
class CherryPick {
  static Scope? _rootScope;

  /// Sets the global logger for all subsequent [Scope]s created by [CherryPick].
  ///
  /// [logger] The logger implementation to use (see [SilentLogger], [DefaultLogger], etc).
  static void setGlobalLogger(CherryPickLogger logger) {
    _globalLogger = logger;
  }

  /// Returns the current global logger used by [CherryPick].
  static CherryPickLogger get globalLogger => _globalLogger;

  /// Returns the singleton root [Scope], creating it if needed.
  ///
  /// Uses the current [globalLogger], and applies global cycle detection flags if enabled.
  /// Call [closeRootScope] to dispose and reset the singleton.
  static Scope openRootScope() {
    _rootScope ??= Scope(null, logger: _globalLogger);
    // Apply cycle detection settings
    if (_globalCycleDetectionEnabled && !_rootScope!.isCycleDetectionEnabled) {
      _rootScope!.enableCycleDetection();
    }
    if (_globalCrossScopeCycleDetectionEnabled && !_rootScope!.isGlobalCycleDetectionEnabled) {
      _rootScope!.enableGlobalCycleDetection();
    }
    return _rootScope!;
  }

  /// Disposes and resets the root [Scope] singleton.
  /// The next [openRootScope] call will create a new root [Scope].
  static void closeRootScope() {
    _rootScope = null;
  }

  /// Globally enables local cycle detection on all [Scope]s created by [CherryPick].
  ///
  /// Also calls [Scope.enableCycleDetection] on the rootScope (if already created).
  static void enableGlobalCycleDetection() {
    _globalCycleDetectionEnabled = true;
    if (_rootScope != null) {
      _rootScope!.enableCycleDetection();
    }
  }

  /// Disables global local cycle detection.
  static void disableGlobalCycleDetection() {
    _globalCycleDetectionEnabled = false;
    if (_rootScope != null) {
      _rootScope!.disableCycleDetection();
    }
  }

  /// Returns whether global local cycle detection is enabled via [enableGlobalCycleDetection].
  static bool get isGlobalCycleDetectionEnabled => _globalCycleDetectionEnabled;

  /// Enables cycle detection for a specific (possibly nested) [Scope].
  ///
  /// [scopeName] Hierarchical path string ("outer.inner.deeper"),
  /// or empty for root. [separator] custom path delimiter (defaults to '.').
  static void enableCycleDetectionForScope({String scopeName = '', String separator = '.'}) {
    final scope = _getScope(scopeName, separator);
    scope.enableCycleDetection();
  }

  /// Disables cycle detection for a specific Scope.
  static void disableCycleDetectionForScope({String scopeName = '', String separator = '.'}) {
    final scope = _getScope(scopeName, separator);
    scope.disableCycleDetection();
  }

  /// Returns true if cycle detection is enabled for the requested scope.
  static bool isCycleDetectionEnabledForScope({String scopeName = '', String separator = '.'}) {
    final scope = _getScope(scopeName, separator);
    return scope.isCycleDetectionEnabled;
  }

  /// Returns the current dependency resolution chain inside the given scope.
  /// Useful for diagnostics and runtime debugging.
  static List<String> getCurrentResolutionChain({String scopeName = '', String separator = '.'}) {
    final scope = _getScope(scopeName, separator);
    return scope.currentResolutionChain;
  }

  /// Opens [openRootScope] and enables local cycle detection on it.
  static Scope openSafeRootScope() {
    final scope = openRootScope();
    scope.enableCycleDetection();
    return scope;
  }

  /// Opens a scope (by hierarchical name) with local cycle detection enabled.
  static Scope openSafeScope({String scopeName = '', String separator = '.'}) {
    final scope = openScope(scopeName: scopeName, separator: separator);
    scope.enableCycleDetection();
    return scope;
  }

  /// Returns a [Scope] by path (or the rootScope if none specified).
  /// Used internally for diagnostics and utility operations.
  static Scope _getScope(String scopeName, String separator) {
    if (scopeName.isEmpty) {
      return openRootScope();
    }
    return openScope(scopeName: scopeName, separator: separator);
  }

  /// Opens (and creates nested subscopes if needed) a scope by name/path.
  ///
  /// - [scopeName]: Hierarchical dot-separated path (e.g. 'outer.inner.sub'). Empty string is root.
  /// - [separator]: Use a custom string separator (default ".").
  /// - Always applies global cycle detection settings.
  @experimental
  static Scope openScope({String scopeName = '', String separator = '.'}) {
    if (scopeName.isEmpty) {
      return openRootScope();
    }
    final nameParts = scopeName.split(separator);
    if (nameParts.isEmpty) {
      throw Exception('Can not open sub scope because scopeName can not split');
    }
    final scope = nameParts.fold(
      openRootScope(),
      (Scope previous, String element) => previous.openSubScope(element)
    );
    if (_globalCycleDetectionEnabled && !scope.isCycleDetectionEnabled) {
      scope.enableCycleDetection();
    }
    if (_globalCrossScopeCycleDetectionEnabled && !scope.isGlobalCycleDetectionEnabled) {
      scope.enableGlobalCycleDetection();
    }
    return scope;
  }

  /// Closes a named or root scope (if [scopeName] omitted).
  ///
  /// - [scopeName]: Hierarchical dot-separated path (e.g. 'outer.inner.sub'). Empty string is root.
  /// - [separator]: Custom separator for path.
  @experimental
  static void closeScope({String scopeName = '', String separator = '.'}) {
    if (scopeName.isEmpty) {
      closeRootScope();
      return;
    }
    final nameParts = scopeName.split(separator);
    if (nameParts.isEmpty) {
      throw Exception('Can not close sub scope because scopeName can not split');
    }
    if (nameParts.length > 1) {
      final lastPart = nameParts.removeLast();
      final scope = nameParts.fold(
        openRootScope(),
        (Scope previous, String element) => previous.openSubScope(element)
      );
      scope.closeSubScope(lastPart);
    } else {
      openRootScope().closeSubScope(nameParts.first);
    }
  }

  /// Enables cross-scope cycle detection globally. All new and current [Scope]s get this feature.
  static void enableGlobalCrossScopeCycleDetection() {
    _globalCrossScopeCycleDetectionEnabled = true;
    if (_rootScope != null) {
      _rootScope!.enableGlobalCycleDetection();
    }
  }

  /// Disables cross-scope cycle detection globally, and clears the detector.
  static void disableGlobalCrossScopeCycleDetection() {
    _globalCrossScopeCycleDetectionEnabled = false;
    if (_rootScope != null) {
      _rootScope!.disableGlobalCycleDetection();
    }
    GlobalCycleDetector.instance.clear();
  }

  /// Returns whether global cross-scope detection is enabled.
  static bool get isGlobalCrossScopeCycleDetectionEnabled => _globalCrossScopeCycleDetectionEnabled;

  /// Returns the global dependency resolution chain (for diagnostics/cross-scope cycle detection).
  static List<String> getGlobalResolutionChain() {
    return GlobalCycleDetector.instance.globalResolutionChain;
  }

  /// Clears the global cross-scope detector, useful for tests and resets.
  static void clearGlobalCycleDetector() {
    GlobalCycleDetector.reset();
  }

  /// Opens [openRootScope], then enables local and cross-scope cycle detection.
  static Scope openGlobalSafeRootScope() {
    final scope = openRootScope();
    scope.enableCycleDetection();
    scope.enableGlobalCycleDetection();
    return scope;
  }

  /// Opens [openScope] and enables both local and cross-scope cycle detection on the result.
  static Scope openGlobalSafeScope({String scopeName = '', String separator = '.'}) {
    final scope = openScope(scopeName: scopeName, separator: separator);
    scope.enableCycleDetection();
    scope.enableGlobalCycleDetection();
    return scope;
  }
}