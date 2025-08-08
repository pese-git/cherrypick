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
///
/// ### Example: Opening a root scope and installing modules
/// ```dart
/// class AppModule extends Module {
///   @override
///   void builder(Scope scope) {
///     scope.bind<Service>().toProvide(() => ServiceImpl());
///   }
/// }
///
/// final root = CherryPick.openRootScope();
/// root.installModules([AppModule()]);
/// final service = root.resolve<Service>();
/// ```
class CherryPick {
  static Scope? _rootScope;

  /// Sets the global logger for all [Scope]s created by CherryPick.
  ///
  /// Allows customizing log output and DI diagnostics globally.
  ///
  /// Example:
  /// ```dart
  /// CherryPick.setGlobalLogger(DefaultLogger());
  /// ```
  static void setGlobalLogger(CherryPickLogger logger) {
    _globalLogger = logger;
  }

  /// Returns the current global logger used by CherryPick.
  static CherryPickLogger get globalLogger => _globalLogger;

  /// Returns the singleton root [Scope], creating it if needed.
  ///
  /// Applies configured [globalLogger] and cycle detection settings.
  ///
  /// Example:
  /// ```dart
  /// final root = CherryPick.openRootScope();
  /// ```
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
  ///
  /// Call before tests or when needing full re-initialization.
  ///
  /// Example:
  /// ```dart
  /// CherryPick.closeRootScope();
  /// ```
  static void closeRootScope() {
    _rootScope = null;
  }

  /// Globally enables cycle detection for all new [Scope]s created by CherryPick.
  ///
  /// Strongly recommended for safety in all projects.
  ///
  /// Example:
  /// ```dart
  /// CherryPick.enableGlobalCycleDetection();
  /// ```
  static void enableGlobalCycleDetection() {
    _globalCycleDetectionEnabled = true;
    if (_rootScope != null) {
      _rootScope!.enableCycleDetection();
    }
  }

  /// Disables global local cycle detection. Existing and new scopes won't check for local cycles.
  ///
  /// Example:
  /// ```dart
  /// CherryPick.disableGlobalCycleDetection();
  /// ```
  static void disableGlobalCycleDetection() {
    _globalCycleDetectionEnabled = false;
    if (_rootScope != null) {
      _rootScope!.disableCycleDetection();
    }
  }

  /// Returns `true` if global local cycle detection is enabled.
  static bool get isGlobalCycleDetectionEnabled => _globalCycleDetectionEnabled;

  /// Enables cycle detection for a particular scope tree.
  ///
  /// [scopeName] - hierarchical string path (e.g. 'feature.api'), or empty for root.
  /// [separator] - path separator (default: '.'), e.g. '/' for "feature/api/module"
  ///
  /// Example:
  /// ```dart
  /// CherryPick.enableCycleDetectionForScope(scopeName: 'api.feature');
  /// ```
  static void enableCycleDetectionForScope({String scopeName = '', String separator = '.'}) {
    final scope = _getScope(scopeName, separator);
    scope.enableCycleDetection();
  }

  /// Disables cycle detection for a given scope. See [enableCycleDetectionForScope].
  static void disableCycleDetectionForScope({String scopeName = '', String separator = '.'}) {
    final scope = _getScope(scopeName, separator);
    scope.disableCycleDetection();
  }

  /// Returns `true` if cycle detection is enabled for the requested scope.
  ///
  /// Example:
  /// ```dart
  /// CherryPick.isCycleDetectionEnabledForScope(scopeName: 'feature.api');
  /// ```
  static bool isCycleDetectionEnabledForScope({String scopeName = '', String separator = '.'}) {
    final scope = _getScope(scopeName, separator);
    return scope.isCycleDetectionEnabled;
  }

  /// Returns the current dependency resolution chain inside the given scope.
  ///
  /// Useful for diagnostics (to print what types are currently resolving).
  ///
  /// Example:
  /// ```dart
  /// print(CherryPick.getCurrentResolutionChain(scopeName: 'feature.api'));
  /// ```
  static List<String> getCurrentResolutionChain({String scopeName = '', String separator = '.'}) {
    final scope = _getScope(scopeName, separator);
    return scope.currentResolutionChain;
  }

  /// Opens the root scope and enables local cycle detection.
  ///
  /// Example:
  /// ```dart
  /// final safeRoot = CherryPick.openSafeRootScope();
  /// ```
  static Scope openSafeRootScope() {
    final scope = openRootScope();
    scope.enableCycleDetection();
    return scope;
  }

  /// Opens a named/nested scope and enables local cycle detection for it.
  ///
  /// Example:
  /// ```dart
  /// final api = CherryPick.openSafeScope(scopeName: 'feature.api');
  /// ```
  static Scope openSafeScope({String scopeName = '', String separator = '.'}) {
    final scope = openScope(scopeName: scopeName, separator: separator);
    scope.enableCycleDetection();
    return scope;
  }

  /// Returns a [Scope] by path (or the root if none specified).
  /// Used for internal diagnostics & helpers.
  static Scope _getScope(String scopeName, String separator) {
    if (scopeName.isEmpty) {
      return openRootScope();
    }
    return openScope(scopeName: scopeName, separator: separator);
  }

  /// Opens (and creates nested subscopes if needed) a scope by hierarchical path.
  ///
  /// [scopeName] - dot-separated path ("api.feature"). Empty = root.
  /// [separator] - path delimiter (default: '.')
  ///
  /// Applies global cycle detection settings to the returned scope.
  ///
  /// Example:
  /// ```dart
  /// final apiScope = CherryPick.openScope(scopeName: 'network.super.api');
  /// ```
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

  /// Closes a named or root scope (if [scopeName] is omitted).
  ///
  /// [scopeName] - dot-separated hierarchical path (e.g. 'api.feature'). Empty = root.
  /// [separator] - path delimiter.
  ///
  /// Example:
  /// ```dart
  /// CherryPick.closeScope(scopeName: 'network.super.api');
  /// ```
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

  /// Enables cross-scope cycle detection globally.
  ///
  /// This will activate detection of cycles that may span across multiple scopes
  /// in the entire dependency graph. All new and existing [Scope]s will participate.
  ///
  /// Strongly recommended for complex solutions with modular architecture.
  ///
  /// Example:
  /// ```dart
  /// CherryPick.enableGlobalCrossScopeCycleDetection();
  /// ```
  static void enableGlobalCrossScopeCycleDetection() {
    _globalCrossScopeCycleDetectionEnabled = true;
    if (_rootScope != null) {
      _rootScope!.enableGlobalCycleDetection();
    }
  }

  /// Disables global cross-scope cycle detection.
  ///
  /// Existing and new scopes stop checking for global (cross-scope) cycles.
  /// The internal global cycle detector will be cleared as well.
  ///
  /// Example:
  /// ```dart
  /// CherryPick.disableGlobalCrossScopeCycleDetection();
  /// ```
  static void disableGlobalCrossScopeCycleDetection() {
    _globalCrossScopeCycleDetectionEnabled = false;
    if (_rootScope != null) {
      _rootScope!.disableGlobalCycleDetection();
    }
    GlobalCycleDetector.instance.clear();
  }

  /// Returns `true` if global cross-scope cycle detection is enabled.
  ///
  /// Example:
  /// ```dart
  /// if (CherryPick.isGlobalCrossScopeCycleDetectionEnabled) {
  ///   print('Global cross-scope detection is ON');
  /// }
  /// ```
  static bool get isGlobalCrossScopeCycleDetectionEnabled => _globalCrossScopeCycleDetectionEnabled;

  /// Returns the current global dependency resolution chain (across all scopes).
  ///
  /// Shows the cross-scope resolution stack, which is useful for advanced diagnostics
  /// and debugging cycle issues that occur between scopes.
  ///
  /// Example:
  /// ```dart
  /// print(CherryPick.getGlobalResolutionChain());
  /// ```
  static List<String> getGlobalResolutionChain() {
    return GlobalCycleDetector.instance.globalResolutionChain;
  }

  /// Clears the global cross-scope cycle detector.
  ///
  /// Useful in tests or when resetting application state.
  ///
  /// Example:
  /// ```dart
  /// CherryPick.clearGlobalCycleDetector();
  /// ```
  static void clearGlobalCycleDetector() {
    GlobalCycleDetector.reset();
  }

  /// Opens the root scope with both local and global cross-scope cycle detection enabled.
  ///
  /// This is the safest way to start IoC for most apps — cycles will be detected
  /// both inside a single scope and between scopes.
  ///
  /// Example:
  /// ```dart
  /// final root = CherryPick.openGlobalSafeRootScope();
  /// ```
  static Scope openGlobalSafeRootScope() {
    final scope = openRootScope();
    scope.enableCycleDetection();
    scope.enableGlobalCycleDetection();
    return scope;
  }

  /// Opens the given named/nested scope and enables both local and cross-scope cycle detection on it.
  ///
  /// Recommended when creating feature/module scopes in large apps.
  ///
  /// Example:
  /// ```dart
  /// final featureScope = CherryPick.openGlobalSafeScope(scopeName: 'featureA.api');
  /// ```
  static Scope openGlobalSafeScope({String scopeName = '', String separator = '.'}) {
    final scope = openScope(scopeName: scopeName, separator: separator);
    scope.enableCycleDetection();
    scope.enableGlobalCycleDetection();
    return scope;
  }
}