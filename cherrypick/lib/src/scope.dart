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
import 'dart:collection';
import 'dart:math';

import 'package:cherrypick/src/cycle_detector.dart';
import 'package:cherrypick/src/disposable.dart';
import 'package:cherrypick/src/global_cycle_detector.dart';
import 'package:cherrypick/src/binding_resolver.dart';
import 'package:cherrypick/src/module.dart';
import 'package:cherrypick/src/logger.dart';
import 'package:cherrypick/src/log_format.dart';

class Scope with CycleDetectionMixin, GlobalCycleDetectionMixin {
  final Scope? _parentScope;

  late final CherryPickLogger _logger;

  @override
  CherryPickLogger get logger => _logger;

  /// COLLECTS all resolved instances that implement [Disposable].
  final Set<Disposable> _disposables = HashSet();

  /// RU: Метод возвращает родительский [Scope].
  ///
  /// ENG: The method returns the parent [Scope].
  ///
  /// return [Scope]
  Scope? get parentScope => _parentScope;

  final Map<String, Scope> _scopeMap = HashMap();

  Scope(this._parentScope, {required CherryPickLogger logger}) : _logger = logger {
    setScopeId(_generateScopeId());
    logger.info(formatLogMessage(
      type: 'Scope',
      name: scopeId ?? 'NO_ID',
      params: {
        if (_parentScope?.scopeId != null) 'parent': _parentScope!.scopeId,
      },
      description: 'scope created',
    ));
  }

  final Set<Module> _modulesList = HashSet();

  // индекс для мгновенного поиска binding’ов
  final Map<Object, Map<String?, BindingResolver>> _bindingResolvers = {};


  /// RU: Генерирует уникальный идентификатор для скоупа.
  /// ENG: Generates unique identifier for scope.
  String _generateScopeId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(10000);
    return 'scope_${timestamp}_$randomPart';
  }

  /// RU: Метод открывает дочерний (дополнительный) [Scope].
  ///
  /// ENG: The method opens child (additional) [Scope].
  ///
  /// return [Scope]
  Scope openSubScope(String name) {
    if (!_scopeMap.containsKey(name)) {
      final childScope = Scope(this, logger: logger); // Наследуем логгер вниз по иерархии
      // print removed (trace)
      // Наследуем настройки обнаружения циклических зависимостей
      if (isCycleDetectionEnabled) {
        childScope.enableCycleDetection();
      }
      if (isGlobalCycleDetectionEnabled) {
        childScope.enableGlobalCycleDetection();
      }
      _scopeMap[name] = childScope;
      logger.info(formatLogMessage(
        type: 'SubScope',
        name: name,
        params: {
          'id': childScope.scopeId,
          if (scopeId != null) 'parent': scopeId,
        },
        description: 'subscope created',
      ));
    }
    return _scopeMap[name]!;
  }

  /// RU: Метод закрывает дочерний (дополнительный) [Scope] асинхронно.
  ///
  /// ENG: The method closes child (additional) [Scope] asynchronously.
  ///
  /// return [Future<void>]
  Future<void> closeSubScope(String name) async {
    final childScope = _scopeMap[name];
    if (childScope != null) {
      await childScope.dispose(); // асинхронный вызов
      // Очищаем детектор для дочернего скоупа
      if (childScope.scopeId != null) {
        GlobalCycleDetector.instance.removeScopeDetector(childScope.scopeId!);
      }
      logger.info(formatLogMessage(
        type: 'SubScope',
        name: name,
        params: {
          'id': childScope.scopeId,
          if (scopeId != null) 'parent': scopeId,
        },
        description: 'subscope closed',
      ));
    }
    _scopeMap.remove(name);
  }

  /// RU: Метод инициализирует пользовательские модули в  [Scope].
  ///
  /// ENG: The method initializes custom modules in [Scope].
  ///
  /// return [Scope]
  Scope installModules(List<Module> modules) {
    _modulesList.addAll(modules);
    for (var module in modules) {
      logger.info(formatLogMessage(
        type: 'Module',
        name: module.runtimeType.toString(),
        params: {
          'scope': scopeId,
        },
        description: 'module installed',
      ));
      module.builder(this);
      // После builder: для всех новых биндингов
      for (final binding in module.bindingSet) {
        binding.logger = logger;
        binding.logAllDeferred();
      }
    }
    _rebuildResolversIndex();
    return this;
  }

  /// RU: Метод удаляет пользовательские модули из [Scope].
  ///
  /// ENG: This method removes custom modules from [Scope].
  ///
  /// return [Scope]
  Scope dropModules() {
    logger.info(formatLogMessage(
      type: 'Scope',
      name: scopeId,
      description: 'modules dropped',
    ));
    _modulesList.clear();
    _rebuildResolversIndex();
    return this;
  }

  /// RU: Возвращает найденную зависимость, определенную параметром типа [T].
  /// Выдает [StateError], если зависимость не может быть разрешена.
  /// Если вы хотите получить [null], если зависимость не может быть найдена,
  /// то используйте вместо этого [tryResolve]
  /// return - возвращает объект типа [T]  или [StateError]
  ///
  /// ENG: Returns the found dependency specified by the type parameter [T].
  /// Throws [StateError] if the dependency cannot be resolved.
  /// If you want to get [null] if the dependency cannot be found then use [tryResolve] instead
  /// return - returns an object of type [T] or [StateError]
  ///
  T resolve<T>({String? named, dynamic params}) {
    // Используем глобальное отслеживание, если включено
    T result;
    if (isGlobalCycleDetectionEnabled) {
      try {
        result =  withGlobalCycleDetection<T>(T, named, () {
          return _resolveWithLocalDetection<T>(named: named, params: params);
        });
      } catch (e, s) {
        logger.error(
          formatLogMessage(
            type: 'Scope',
            name: scopeId,
            params: {'resolve': T.toString()},
            description: 'global cycle detection failed during resolve',
          ),
          e,
          s,
        );
        rethrow;
      }
    } else {
      try {
        result = _resolveWithLocalDetection<T>(named: named, params: params);
      } catch (e, s) {
        logger.error(
          formatLogMessage(
            type: 'Scope',
            name: scopeId,
            params: {'resolve': T.toString()},
            description: 'failed to resolve',
          ),
          e,
          s,
        );
        rethrow;
      }
    }
    _trackDisposable(result);
    return result;
  }

  /// RU: Разрешение с локальным детектором циклических зависимостей.
  /// ENG: Resolution with local circular dependency detector.
  T _resolveWithLocalDetection<T>({String? named, dynamic params}) {
    return withCycleDetection<T>(T, named, () {
      var resolved = _tryResolveInternal<T>(named: named, params: params);
      if (resolved != null) {
        logger.info(formatLogMessage(
          type: 'Scope',
          name: scopeId,
          params: {
            'resolve': T.toString(),
            if (named != null) 'named': named,
          },
          description: 'successfully resolved',
        ));
        return resolved;
      } else {
        logger.error(
          formatLogMessage(
            type: 'Scope',
            name: scopeId,
            params: {
              'resolve': T.toString(),
              if (named != null) 'named': named,
            },
            description: 'failed to resolve',
          ),
        );
        throw StateError(
            'Can\'t resolve dependency `$T`. Maybe you forget register it?');
      }
    });
  }

  /// RU: Возвращает найденную зависимость типа [T] или null, если она не может быть найдена.
  /// ENG: Returns found dependency of type [T] or null if it cannot be found.
  ///
  T? tryResolve<T>({String? named, dynamic params}) {
    // Используем глобальное отслеживание, если включено
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

  /// RU: Попытка разрешения с локальным детектором циклических зависимостей.
  /// ENG: Try resolution with local circular dependency detector.
  T? _tryResolveWithLocalDetection<T>({String? named, dynamic params}) {
    if (isCycleDetectionEnabled) {
      return withCycleDetection<T?>(T, named, () {
        return _tryResolveInternal<T>(named: named, params: params);
      });
    } else {
      return _tryResolveInternal<T>(named: named, params: params);
    }
  }

  /// RU: Внутренний метод для разрешения зависимостей без проверки циклических зависимостей.
  /// ENG: Internal method for dependency resolution without circular dependency checking.
  T? _tryResolveInternal<T>({String? named, dynamic params}) {
    final resolver = _findBindingResolver<T>(named);

    // 1 Поиск зависимости по всем модулям текущего скоупа
    return resolver?.resolveSync(params) ??
        // 2 Поиск зависимостей в родительском скоупе
        _parentScope?.tryResolve(named: named, params: params);
  }

  /// RU: Асинхронно возвращает найденную зависимость, определенную параметром типа [T].
  /// Выдает [StateError], если зависимость не может быть разрешена.
  /// Если хотите получить [null], если зависимость не может быть найдена, используйте [tryResolveAsync].
  /// return - возвращает объект типа [T] or [StateError]
  ///
  /// ENG: Asynchronously returns the found dependency specified by the type parameter [T].
  /// Throws [StateError] if the dependency cannot be resolved.
  /// If you want to get [null] if the dependency cannot be found, use [tryResolveAsync] instead.
  /// return - returns an object of type [T] or [StateError]
  ///
  Future<T> resolveAsync<T>({String? named, dynamic params}) async {
    // Используем глобальное отслеживание, если включено
    T result;
    if (isGlobalCycleDetectionEnabled) {
      result = await withGlobalCycleDetection<Future<T>>(T, named, () async {
        return await _resolveAsyncWithLocalDetection<T>(named: named, params: params);
      });
    } else {
      result = await _resolveAsyncWithLocalDetection<T>(named: named, params: params);
    }
    _trackDisposable(result);
    return result;
  }

  /// RU: Асинхронное разрешение с локальным детектором циклических зависимостей.
  /// ENG: Async resolution with local circular dependency detector.
  Future<T> _resolveAsyncWithLocalDetection<T>({String? named, dynamic params}) async {
    return withCycleDetection<Future<T>>(T, named, () async {
      var resolved = await _tryResolveAsyncInternal<T>(named: named, params: params);
      if (resolved != null) {
        return resolved;
      } else {
        throw StateError(
            'Can\'t resolve async dependency `$T`. Maybe you forget register it?');
      }
    });
  }

  Future<T?> tryResolveAsync<T>({String? named, dynamic params}) async {
    // Используем глобальное отслеживание, если включено
    T? result;
    if (isGlobalCycleDetectionEnabled) {
      result = await withGlobalCycleDetection<Future<T?>>(T, named, () async {
        return await _tryResolveAsyncWithLocalDetection<T>(named: named, params: params);
      });
    } else {
      result = await _tryResolveAsyncWithLocalDetection<T>(named: named, params: params);
    }
    if (result != null) _trackDisposable(result);
    return result;
  }

  /// RU: Асинхронная попытка разрешения с локальным детектором циклических зависимостей.
  /// ENG: Async try resolution with local circular dependency detector.
  Future<T?> _tryResolveAsyncWithLocalDetection<T>({String? named, dynamic params}) async {
    if (isCycleDetectionEnabled) {
      return withCycleDetection<Future<T?>>(T, named, () async {
        return await _tryResolveAsyncInternal<T>(named: named, params: params);
      });
    } else {
      return await _tryResolveAsyncInternal<T>(named: named, params: params);
    }
  }

  /// RU: Внутренний метод для асинхронного разрешения зависимостей без проверки циклических зависимостей.
  /// ENG: Internal method for async dependency resolution without circular dependency checking.
  Future<T?> _tryResolveAsyncInternal<T>({String? named, dynamic params}) async {
    final resolver = _findBindingResolver<T>(named);

    // 1 Поиск зависимости по всем модулям текущего скоупа
    return resolver?.resolveAsync(params) ??
        // 2 Поиск зависимостей в родительском скоупе
        _parentScope?.tryResolveAsync(named: named, params: params);
  }

  BindingResolver<T>? _findBindingResolver<T>(String? named) =>
      _bindingResolvers[T]?[named] as BindingResolver<T>?;

  // Индексируем все binding’и после каждого installModules/dropModules
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

  /// INTERNAL: Tracks Disposable objects
  void _trackDisposable(Object? obj) {
    if (obj is Disposable && !_disposables.contains(obj)) {
      _disposables.add(obj);
    }
  }

  /// Calls dispose on all tracked disposables and child scopes recursively (async).
  Future<void> dispose() async {
    // First dispose children scopes
    for (final subScope in _scopeMap.values) {
      await subScope.dispose();
    }
    _scopeMap.clear();
    // Then dispose own disposables
    for (final d in _disposables) {
      try {
        await d.dispose();
      } catch (_) {}
    }
    _disposables.clear();
  }
}
