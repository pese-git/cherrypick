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

/// Synchronous factory: `T Function()`.
typedef ProviderFactory<T> = T Function();

/// Parameterized synchronous factory: `T Function(dynamic)`.
typedef ProviderFactoryWithParams<T> = T Function(dynamic);

/// Asynchronous factory: `Future<T> Function()`.
typedef AsyncProviderFactory<T> = Future<T> Function();

/// Parameterized asynchronous factory: `Future<T> Function(dynamic)`.
typedef AsyncProviderFactoryWithParams<T> = Future<T> Function(dynamic);

/// Internal interface for resolvers managed by [Binding].
abstract class BindingResolver<T> {
  T? resolveSync([dynamic params]);
  Future<T>? resolveAsync([dynamic params]);
  void toSingleton();
  bool get isSingleton;
}

/// Resolver for a pre-built synchronous instance.
class SyncInstanceResolver<T> implements BindingResolver<T> {
  final T _instance;

  SyncInstanceResolver(this._instance);

  @override
  T resolveSync([_]) => _instance;

  @override
  Future<T> resolveAsync([_]) => Future<T>.value(_instance);

  @override
  void toSingleton() {}

  @override
  bool get isSingleton => true;
}

/// Resolver for a pre-built async instance ([Future]).
class AsyncInstanceResolver<T> implements BindingResolver<T> {
  final Future<T> _instance;

  AsyncInstanceResolver(this._instance);

  @override
  T resolveSync([_]) {
    throw StateError('Instance is a Future; use resolveAsync() instead');
  }

  @override
  Future<T> resolveAsync([_]) => _instance;

  @override
  void toSingleton() {}

  @override
  bool get isSingleton => true;
}

/// Base class for provider-based resolvers with singleton flag support.
abstract class _BaseProviderResolver<T> implements BindingResolver<T> {
  bool _singleton = false;

  @override
  void toSingleton() {
    _singleton = true;
  }

  @override
  bool get isSingleton => _singleton;
}

/// Resolves [Binding.toProvide] with a sync `T Function()` provider.
class SyncProviderResolver<T> extends _BaseProviderResolver<T> {
  final ProviderFactory<T> _provider;
  Object? _cached;
  bool _isCached = false;

  SyncProviderResolver(this._provider);

  @override
  T resolveSync([_]) {
    if (_singleton && _isCached) {
      return _cached as T;
    }
    final result = _provider();
    if (_singleton) {
      _cached = result;
      _isCached = true;
    }
    return result;
  }

  @override
  Future<T> resolveAsync([_]) => Future<T>.value(resolveSync());
}

/// Resolves [Binding.toProvideWithParams] with a sync `T Function(dynamic)` provider.
class SyncProviderWithParamsResolver<T> extends _BaseProviderResolver<T> {
  final ProviderFactoryWithParams<T> _provider;
  Object? _cached;
  bool _isCached = false;

  SyncProviderWithParamsResolver(this._provider);

  @override
  T resolveSync([dynamic params]) {
    if (_singleton && _isCached) {
      return _cached as T;
    }
    if (params == null) {
      throw StateError('[$T] Params is null. Maybe you forgot to pass it?');
    }
    final result = _provider(params);
    if (_singleton) {
      _cached = result;
      _isCached = true;
    }
    return result;
  }

  @override
  Future<T> resolveAsync([dynamic params]) =>
      Future<T>.value(resolveSync(params));
}

/// Resolves [Binding.toProvide] with an async `Future<T> Function()` provider.
class AsyncProviderResolver<T> extends _BaseProviderResolver<T> {
  final AsyncProviderFactory<T> _provider;
  Future<T>? _cache;
  bool _isCached = false;

  AsyncProviderResolver(this._provider);

  @override
  T resolveSync([_]) {
    throw StateError(
      'Provider returns Future<$T>. Use resolveAsync() instead.',
    );
  }

  @override
  Future<T> resolveAsync([_]) {
    if (_singleton && _isCached) {
      return _cache!;
    }
    final result = _provider();
    if (_singleton) {
      _cache = result;
      _isCached = true;
    }
    return result;
  }
}

/// Resolves [Binding.toProvideWithParams] with an async `Future<T> Function(dynamic)` provider.
class AsyncProviderWithParamsResolver<T> extends _BaseProviderResolver<T> {
  final AsyncProviderFactoryWithParams<T> _provider;
  Future<T>? _cache;
  bool _isCached = false;

  AsyncProviderWithParamsResolver(this._provider);

  @override
  T resolveSync([_]) {
    throw StateError(
      'Provider returns Future<$T>. Use resolveAsync() instead.',
    );
  }

  @override
  Future<T> resolveAsync([dynamic params]) {
    if (_singleton && _isCached) {
      return _cache!;
    }
    if (params == null) {
      throw StateError('[$T] Params is null. Maybe you forgot to pass it?');
    }
    final result = _provider(params);
    if (_singleton) {
      _cache = result;
      _isCached = true;
    }
    return result;
  }
}

/// Fallback resolver for `FutureOr<T> Function()` providers whose static type
/// is not known at compile time. Detects sync vs async at resolve time.
class FutureOrProviderResolver<T> extends _BaseProviderResolver<T> {
  final FutureOr<T> Function() _provider;
  Object? _cached;
  bool _isCached = false;

  FutureOrProviderResolver(this._provider);

  @override
  T resolveSync([_]) {
    if (_singleton && _isCached) {
      final cached = _cached;
      if (cached is Future<T>) {
        throw StateError(
          'Provider returns Future<$T>. Use resolveAsync() instead.',
        );
      }
      return cached as T;
    }
    final result = _provider();
    if (result is Future<T>) {
      throw StateError(
        'Provider returns Future<$T>. Use resolveAsync() instead.',
      );
    }
    if (_singleton) {
      _cached = result;
      _isCached = true;
    }
    return result;
  }

  @override
  Future<T> resolveAsync([_]) {
    if (_singleton && _isCached) {
      final cached = _cached;
      if (cached is Future<T>) return cached;
      return Future<T>.value(cached as T);
    }
    final result = _provider();
    if (_singleton) {
      _cached = result;
      _isCached = true;
    }
    if (result is Future<T>) return result;
    return Future<T>.value(result);
  }
}

/// Fallback resolver for `FutureOr<T> Function(dynamic)` providers with params
/// whose static type is not known at compile time.
class FutureOrProviderWithParamsResolver<T> extends _BaseProviderResolver<T> {
  final FutureOr<T> Function(dynamic) _provider;
  Object? _cached;
  bool _isCached = false;

  FutureOrProviderWithParamsResolver(this._provider);

  @override
  T resolveSync([dynamic params]) {
    if (_singleton && _isCached) {
      final cached = _cached;
      if (cached is Future<T>) {
        throw StateError(
          'Provider returns Future<$T>. Use resolveAsync() instead.',
        );
      }
      return cached as T;
    }
    if (params == null) {
      throw StateError('[$T] Params is null. Maybe you forgot to pass it?');
    }
    final result = _provider(params);
    if (result is Future<T>) {
      throw StateError(
        'Provider returns Future<$T>. Use resolveAsync() instead.',
      );
    }
    if (_singleton) {
      _cached = result;
      _isCached = true;
    }
    return result;
  }

  @override
  Future<T> resolveAsync([dynamic params]) {
    if (_singleton && _isCached) {
      final cached = _cached;
      if (cached is Future<T>) return cached;
      return Future<T>.value(cached as T);
    }
    if (params == null) {
      throw StateError('[$T] Params is null. Maybe you forgot to pass it?');
    }
    final result = _provider(params);
    if (_singleton) {
      _cached = result;
      _isCached = true;
    }
    if (result is Future<T>) return result;
    return Future<T>.value(result);
  }
}

/// Factory for creating instance resolvers (sync or async).
class InstanceResolver {
  static BindingResolver<T> create<T>(FutureOr<T> instance) {
    if (instance is Future<T>) {
      return AsyncInstanceResolver<T>(instance);
    }
    return SyncInstanceResolver<T>(instance);
  }
}

/// Factory for creating the correct provider resolver based on the
/// provider's static return type, avoiding runtime checks in fast paths.
class ProviderResolver {
  static BindingResolver<T> create<T>(FutureOr<T> Function() provider) {
    if (provider is T Function()) {
      return SyncProviderResolver<T>(provider);
    }
    if (provider is Future<T> Function()) {
      return AsyncProviderResolver<T>(provider);
    }
    return FutureOrProviderResolver<T>(provider);
  }

  static BindingResolver<T> createWithParams<T>(
      FutureOr<T> Function(dynamic) provider) {
    if (provider is T Function(dynamic)) {
      return SyncProviderWithParamsResolver<T>(provider);
    }
    if (provider is Future<T> Function(dynamic)) {
      return AsyncProviderWithParamsResolver<T>(provider);
    }
    return FutureOrProviderWithParamsResolver<T>(provider);
  }

  /// Explicit sync resolver without parameters.
  static BindingResolver<T> sync<T>(ProviderFactory<T> provider) {
    return SyncProviderResolver<T>(provider);
  }

  /// Explicit sync resolver with parameters.
  static BindingResolver<T> syncWithParams<T>(
      ProviderFactoryWithParams<T> provider) {
    return SyncProviderWithParamsResolver<T>(provider);
  }

  /// Explicit async resolver without parameters.
  static BindingResolver<T> async<T>(AsyncProviderFactory<T> provider) {
    return AsyncProviderResolver<T>(provider);
  }

  /// Explicit async resolver with parameters.
  static BindingResolver<T> asyncWithParams<T>(
      AsyncProviderFactoryWithParams<T> provider) {
    return AsyncProviderWithParamsResolver<T>(provider);
  }
}
