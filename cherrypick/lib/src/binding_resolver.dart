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

typedef Instance<T> = FutureOr<T>;

/// RU: Синхронный или асинхронный провайдер без параметров, возвращающий [T] или [Future<T>].
/// ENG: Synchronous or asynchronous provider without parameters, returning [T] or [Future<T>].
typedef Provider<T> = FutureOr<T> Function();

/// RU: Провайдер с динамическим параметром, возвращающий [T] или [Future<T>] в зависимости от реализации.
/// ENG: Provider with dynamic parameter, returning [T] or [Future<T>] depending on implementation.
typedef ProviderWithParams<T> = FutureOr<T> Function(dynamic);

/// RU: Абстрактный интерфейс для классов, которые разрешают зависимости типа [T].
/// ENG: Abstract interface for classes that resolve dependencies of type [T].
abstract class BindingResolver<T> {
  /// RU: Синхронное разрешение зависимости с параметром [params].
  /// ENG: Synchronous resolution of the dependency with [params].
  T? resolveSync([dynamic params]);

  /// RU: Асинхронное разрешение зависимости с параметром [params].
  /// ENG: Asynchronous resolution of the dependency with [params].
  Future<T>? resolveAsync([dynamic params]);

  /// RU: Помечает текущий резолвер как синглтон — результат будет закеширован.
  /// ENG: Marks this resolver as singleton — result will be cached.
  void toSingleton();

  bool get isSingleton;
}

/// RU: Резолвер, оборачивающий конкретный экземпляр [T] (или Future<T>), без вызова провайдера.
/// ENG: Resolver that wraps a concrete instance of [T] (or Future<T>), without provider invocation.
class InstanceResolver<T> implements BindingResolver<T> {
  final Instance<T> _instance;

  /// RU: Создаёт резолвер, оборачивающий значение [instance].
  /// ENG: Creates a resolver that wraps the given [instance].
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

/// RU: Резолвер, оборачивающий провайдер, с возможностью синглтон-кеширования.
/// ENG: Resolver that wraps a provider, with optional singleton caching.
class ProviderResolver<T> implements BindingResolver<T> {
  final ProviderWithParams<T> _provider;
  final bool _withParams;

  FutureOr<T>? _cache;
  bool _singleton = false;

  /// RU: Создаёт резолвер из произвольной функции [raw], поддерживающей ноль или один параметр.
  /// ENG: Creates a resolver from arbitrary function [raw], supporting zero or one parameter.
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

  /// RU: Проверяет, был ли передан параметр, если провайдер требует его.
  /// ENG: Checks if parameter is passed when the provider expects it.
  void _checkParams(dynamic params) {
    if (_withParams && params == null) {
      throw StateError(
        '[$T] Params is null. Maybe you forgot to pass it?',
      );
    }
  }
}
