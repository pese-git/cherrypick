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

import 'package:cherrypick/src/binding_resolver.dart';

/// RU: Класс Binding<T> настраивает параметры экземпляра.
/// ENG: The Binding<T> class configures the settings for the instance.
///
class Binding<T> {
  late Type _key;
  String? _name;

  BindingResolver<T>? _resolver;

  Binding() {
    _key = T;
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

    return this;
  }

  T? resolveSync([dynamic params]) {
    return resolver?.resolveSync(params);
  }

  Future<T>? resolveAsync([dynamic params]) {
    return resolver?.resolveAsync(params);
  }
}
