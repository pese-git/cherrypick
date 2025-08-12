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

/// An abstract Observer for CherryPick DI container events.
///
/// Extend this class to react to and log various events inside the CherryPick Dependency Injection container.
/// Allows monitoring of registration, creation, disposal, module changes, cache hits/misses, cycles, and
/// errors/warnings for improved diagnostics and debugging.
///
/// All methods have detailed event information, including name, type, scope, and other arguments.
///
/// Example: Logging and debugging container events
/// ```dart
/// final CherryPickObserver observer = PrintCherryPickObserver();
/// // Pass observer to CherryPick during setup
/// CherryPick.openRootScope(observer: observer);
/// ```
abstract class CherryPickObserver {
  // === Registration and instance lifecycle ===
  /// Called when a binding is registered within the container (new dependency mapping).
  ///
  /// Example:
  /// ```dart
  /// observer.onBindingRegistered('MyService', MyService, scopeName: 'root');
  /// ```
  void onBindingRegistered(String name, Type type, {String? scopeName});

  /// Called when an instance is requested (before it is created or retrieved from cache).
  ///
  /// Example:
  /// ```dart
  /// observer.onInstanceRequested('MyService', MyService, scopeName: 'root');
  /// ```
  void onInstanceRequested(String name, Type type, {String? scopeName});

  /// Called when a new instance is successfully created.
  ///
  /// Example:
  /// ```dart
  /// observer.onInstanceCreated('MyService', MyService, instance, scopeName: 'root');
  /// ```
  void onInstanceCreated(String name, Type type, Object instance, {String? scopeName});

  /// Called when an instance is disposed (removed from cache and/or finalized).
  ///
  /// Example:
  /// ```dart
  /// observer.onInstanceDisposed('MyService', MyService, instance, scopeName: 'root');
  /// ```
  void onInstanceDisposed(String name, Type type, Object instance, {String? scopeName});

  // === Module events ===
  /// Called when modules are installed into the container.
  ///
  /// Example:
  /// ```dart
  /// observer.onModulesInstalled(['NetworkModule', 'RepositoryModule'], scopeName: 'root');
  /// ```
  void onModulesInstalled(List<String> moduleNames, {String? scopeName});

  /// Called when modules are removed from the container.
  ///
  /// Example:
  /// ```dart
  /// observer.onModulesRemoved(['RepositoryModule'], scopeName: 'root');
  /// ```
  void onModulesRemoved(List<String> moduleNames, {String? scopeName});

  // === Scope lifecycle ===
  /// Called when a new DI scope is opened (for example, starting a new feature or screen).
  ///
  /// Example:
  /// ```dart
  /// observer.onScopeOpened('user-session');
  /// ```
  void onScopeOpened(String name);

  /// Called when an existing DI scope is closed.
  ///
  /// Example:
  /// ```dart
  /// observer.onScopeClosed('user-session');
  /// ```
  void onScopeClosed(String name);

  // === Cycle detection ===
  /// Called if a dependency cycle is detected during resolution.
  ///
  /// Example:
  /// ```dart
  /// observer.onCycleDetected(['A', 'B', 'C', 'A'], scopeName: 'root');
  /// ```
  void onCycleDetected(List<String> chain, {String? scopeName});

  // === Cache events ===
  /// Called when an instance is found in the cache.
  ///
  /// Example:
  /// ```dart
  /// observer.onCacheHit('MyService', MyService, scopeName: 'root');
  /// ```
  void onCacheHit(String name, Type type, {String? scopeName});

  /// Called when an instance is not found in the cache and should be created.
  ///
  /// Example:
  /// ```dart
  /// observer.onCacheMiss('MyService', MyService, scopeName: 'root');
  /// ```
  void onCacheMiss(String name, Type type, {String? scopeName});

  // === Diagnostic ===
  /// Used for custom diagnostic and debug messages.
  ///
  /// Example:
  /// ```dart
  /// observer.onDiagnostic('Cache cleared', details: detailsObj);
  /// ```
  void onDiagnostic(String message, {Object? details});

  // === Warnings & errors ===
  /// Called on non-fatal, recoverable DI container warnings.
  ///
  /// Example:
  /// ```dart
  /// observer.onWarning('Binding override', details: {...});
  /// ```
  void onWarning(String message, {Object? details});

  /// Called on error (typically exceptions thrown during resolution, instantiation, or disposal).
  ///
  /// Example:
  /// ```dart
  /// observer.onError('Failed to resolve dependency', errorObj, stackTraceObj);
  /// ```
  void onError(String message, Object? error, StackTrace? stackTrace);
}

/// Diagnostic/Debug observer that prints all events
class PrintCherryPickObserver implements CherryPickObserver {
  @override
  void onBindingRegistered(String name, Type type, {String? scopeName}) =>
      print('[binding][CherryPick] $name — $type (scope: $scopeName)');

  @override
  void onInstanceRequested(String name, Type type, {String? scopeName}) =>
      print('[request][CherryPick] $name — $type (scope: $scopeName)');

  @override
  void onInstanceCreated(String name, Type type, Object instance, {String? scopeName}) =>
      print('[create][CherryPick] $name — $type => $instance (scope: $scopeName)');

  @override
  void onInstanceDisposed(String name, Type type, Object instance, {String? scopeName}) =>
      print('[dispose][CherryPick] $name — $type => $instance (scope: $scopeName)');

  @override
  void onModulesInstalled(List<String> modules, {String? scopeName}) =>
      print('[modules installed][CherryPick] ${modules.join(', ')} (scope: $scopeName)');
  @override
  void onModulesRemoved(List<String> modules, {String? scopeName}) =>
      print('[modules removed][CherryPick] ${modules.join(', ')} (scope: $scopeName)');

  @override
  void onScopeOpened(String name) => print('[scope opened][CherryPick] $name');

  @override
  void onScopeClosed(String name) => print('[scope closed][CherryPick] $name');

  @override
  void onCycleDetected(List<String> chain, {String? scopeName}) =>
      print('[cycle][CherryPick] Detected: ${chain.join(' -> ')}${scopeName != null ? ' (scope: $scopeName)' : ''}');

  @override
  void onCacheHit(String name, Type type, {String? scopeName}) =>
      print('[cache hit][CherryPick] $name — $type (scope: $scopeName)');
  @override
  void onCacheMiss(String name, Type type, {String? scopeName}) =>
      print('[cache miss][CherryPick] $name — $type (scope: $scopeName)');

  @override
  void onDiagnostic(String message, {Object? details}) =>
      print('[diagnostic][CherryPick] $message ${details ?? ''}');

  @override
  void onWarning(String message, {Object? details}) =>
      print('[warn][CherryPick] $message ${details ?? ''}');
  @override
  void onError(String message, Object? error, StackTrace? stackTrace) {
    print('[error][CherryPick] $message');
    if (error != null) print('  error: $error');
    if (stackTrace != null) print('  stack: $stackTrace');
  }
}

/// Silent observer: ignores all events
class SilentCherryPickObserver implements CherryPickObserver {
  @override
  void onBindingRegistered(String name, Type type, {String? scopeName}) {}
  @override
  void onInstanceRequested(String name, Type type, {String? scopeName}) {}
  @override
  void onInstanceCreated(String name, Type type, Object instance, {String? scopeName}) {}
  @override
  void onInstanceDisposed(String name, Type type, Object instance, {String? scopeName}) {}
  @override
  void onModulesInstalled(List<String> modules, {String? scopeName}) {}
  @override
  void onModulesRemoved(List<String> modules, {String? scopeName}) {}
  @override
  void onScopeOpened(String name) {}
  @override
  void onScopeClosed(String name) {}
  @override
  void onCycleDetected(List<String> chain, {String? scopeName}) {}
  @override
  void onCacheHit(String name, Type type, {String? scopeName}) {}
  @override
  void onCacheMiss(String name, Type type, {String? scopeName}) {}
  @override
  void onDiagnostic(String message, {Object? details}) {}
  @override
  void onWarning(String message, {Object? details}) {}
  @override
  void onError(String message, Object? error, StackTrace? stackTrace) {}
}
