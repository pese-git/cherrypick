/**
 * Copyright 2021 Sergey Penkovsky <sergey.penkovsky@gmail.com>
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *      http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:collection';

import 'package:dart_di/binding.dart';
import 'package:dart_di/module.dart';

Scope openRootScope() => Scope(null);

class Scope {
  final Scope? _parentScope;

  /// RU: Метод возвращает родительский [Scope].
  ///
  /// ENG: The method returns the parent [Scope].
  ///
  /// return [Scope]
  Scope? get parentScope => _parentScope;

  final Map<String, Scope> _scopeMap = HashMap();

  Scope(this._parentScope);

  final Set<Module> _modulesList = HashSet();

  /// RU: Метод открывает дочерний (дополнительный) [Scope].
  ///
  /// ENG: The method opens child (additional) [Scope].
  ///
  /// return [Scope]
  Scope openSubScope(String name) {
    if (!_scopeMap.containsKey(name)) {
      _scopeMap[name] = Scope(this);
    }
    return _scopeMap[name]!;
  }

  /// RU: Метод закрывает дочерний (дополнительный) [Scope].
  ///
  /// ENG: The method closes child (additional) [Scope].
  ///
  /// return [Scope]
  void closeSubScope(String name) {
    _scopeMap.remove(name);
  }

  /// RU: Метод инициализирует пользовательские модули в  [Scope].
  ///
  /// ENG: The method initializes custom modules in [Scope].
  ///
  /// return [Scope]
  Scope installModules(List<Module> modules) {
    _modulesList.addAll(modules);
    modules.forEach((module) => module.builder(this));
    return this;
  }

  /// RU: Метод удаляет пользовательские модули из [Scope].
  ///
  /// ENG: This method removes custom modules from [Scope].
  ///
  /// return [Scope]
  Scope dropModules() {
    _modulesList.removeAll(_modulesList);
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
  T resolve<T>({String? named}) {
    var resolved = tryResolve<T>(named: named);
    if (resolved != null) {
      return resolved;
    } else {
      throw StateError(
          'Can\'t resolve dependency `$T`. Maybe you forget register it?');
    }
  }

  /// RU: Возвращает найденную зависимость типа [T] или null, если она не может быть найдена.
  /// ENG: Returns found dependency of type [T] or null if it cannot be found.
  ///
  T? tryResolve<T>({String? named}) {
    // 1 Поиск зависимости по всем модулям текущего скоупа
    if (_modulesList.isNotEmpty) {
      for (Module module in _modulesList) {
        for (Binding binding in module.bindingSet) {
          if (binding.key == T &&
              ((!binding.isNamed && named == null) ||
                  (binding.isNamed && named == binding.name))) {
            switch (binding.mode) {
              case Mode.INSTANCE:
                return binding.instance;
              case Mode.PROVIDER_INSTANCE:
                return binding.isSingeltone
                    ? binding.instance
                    : binding.provider;
              default:
                return null;
            }
          }
        }
      }
    }

    // 2 Поиск зависимостей в родительском скоупе
    return _parentScope != null ? _parentScope!.tryResolve(named: named) : null;
  }
}
