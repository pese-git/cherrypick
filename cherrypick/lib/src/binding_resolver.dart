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

/// Represents a direct instance or an async instance ([T] or [Future<T>]).
/// Used for both direct and async bindings.
///
/// Example:
/// ```dart
/// Instance<String> sync = "hello";
/// Instance<MyApi> async = Future.value(MyApi());
/// ```
typedef Instance<T> = FutureOr<T>;

/// Provider function type for synchronous or asynchronous, parameterless creation of [T].
/// Can return [T] or [Future<T>].
///
/// Example:
/// ```dart
/// Provider<MyService> provider = () => MyService();
/// Provider<Api> asyncProvider = () async => await Api.connect();
/// ```
typedef Provider<T> = FutureOr<T> Function();

/// Provider function type that accepts a dynamic parameter, for factory/parametrized injection.
/// Returns [T] or [Future<T>].
///
/// Example:
/// ```dart
/// ProviderWithParams<User> provider = (params) => User(params["name"]);
/// ```
typedef ProviderWithParams<T> = FutureOr<T> Function(dynamic);

/// Abstract interface for dependency resolvers used by [Binding].
/// Defines how to resolve instances of type [T].
///
/// You usually don't use this directly; it's used internally for advanced/low-level DI.
abstract class BindingResolver<T> {
  /// Synchronously resolves the dependency, optionally taking parameters (for factory cases).
  /// Throws if implementation does not support sync resolution.
  T? resolveSync([dynamic params]);

  /// Asynchronously resolves the dependency, optionally taking parameters (for factory cases).
  /// If instance is already a [Future], returns it directly.
  Future<T>? resolveAsync([dynamic params]);

  /// Marks this resolver as singleton: instance(s) will be cached and reused inside the scope.
  void toSingleton();

  /// Returns true if this resolver is marked as singleton.
  bool get isSingleton;
}

/// Concrete resolver for direct instance ([T] or [Future<T>]). No provider is called.
///
/// Used for [Binding.toInstance].
/// Supports both sync and async resolution; sync will throw if underlying instance is [Future].
/// Examples:
/// ```dart
/// var resolver = InstanceResolver("hello");
/// resolver.resolveSync(); // == "hello"
/// var asyncResolver = InstanceResolver(Future.value(7));
/// asyncResolver.resolveAsync(); // Future<int>
/// ```
class InstanceResolver<T> implements BindingResolver<T> {
  final Instance<T> _instance;

  /// Wraps the given instance (sync or async) in a resolver.
  InstanceResolver(this._instance);

  @override
  T resolveSync([_]) {
    if (_instance is T) return _instance;
    throw StateError(
      'Instance $_instance is Future; '
      'use resolveAsync() instead',
    );
  }

  @override
  Future<T> resolveAsync([_]) {
    if (_instance is Future<T>) return _instance;
    return Future.value(_instance);
  }

  @override
  void toSingleton() {}

  @override
  bool get isSingleton => true;
}

/// Resolver for provider functions (sync/async/factory), with optional singleton caching.
/// Used for [Binding.toProvide], [Binding.toProvideWithParams], [Binding.singleton].
///
/// Examples:
/// ```dart
/// // No param, sync:
/// var r = ProviderResolver((_) => 5, withParams: false);
/// r.resolveSync(); // == 5
/// // With param:
/// var rp = ProviderResolver((p) => p * 2, withParams: true);
/// rp.resolveSync(2); // == 4
/// // Singleton:
/// r.toSingleton();
/// // Async:
/// var ra = ProviderResolver((_) async => await Future.value(10), withParams: false);
/// await ra.resolveAsync(); // == 10
/// ```
class ProviderResolver<T> implements BindingResolver<T> {
  final ProviderWithParams<T> _provider;
  final bool _withParams;

  FutureOr<T>? _cache;
  bool _singleton = false;

  /// Creates a resolver from [provider], optionally accepting dynamic params.
  ProviderResolver(
    ProviderWithParams<T> provider, {
    required bool withParams,
  })  : _provider = provider,
        _withParams = withParams;

  @override
  T resolveSync([dynamic params]) {
    _checkParams(params);
    final result = _cache ?? _provider(params);
    if (result is T) {
      if (_singleton) {
        _cache ??= result;
      }
      return result;
    }
    throw StateError(
      'Provider [$_provider] return Future<$T>. Use resolveAsync() instead.',
    );
  }

  @override
  Future<T> resolveAsync([dynamic params]) {
    _checkParams(params);
    final result = _cache ?? _provider(params);
    final target = result is Future<T> ? result : Future<T>.value(result);
    if (_singleton) {
      _cache ??= target;
    }
    return target;
  }

  @override
  void toSingleton() {
    _singleton = true;
  }

  @override
  bool get isSingleton => _singleton;

  /// Throws if params required but not supplied.
  void _checkParams(dynamic params) {
    if (_withParams && params == null) {
      throw StateError(
        '[$T] Params is null. Maybe you forgot to pass it?',
      );
    }
  }
}
