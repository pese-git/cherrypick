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

import 'package:cherrypick/src/binding_resolver.dart';

/// RU: Класс Binding&lt;T&gt; настраивает параметры экземпляра.
/// ENG: The Binding&lt;T&gt; class configures the settings for the instance.
///
import 'package:cherrypick/src/logger.dart';
import 'package:cherrypick/src/log_format.dart';

class Binding<T> {
  late Type _key;
  String? _name;

  BindingResolver<T>? _resolver;

  CherryPickLogger? logger;

  // Deferred logging flags
  bool _createdLogged = false;
  bool _namedLogged = false;
  bool _singletonLogged = false;

  Binding({this.logger}) {
    _key = T;
    // Не логируем здесь! Делаем deferred лог после назначения logger
  }

  void markCreated() {
    if (!_createdLogged) {
      logger?.info(formatLogMessage(
        type: 'Binding',
        name: T.toString(),
        params: _name != null ? {'name': _name} : null,
        description: 'created',
      ));
      _createdLogged = true;
    }
  }

  void markNamed() {
    if (isNamed && !_namedLogged) {
      logger?.info(formatLogMessage(
        type: 'Binding',
        name: T.toString(),
        params: {'name': _name},
        description: 'named',
      ));
      _namedLogged = true;
    }
  }

  void markSingleton() {
    if (isSingleton && !_singletonLogged) {
      logger?.info(formatLogMessage(
        type: 'Binding',
        name: T.toString(),
        params: _name != null ? {'name': _name} : null,
        description: 'singleton mode enabled',
      ));
      _singletonLogged = true;
    }
  }

  void logAllDeferred() {
    markCreated();
    markNamed();
    markSingleton();
  }

  /// RU: Метод возвращает тип экземпляра.
  /// ENG: The method returns the type of the instance.
  ///
  /// return [Type]
  Type get key => _key;

  /// RU: Метод возвращает имя экземпляра.
  /// ENG: The method returns the name of the instance.
  ///
  /// return [String]
  String? get name => _name;

  /// RU: Метод проверяет именован экземпляр или нет.
  /// ENG: The method checks whether the instance is named or not.
  ///
  /// return [bool]
  bool get isNamed => _name != null;

  /// RU: Метод проверяет сингелтон экземпляр или нет.
  /// ENG: The method checks the singleton instance or not.
  ///
  /// return [bool]
  bool get isSingleton => _resolver?.isSingleton ?? false;

  BindingResolver<T>? get resolver => _resolver;

  /// RU: Добавляет имя для экземляпя [value].
  /// ENG: Added name for instance [value].
  ///
  /// return [Binding]
  Binding<T> withName(String name) {
    _name = name;
    // Не логируем здесь, deferred log via markNamed()
    return this;
  }

  /// RU: Инициализация экземляпяра [value].
  /// ENG: Initialization instance [value].
  ///
  /// return [Binding]
  Binding<T> toInstance(Instance<T> value) {
    _resolver = InstanceResolver<T>(value);
    return this;
  }

  /// RU: Инициализация экземляпяра  через провайдер [value].
  /// ENG: Initialization instance via provider [value].
  ///
  /// return [Binding]
  Binding<T> toProvide(Provider<T> value) {
    _resolver = ProviderResolver<T>((_) => value.call(), withParams: false);
    return this;
  }

  /// RU: Инициализация экземляпяра  через провайдер [value] c динамическим параметром.
  /// ENG: Initialization instance via provider [value] with a dynamic param.
  ///
  /// return [Binding]
  Binding<T> toProvideWithParams(ProviderWithParams<T> value) {
    _resolver = ProviderResolver<T>(value, withParams: true);
    return this;
  }

  @Deprecated('Use toInstance instead of toInstanceAsync')
  Binding<T> toInstanceAsync(Instance<T> value) {
    return this.toInstance(value);
  }

  @Deprecated('Use toProvide instead of toProvideAsync')
  Binding<T> toProvideAsync(Provider<T> value) {
    return this.toProvide(value);
  }

  @Deprecated('Use toProvideWithParams instead of toProvideAsyncWithParams')
  Binding<T> toProvideAsyncWithParams(ProviderWithParams<T> value) {
    return this.toProvideWithParams(value);
  }

  /// RU: Инициализация экземляпяра  как сингелтон [value].
  /// ENG: Initialization instance as a singelton [value].
  ///
  /// return [Binding]
  Binding<T> singleton() {
    _resolver?.toSingleton();
    // Не логируем здесь, deferred log via markSingleton()
    return this;
  }

  T? resolveSync([dynamic params]) {
    final res = resolver?.resolveSync(params);
    if (res != null) {
      logger?.info(formatLogMessage(
        type: 'Binding',
        name: T.toString(),
        params: {
          if (_name != null) 'name': _name,
          'method': 'resolveSync',
        },
        description: 'object created/resolved',
      ));
    } else {
      logger?.warn(formatLogMessage(
        type: 'Binding',
        name: T.toString(),
        params: {
          if (_name != null) 'name': _name,
          'method': 'resolveSync',
        },
        description: 'resolveSync returned null',
      ));
    }
    return res;
  }

  Future<T>? resolveAsync([dynamic params]) {
    final future = resolver?.resolveAsync(params);
    if (future != null) {
      future
          .then((res) => logger?.info(formatLogMessage(
                type: 'Binding',
                name: T.toString(),
                params: {
                  if (_name != null) 'name': _name,
                  'method': 'resolveAsync',
                },
                description: 'Future resolved',
              )))
          .catchError((e, s) => logger?.error(
                formatLogMessage(
                  type: 'Binding',
                  name: T.toString(),
                  params: {
                    if (_name != null) 'name': _name,
                    'method': 'resolveAsync',
                  },
                  description: 'resolveAsync error',
                ),
                e,
                s,
              ));
    } else {
      logger?.warn(formatLogMessage(
        type: 'Binding',
        name: T.toString(),
        params: {
          if (_name != null) 'name': _name,
          'method': 'resolveAsync',
        },
        description: 'resolveAsync returned null',
      ));
    }
    return future;
  }
}
