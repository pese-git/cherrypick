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

import 'package:cherrypick/src/binding.dart';
import 'package:cherrypick/src/cycle_detector.dart';
import 'package:cherrypick/src/disposable.dart';
import 'package:cherrypick/src/global_cycle_detector.dart';
import 'package:cherrypick/src/binding_resolver.dart';
import 'package:cherrypick/src/module.dart';
import 'package:cherrypick/src/observer.dart';

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

  bool get _isSilentObserver => _observer is SilentCherryPickObserver;

  bool get _canUseDirectResolvePath =>
      _isSilentObserver &&
      !isCycleDetectionEnabled &&
      !isGlobalCycleDetectionEnabled;

  /// COLLECTS all resolved instances that implement [Disposable].
  final Set<Disposable> _disposables = HashSet();

  /// Returns the parent [Scope] if present, or null if this is the root scope.
  Scope? get parentScope => _parentScope;

  final Map<String, Scope> _scopeMap = HashMap();

  Scope(this._parentScope, {required CherryPickObserver observer})
      : _observer = observer {
    setScopeId(_generateScopeId());
    if (!_isSilentObserver) {
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
  }

  final Set<Module> _modulesList = HashSet();

  // index for fast binding lookup
  final Map<Object, Map<String?, BindingResolver>> _bindingResolvers = {};

  /// Counts every scope created in this isolate, making [_generateScopeId]
  /// collision-free by construction.
  static int _scopeSequence = 0;

  /// Generates a unique identifier string for this scope instance.
  ///
  /// Used internally for diagnostics, logging and global scope tracking.
  ///
  /// The id must be unique: [GlobalCycleDetector] keys its per-scope detectors
  /// by it and prefixes every global resolution key with it, so two scopes
  /// sharing an id would share a resolution stack. The sequence number — not
  /// the timestamp, which is only there to make logs readable — is what
  /// guarantees uniqueness.
  String _generateScopeId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'scope_${timestamp}_${++_scopeSequence}';
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
      if (!_isSilentObserver) {
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
    }
    return _scopeMap[name]!;
  }

  /// Asynchronously closes and disposes a named child [Scope] (subscope).
  ///
  /// Ensures all [Disposable] objects and internal modules
  /// in the subscope are properly cleaned up. Also removes any global cycle detectors associated with the subscope.
  ///
  /// Only objects created by bindings declared in the subscope are disposed:
  /// dependencies inherited from this scope remain owned by it. See [dispose].
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
      if (!_isSilentObserver) {
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
    }
    _scopeMap.remove(name);
  }

  /// Installs a list of custom [Module]s into the [Scope].
  ///
  /// Each module registers bindings and configuration for dependencies.
  /// After calling this, bindings are immediately available for resolve/tryResolve.
  ///
  /// Throws [StateError] if a module declares a `bind<T>()` without completing
  /// it with a target (`toInstance`, `toProvide`, …): such a binding could
  /// never be resolved, so it is reported here rather than at resolve time.
  ///
  /// Example:
  /// ```dart
  /// rootScope.installModules([AppModule(), NetworkModule()]);
  /// ```
  Scope installModules(List<Module> modules) {
    _modulesList.addAll(modules);
    if (!_isSilentObserver && modules.isNotEmpty) {
      observer.onModulesInstalled(
        modules.map((m) => m.runtimeType.toString()).toList(),
        scopeName: scopeId,
      );
    }
    for (var module in modules) {
      if (!_isSilentObserver) {
        observer.onDiagnostic(
          'Module installed: ${module.runtimeType}',
          details: {
            'type': 'Module',
            'name': module.runtimeType.toString(),
            'scope': scopeId,
            'description': 'module installed',
          },
        );
      }
      module.builder(this);
      // Associate bindings with this scope's observer
      for (final binding in module.bindingSet) {
        binding.observer = observer;
        if (!_isSilentObserver) {
          binding.logAllDeferred();
        }
      }
      _addModuleToIndex(module);
    }
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
    if (!_isSilentObserver && _modulesList.isNotEmpty) {
      observer.onModulesRemoved(
        _modulesList.map((m) => m.runtimeType.toString()).toList(),
        scopeName: scopeId,
      );
    }
    if (!_isSilentObserver) {
      observer.onDiagnostic(
        'Modules dropped for scope: $scopeId',
        details: {
          'type': 'Scope',
          'name': scopeId,
          'description': 'modules dropped',
        },
      );
    }
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
    if (_canUseDirectResolvePath) {
      final result = _directResolveSync<T>(named, params);
      if (result == null) {
        throw StateError(
            'Can\'t resolve dependency `$T`. Maybe you forget register it?');
      }
      return result;
    }

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
  /// Returns the resolved dependency, or `null` when no such binding is
  /// registered in this scope or its parents — unlike [resolve], a missing
  /// binding is not an error.
  ///
  /// A binding that *is* registered but cannot be resolved synchronously still
  /// throws, so a misuse is reported instead of being hidden behind a `null`:
  /// an async instance or provider directs you to [resolveAsync], and a
  /// parameterized provider invoked without `params` reports the missing
  /// arguments. Errors raised by the provider itself propagate unchanged.
  ///
  /// In short: `null` means "not registered", never "failed".
  ///
  /// Example:
  /// ```dart
  /// final maybeDb = scope.tryResolve<Database>();
  /// ```
  T? tryResolve<T>({String? named, dynamic params}) {
    if (_canUseDirectResolvePath) {
      return _directResolveSync<T>(named, params);
    }

    T? result;
    if (isGlobalCycleDetectionEnabled) {
      result = withGlobalCycleDetection<T?>(T, named, () {
        return _tryResolveWithLocalDetection<T>(named: named, params: params);
      });
    } else {
      result = _tryResolveWithLocalDetection<T>(named: named, params: params);
    }
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
  /// Returns null if not found. Used internally by the observer/detection path.
  ///
  /// A resolved [Disposable] is tracked in the scope that owns the binding
  /// (where the resolver produced it), exactly once — intermediate scopes on
  /// the parent chain only forward the lookup.
  T? _tryResolveInternal<T>({String? named, dynamic params}) {
    final resolver = _findBindingResolver<T>(named);
    final local = resolver?.resolveSync(params);
    if (local != null) {
      _trackDisposable(local);
      return local;
    }
    // Fallback to parent (public entry preserves per-scope cycle detection).
    return _parentScope?.tryResolve(named: named, params: params);
  }

  /// Fast-path resolution used when observers and cycle detection are disabled.
  ///
  /// Walks the parent chain via a direct internal recursion instead of
  /// re-entering the public [tryResolve] at every level. This avoids the
  /// per-level fast-path guard re-evaluation and, crucially, tracks a resolved
  /// [Disposable] exactly once in the scope that owns the binding — the public
  /// re-entry previously registered the same instance in every scope on the
  /// chain (causing `dispose()` to run once per level). Returns null if not
  /// found anywhere in the chain.
  T? _directResolveSync<T>(String? named, dynamic params) {
    final resolver = _findBindingResolver<T>(named);
    final local = resolver?.resolveSync(params);
    if (local != null) {
      _trackDisposable(local);
      return local;
    }
    return _parentScope?._directResolveSync<T>(named, params);
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
    if (_canUseDirectResolvePath) {
      final result = await _directResolveAsync<T>(named, params);
      if (result == null) {
        throw StateError(
            "Can't resolve async dependency `$T`. Maybe you forget register it?");
      }
      return result;
    }
    return _resolveAsyncWithObserverPath<T>(named: named, params: params);
  }

  Future<T> _resolveAsyncWithObserverPath<T>(
      {String? named, dynamic params}) async {
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
  ///
  /// Returns the dependency, or `null` when no such binding is registered in
  /// this scope or its parents.
  ///
  /// Failures while resolving a registered binding are not swallowed: an error
  /// thrown by the provider, a detected cycle, or a parameterized provider
  /// invoked without `params` all propagate to the caller.
  ///
  /// In short: `null` means "not registered", never "failed".
  ///
  /// Example:
  /// ```dart
  /// final user = await scope.tryResolveAsync<User>();
  /// ```
  Future<T?> tryResolveAsync<T>({String? named, dynamic params}) async {
    if (_canUseDirectResolvePath) {
      return await _directResolveAsync<T>(named, params);
    }
    return _tryResolveAsyncWithObserverPath<T>(named: named, params: params);
  }

  Future<T?> _tryResolveAsyncWithObserverPath<T>(
      {String? named, dynamic params}) async {
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

  /// Direct async resolution for [T] without cycle check. Returns null if missing.
  /// Used internally by the observer/detection path. Tracks a resolved
  /// [Disposable] once in the owning scope (see [_tryResolveInternal]).
  Future<T?> _tryResolveAsyncInternal<T>({String? named, dynamic params}) {
    final resolver = _findBindingResolver<T>(named);
    final local = resolver?.resolveAsync(params);
    if (local != null) {
      return local.then((value) {
        _trackDisposable(value);
        return value;
      });
    }
    // Fallback to parent (public entry preserves per-scope cycle detection).
    return _parentScope?.tryResolveAsync(named: named, params: params) ??
        Future<T?>.value(null);
  }

  /// Fast-path async resolution used when observers and cycle detection are
  /// disabled. Mirrors [_directResolveSync]: recurses into the parent chain
  /// directly (no public re-entry) and tracks a resolved [Disposable] exactly
  /// once in the scope that owns the binding.
  Future<T?> _directResolveAsync<T>(String? named, dynamic params) {
    final resolver = _findBindingResolver<T>(named);
    final local = resolver?.resolveAsync(params);
    if (local != null) {
      return local.then((value) {
        _trackDisposable(value);
        return value;
      });
    }
    final parent = _parentScope;
    if (parent != null) return parent._directResolveAsync<T>(named, params);
    return Future<T?>.value(null);
  }

  /// Looks up the [BindingResolver] for [T] and [named] within this scope.
  /// Returns null if none found. Internal use only.
  BindingResolver<T>? _findBindingResolver<T>(String? named) =>
      _bindingResolvers[T]?[named] as BindingResolver<T>?;

  void _trackDisposable(Object? value) {
    if (value is Disposable) {
      _disposables.add(value);
    }
  }

  void _addModuleToIndex(Module module) {
    for (var binding in module.bindingSet) {
      final resolver =
          binding.resolver ?? _reportIncompleteBinding(binding, module);
      _bindingResolvers.putIfAbsent(binding.key, () => {});
      final nameKey = binding.isNamed ? binding.name : null;
      _bindingResolvers[binding.key]![nameKey] = resolver;
    }
  }

  /// Reports a `bind<T>()` whose chain was never completed with a target.
  ///
  /// Such a binding carries no resolver, so nothing could ever be resolved
  /// from it. It is a configuration mistake, and naming the type, the module
  /// and the missing call is far more useful than the null-check failure that
  /// indexing it would otherwise produce.
  Never _reportIncompleteBinding(Binding binding, Module module) {
    final name = binding.isNamed ? " named '${binding.name}'" : '';
    final message =
        'Binding for `${binding.key}`$name in module ${module.runtimeType} '
        'has no target, so it can never be resolved. Complete it with '
        'toInstance(), toProvide(), toProvideWithParams(), toProvideAsync() '
        'or toProvideAsyncWithParams().';
    observer.onError(message, null, null);
    throw StateError(message);
  }

  /// Rebuilds the internal index of all [BindingResolver]s from installed modules.
  /// Called after [dropModules]. Internal use only.
  void _rebuildResolversIndex() {
    _bindingResolvers.clear();
    for (var module in _modulesList) {
      _addModuleToIndex(module);
    }
  }

  /// Asynchronously disposes this [Scope], all tracked [Disposable] objects, and recursively
  /// all its child subscopes.
  ///
  /// This method should always be called when a scope is no longer needed
  /// to guarantee timely resource cleanup (files, sockets, streams, handles, etc).
  ///
  /// A [Disposable] is tracked by — and therefore disposed by — the scope whose
  /// binding created it, not the scope [resolve] was called on. Resolving a
  /// parent's dependency through a subscope leaves it owned by the parent, so
  /// it stays alive until the parent is disposed.
  ///
  /// Note that a binding declared in a long-lived scope and not marked
  /// `singleton()` accumulates one tracked instance per resolve until that
  /// scope is disposed. Declare bindings in the scope whose lifetime matches
  /// the resource.
  ///
  /// Example:
  /// ```dart
  /// await myScope.dispose();
  /// ```
  Future<void> dispose() async {
    // Create copies to avoid concurrent modification
    final scopes = _scopeMap.values.toList();
    for (final subScope in scopes) {
      await subScope.dispose();
    }
    _scopeMap.clear();

    final disposables = _disposables.toList();
    for (final d in disposables) {
      await d.dispose();
    }
    _disposables.clear();

    // Clear modules
    _modulesList.clear();
    // Clear binding-index
    _bindingResolvers.clear();
  }
}
