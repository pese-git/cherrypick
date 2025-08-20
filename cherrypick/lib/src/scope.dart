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
import 'dart:math';
import 'dart:convert';

import 'package:cherrypick/src/cycle_detector.dart';
import 'package:cherrypick/src/disposable.dart';
import 'package:cherrypick/src/global_cycle_detector.dart';
import 'package:cherrypick/src/binding_resolver.dart';
import 'package:cherrypick/src/module.dart';
import 'package:cherrypick/src/observer.dart';
// import 'package:cherrypick/src/log_format.dart';

/// Represents a DI scope (container) for modules, subscopes,
/// and dependency resolution (sync/async) in CherryPick.
///
/// Scopes provide hierarchical DI: you can resolve dependencies from parents,
/// override or isolate modules, and manage scope-specific singletons.
///
/// Each scope:
/// - Can install modules ([installModules]) that define [Binding]s
/// - Supports parent-child scope tree (see [openSubScope])
/// - Can resolve dependencies synchronously ([resolve]) or asynchronously ([resolveAsync])
/// - Cleans up resources for [Disposable] objects (see [dispose])
/// - Detects dependency cycles (local and global, if enabled)
///
/// Example usage:
/// ```dart
/// final rootScope = CherryPick.openRootScope();
/// rootScope.installModules([AppModule()]);
///
/// // Synchronous resolution:
/// final auth = rootScope.resolve<AuthService>();
///
/// // Asynchronous resolution:
/// final db = await rootScope.resolveAsync<Database>();
///
/// // Open a child scope (for a feature, page, or test):
/// final userScope = rootScope.openSubScope('user');
/// userScope.installModules([UserModule()]);
///
/// // Proper resource cleanup (calls dispose() on tracked objects)
/// await CherryPick.closeRootScope();
/// ```
class Scope with CycleDetectionMixin, GlobalCycleDetectionMixin {
  final Scope? _parentScope;

  late final CherryPickObserver _observer;

  @override
  CherryPickObserver get observer => _observer;

  /// COLLECTS all resolved instances that implement [Disposable].
  final Set<Disposable> _disposables = HashSet();

  /// Returns the parent [Scope] if present, or null if this is the root scope.
  Scope? get parentScope => _parentScope;

  final Map<String, Scope> _scopeMap = HashMap();

  Scope(this._parentScope, {required CherryPickObserver observer})
      : _observer = observer {
    setScopeId(_generateScopeId());
    observer.onScopeOpened(scopeId ?? 'NO_ID');
    observer.onDiagnostic(
      'Scope created: ${scopeId ?? 'NO_ID'}',
      details: {
        'type': 'Scope',
        'name': scopeId ?? 'NO_ID',
        if (_parentScope?.scopeId != null) 'parent': _parentScope!.scopeId,
        'description': 'scope created',
      },
    );
  }

  final Set<Module> _modulesList = HashSet();

  // индекс для мгновенного поиска binding’ов
  final Map<Object, Map<String?, BindingResolver>> _bindingResolvers = {};

  /// Cached [Future]s for async singleton or in-progress resolutions (keyed by binding).
  final Map<String, Future<Object?>> _asyncResolveCache = {};

  /// Holds [Completer] for every async key currently being awaited — needed to notify all callers promptly and consistently in case of errors.
  final Map<String, Completer<Object?>> _asyncCompleterCache = {};

  /// Tracks which async keys are actively in progress (to detect/guard against async circular dependencies).
  final Set<String> _activeAsyncKeys = {};

  /// Converts parameter object to a unique key string for cache/indexing.
  String _paramsToKey(dynamic params) {
    if (params == null) return '';
    if (params is String) return params;
    if (params is num || params is bool) return params.toString();
    if (params is Map || params is List) return jsonEncode(params);
    return params.hashCode.toString();
  }

  /// Builds a unique key from type, name, and parameters — used for async singleton/factory cache lookups.
  String _cacheKey<T>(String? named, [dynamic params]) =>
      '${T.toString()}:${named ?? ""}:${_paramsToKey(params)}';

  /// Generates a unique identifier string for this scope instance.
  ///
  /// Used internally for diagnostics, logging and global scope tracking.
  String _generateScopeId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(10000);
    return 'scope_${timestamp}_$randomPart';
  }

  /// Opens a named child [Scope] (subscope) as a descendant of the current scope.
  ///
  /// Subscopes inherit modules and DI context from their parent, but can override or extend bindings.
  /// Useful for feature-isolation, screens, request/transaction lifetimes, and test separation.
  ///
  /// Example:
  /// ```dart
  /// final featureScope = rootScope.openSubScope('feature');
  /// featureScope.installModules([FeatureModule()]);
  /// final dep = featureScope.resolve<MyDep>();
  /// ```
  Scope openSubScope(String name) {
    if (!_scopeMap.containsKey(name)) {
      final childScope = Scope(this, observer: observer);
      if (isCycleDetectionEnabled) {
        childScope.enableCycleDetection();
      }
      if (isGlobalCycleDetectionEnabled) {
        childScope.enableGlobalCycleDetection();
      }
      _scopeMap[name] = childScope;
      observer.onDiagnostic(
        'SubScope created: $name',
        details: {
          'type': 'SubScope',
          'name': name,
          'id': childScope.scopeId,
          if (scopeId != null) 'parent': scopeId,
          'description': 'subscope created',
        },
      );
    }
    return _scopeMap[name]!;
  }

  /// Asynchronously closes and disposes a named child [Scope] (subscope).
  ///
  /// Ensures all [Disposable] objects and internal modules
  /// in the subscope are properly cleaned up. Also removes any global cycle detectors associated with the subscope.
  ///
  /// Example:
  /// ```dart
  /// await rootScope.closeSubScope('feature');
  /// ```
  Future<void> closeSubScope(String name) async {
    final childScope = _scopeMap[name];
    if (childScope != null) {
      await childScope.dispose();
      if (childScope.scopeId != null) {
        GlobalCycleDetector.instance.removeScopeDetector(childScope.scopeId!);
      }
      observer.onScopeClosed(childScope.scopeId ?? name);
      observer.onDiagnostic(
        'SubScope closed: $name',
        details: {
          'type': 'SubScope',
          'name': name,
          'id': childScope.scopeId,
          if (scopeId != null) 'parent': scopeId,
          'description': 'subscope closed',
        },
      );
    }
    _scopeMap.remove(name);
  }

  /// Installs a list of custom [Module]s into the [Scope].
  ///
  /// Each module registers bindings and configuration for dependencies.
  /// After calling this, bindings are immediately available for resolve/tryResolve.
  ///
  /// Example:
  /// ```dart
  /// rootScope.installModules([AppModule(), NetworkModule()]);
  /// ```
  Scope installModules(List<Module> modules) {
    _modulesList.addAll(modules);
    if (modules.isNotEmpty) {
      observer.onModulesInstalled(
        modules.map((m) => m.runtimeType.toString()).toList(),
        scopeName: scopeId,
      );
    }
    for (var module in modules) {
      observer.onDiagnostic(
        'Module installed: ${module.runtimeType}',
        details: {
          'type': 'Module',
          'name': module.runtimeType.toString(),
          'scope': scopeId,
          'description': 'module installed',
        },
      );
      module.builder(this);
      // Associate bindings with this scope's observer
      for (final binding in module.bindingSet) {
        binding.observer = observer;
        binding.logAllDeferred();
      }
    }
    _rebuildResolversIndex();
    return this;
  }

  /// Removes all installed [Module]s and their bindings from this [Scope].
  ///
  /// Typically used in tests or when resetting app configuration/runtime environment.
  /// Note: this does not dispose resolved [Disposable]s (call [dispose] for that).
  ///
  /// Example:
  /// ```dart
  /// testScope.dropModules();
  /// ```
  Scope dropModules() {
    if (_modulesList.isNotEmpty) {
      observer.onModulesRemoved(
        _modulesList.map((m) => m.runtimeType.toString()).toList(),
        scopeName: scopeId,
      );
    }
    observer.onDiagnostic(
      'Modules dropped for scope: $scopeId',
      details: {
        'type': 'Scope',
        'name': scopeId,
        'description': 'modules dropped',
      },
    );
    _modulesList.clear();
    _rebuildResolversIndex();
    return this;
  }

  /// Resolves a dependency of type [T], optionally by name and with params.
  ///
  /// Throws [StateError] if the dependency cannot be resolved. (Use [tryResolve] for fallible lookup).
  /// Resolves from installed modules or recurses up the parent scope chain.
  ///
  /// Example:
  /// ```dart
  /// final logger = scope.resolve<Logger>();
  /// final special = scope.resolve<Service>(named: 'special');
  /// ```
  T resolve<T>({String? named, dynamic params}) {
    observer.onInstanceRequested(T.toString(), T, scopeName: scopeId);
    T result;
    if (isGlobalCycleDetectionEnabled) {
      try {
        result = withGlobalCycleDetection<T>(T, named, () {
          return _resolveWithLocalDetection<T>(named: named, params: params);
        });
      } catch (e, s) {
        observer.onError(
          'Global cycle detection failed during resolve: $T',
          e,
          s,
        );
        rethrow;
      }
    } else {
      try {
        result = _resolveWithLocalDetection<T>(named: named, params: params);
      } catch (e, s) {
        observer.onError(
          'Failed to resolve: $T',
          e,
          s,
        );
        rethrow;
      }
    }
    _trackDisposable(result);
    return result;
  }

  /// Resolves [T] using the local cycle detector for this scope.
  /// Throws [StateError] if not found or cycle is detected.
  /// Used internally by [resolve].
  T _resolveWithLocalDetection<T>({String? named, dynamic params}) {
    return withCycleDetection<T>(T, named, () {
      var resolved = _tryResolveInternal<T>(named: named, params: params);
      if (resolved != null) {
        observer.onInstanceCreated(T.toString(), T, resolved,
            scopeName: scopeId);
        observer.onDiagnostic(
          'Successfully resolved: $T',
          details: {
            'type': 'Scope',
            'name': scopeId,
            'resolve': T.toString(),
            if (named != null) 'named': named,
            'description': 'successfully resolved',
          },
        );
        return resolved;
      } else {
        observer.onError(
          'Failed to resolve: $T',
          null,
          null,
        );
        throw StateError(
            'Can\'t resolve dependency `$T`. Maybe you forget register it?');
      }
    });
  }

  /// Attempts to resolve a dependency of type [T], optionally by name and with params.
  ///
  /// Returns the resolved dependency, or `null` if not found.
  /// Does not throw if missing (unlike [resolve]).
  ///
  /// Example:
  /// ```dart
  /// final maybeDb = scope.tryResolve<Database>();
  /// ```
  T? tryResolve<T>({String? named, dynamic params}) {
    T? result;
    if (isGlobalCycleDetectionEnabled) {
      result = withGlobalCycleDetection<T?>(T, named, () {
        return _tryResolveWithLocalDetection<T>(named: named, params: params);
      });
    } else {
      result = _tryResolveWithLocalDetection<T>(named: named, params: params);
    }
    if (result != null) _trackDisposable(result);
    return result;
  }

  /// Attempts to resolve [T] using the local cycle detector. Returns null if not found or cycle.
  /// Used internally by [tryResolve].
  T? _tryResolveWithLocalDetection<T>({String? named, dynamic params}) {
    if (isCycleDetectionEnabled) {
      return withCycleDetection<T?>(T, named, () {
        return _tryResolveInternal<T>(named: named, params: params);
      });
    } else {
      return _tryResolveInternal<T>(named: named, params: params);
    }
  }

  /// Locates and resolves [T] without cycle detection (direct lookup).
  /// Returns null if not found. Used internally.
  T? _tryResolveInternal<T>({String? named, dynamic params}) {
    final resolver = _findBindingResolver<T>(named);
    // 1 - Try from own modules; 2 - Fallback to parent
    return resolver?.resolveSync(params) ??
        _parentScope?.tryResolve(named: named, params: params);
  }

  /// Asynchronously resolves a dependency of type [T].
  ///
  /// Throws [StateError] if not found. (Use [tryResolveAsync] for a fallible async resolve.)
  ///
  /// Example:
  /// ```dart
  /// final db = await scope.resolveAsync<Database>();
  /// final special = await scope.resolveAsync<Service>(named: "special");
  /// ```
  Future<T> resolveAsync<T>({String? named, dynamic params}) async {
    T result;
    if (isGlobalCycleDetectionEnabled) {
      result = await withGlobalCycleDetection<Future<T>>(T, named, () async {
        return await _resolveAsyncWithLocalDetection<T>(
            named: named, params: params);
      });
    } else {
      result = await _resolveAsyncWithLocalDetection<T>(
          named: named, params: params);
    }
    //if (result == null) {
    //  throw StateError('Can\'t resolve async dependency `$T`. Maybe you forget register it?');
    //}
    _trackDisposable(result);
    return result;
  }

  /// Resolves [T] asynchronously using local cycle detector. Throws if not found.
  /// Internal implementation for async [resolveAsync].
  Future<T> _resolveAsyncWithLocalDetection<T>(
      {String? named, dynamic params}) async {
    return withCycleDetection<Future<T>>(T, named, () async {
      var resolved =
          await _tryResolveAsyncInternal<T>(named: named, params: params);
      if (resolved != null) {
        observer.onInstanceCreated(T.toString(), T, resolved,
            scopeName: scopeId);
        observer.onDiagnostic(
          'Successfully async resolved: $T',
          details: {
            'type': 'Scope',
            'name': scopeId,
            'resolve': T.toString(),
            if (named != null) 'named': named,
            'description': 'successfully resolved (async)',
          },
        );
        return resolved;
      } else {
        observer.onError(
          'Failed to async resolve: $T',
          null,
          null,
        );
        throw StateError(
            'Can\'t resolve async dependency `$T`. Maybe you forget register it?');
      }
    });
  }

  /// Attempts to asynchronously resolve a dependency of type [T].
  /// Returns the dependency or null if not present (never throws).
  ///
  /// Example:
  /// ```dart
  /// final user = await scope.tryResolveAsync<User>();
  /// ```
  Future<T?> tryResolveAsync<T>({String? named, dynamic params}) async {
    T? result;
    if (isGlobalCycleDetectionEnabled) {
      result = await withGlobalCycleDetection<Future<T?>>(T, named, () async {
        return await _tryResolveAsyncWithLocalDetection<T>(
            named: named, params: params);
      });
    } else {
      result = await _tryResolveAsyncWithLocalDetection<T>(
          named: named, params: params);
    }
    if (result != null) _trackDisposable(result);
    return result;
  }

  /// Attempts to resolve [T] asynchronously using local cycle detector. Returns null if missing.
  /// Internal implementation for async [tryResolveAsync].
  Future<T?> _tryResolveAsyncWithLocalDetection<T>(
      {String? named, dynamic params}) async {
    if (isCycleDetectionEnabled) {
      return withCycleDetection<Future<T?>>(T, named, () async {
        return await _tryResolveAsyncInternal<T>(named: named, params: params);
      });
    } else {
      return await _tryResolveAsyncInternal<T>(named: named, params: params);
    }
  }

  /// Direct async resolution for [T] without cycle check. Returns null if missing. Internal use only.
  Future<T?> _tryResolveAsyncInternal<T>(
      {String? named, dynamic params}) async {
    final key = _cacheKey<T>(named, params);
    final resolver = _findBindingResolver<T>(named);
    if (resolver != null) {
      final isSingleton = resolver.isSingleton;
      return await _sharedAsyncResolveCurrentScope(
        key: key,
        resolver: resolver,
        isSingleton: isSingleton,
        params: params,
      );
    } else if (_parentScope != null) {
      // переход на родителя: выпадение из локального кэша!
      return await _parentScope.tryResolveAsync<T>(
          named: named, params: params);
    } else {
      // не найден — null, не кэшируем!
      return null;
    }
  }

  /// Looks up the [BindingResolver] for [T] and [named] within this scope.
  /// Returns null if none found. Internal use only.
  BindingResolver<T>? _findBindingResolver<T>(String? named) =>
      _bindingResolvers[T]?[named] as BindingResolver<T>?;

  /// Rebuilds the internal index of all [BindingResolver]s from installed modules.
  /// Called after [installModules] and [dropModules]. Internal use only.
  void _rebuildResolversIndex() {
    _bindingResolvers.clear();
    for (var module in _modulesList) {
      for (var binding in module.bindingSet) {
        _bindingResolvers.putIfAbsent(binding.key, () => {});
        final nameKey = binding.isNamed ? binding.name : null;
        _bindingResolvers[binding.key]![nameKey] = binding.resolver!;
      }
    }
  }

  /// Tracks resolved [Disposable] instances, to ensure dispose is called automatically.
  /// Internal use only.
  void _trackDisposable(Object? obj) {
    if (obj is Disposable && !_disposables.contains(obj)) {
      _disposables.add(obj);
    }
  }

  /// Shared core for async binding resolution:
  /// Handles async singleton/factory caching, error propagation for all awaiting callers,
  /// and detection of async circular dependencies.
  ///
  /// If an error occurs (circular or factory throws), all awaiting completions get the same error.
  /// For singletons, result stays in cache for next calls.
  ///
  /// [key] — unique cache key for binding resolution (type:name:params)
  /// [resolver] — BindingResolver to provide async instance
  /// [isSingleton] — if true, caches the Future/result; otherwise cache is cleared after resolve
  /// [params] — (optional) parameters for resolution
  Future<T?> _sharedAsyncResolveCurrentScope<T>({
    required String key,
    required BindingResolver<T> resolver,
    required bool isSingleton,
    dynamic params,
  }) async {
    observer.onDiagnostic(
      'Async resolve requested',
      details: {
        'type': T.toString(),
        'key': key,
        'singleton': isSingleton,
        'params': params,
        'scopeId': scopeId,
      },
    );

    if (_activeAsyncKeys.contains(key)) {
      observer.onDiagnostic(
        'Circular async DI detected',
        details: {
          'key': key,
          'asyncKeyStack': List<String>.from(_activeAsyncKeys)..add(key),
          'scopeId': scopeId
        },
      );
      final error = CircularDependencyException(
          'Circular async DI detected for key=$key',
          List<String>.from(_activeAsyncKeys)..add(key));
      if (_asyncCompleterCache.containsKey(key)) {
        final pending = _asyncCompleterCache[key]!;
        if (!pending.isCompleted) {
          pending.completeError(error, StackTrace.current);
        }
      } else {
        final completer = Completer<Object?>();
        _asyncCompleterCache[key] = completer;
        _asyncResolveCache[key] = completer.future;
        completer.completeError(error, StackTrace.current);
      }
      throw error;
    }

    if (_asyncResolveCache.containsKey(key)) {
      observer.onDiagnostic(
        'Async resolve cache HIT',
        details: {'key': key, 'scopeId': scopeId},
      );
      try {
        return (await _asyncResolveCache[key]) as T?;
      } catch (e) {
        observer.onDiagnostic(
          'Async resolve cache HIT — exception',
          details: {'key': key, 'scopeId': scopeId, 'error': e.toString()},
        );
        rethrow;
      }
    } else {
      observer.onDiagnostic(
        'Async resolve cache MISS',
        details: {'key': key, 'scopeId': scopeId},
      );
    }

    final completer = Completer<Object?>();
    _asyncResolveCache[key] = completer.future;
    _asyncCompleterCache[key] = completer;
    _activeAsyncKeys.add(key);

    try {
      observer.onDiagnostic('Async resolution started',
          details: {'key': key, 'scopeId': scopeId});
      final Future<T?> resultFut = resolver.resolveAsync(params)!;
      final T? result = await resultFut;
      observer.onDiagnostic('Async resolution success',
          details: {'key': key, 'scopeId': scopeId});
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      if (!isSingleton) {
        _asyncResolveCache.remove(key);
        _asyncCompleterCache.remove(key);
      }
      return result;
    } catch (e, st) {
      observer.onDiagnostic('Async resolution error',
          details: {'key': key, 'scopeId': scopeId, 'error': e.toString()});
      if (!completer.isCompleted) {
        completer.completeError(e, st);
      }
      _asyncResolveCache.remove(key);
      _asyncCompleterCache.remove(key);
      rethrow;
    } finally {
      observer.onDiagnostic('Async resolve FINISH (removing from active)',
          details: {'key': key, 'scopeId': scopeId});
      _activeAsyncKeys.remove(key); // всегда убираем!
    }
  }

  /// Asynchronously disposes this [Scope], all tracked [Disposable] objects, and recursively
  /// all its child subscopes.
  ///
  /// This method should always be called when a scope is no longer needed
  /// to guarantee timely resource cleanup (files, sockets, streams, handles, etc).
  ///
  /// Example:
  /// ```dart
  /// await myScope.dispose();
  /// ```
  Future<void> dispose() async {
    // Create copies to avoid concurrent modification
    final scopesCopy = Map<String, Scope>.from(_scopeMap);
    for (final subScope in scopesCopy.values) {
      await subScope.dispose();
    }
    _scopeMap.clear();

    final disposablesCopy = Set<Disposable>.from(_disposables);
    for (final d in disposablesCopy) {
      await d.dispose();
    }
    _disposables.clear();
    _asyncResolveCache.clear();
    _asyncCompleterCache.clear();
    _activeAsyncKeys.clear();
  }
}
