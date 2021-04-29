///
/// Copyright 2021 Sergey Penkovsky <sergey.penkovsky@gmail.com>
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///      http://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///

enum Mode { SIMPLE, INSTANCE, PROVIDER_INSTANCE }

/// RU: Класс Binding<T> настраивает параметры экземпляра.
/// ENG: The Binding<T> class configures the settings for the instance.
///
class Binding<T> {
  late Mode _mode;
  late Type _key;
  late String _name;
  T? _instance;
  T? Function()? _provider;
  late bool _isSingeltone = false;
  late bool _isNamed = false;

  Binding() {
    _mode = Mode.SIMPLE;
    _key = T;
  }

  /// RU: Метод возвращает [Mode] экземпляра.
  /// ENG: The method returns the [Mode] of the instance.
  ///
  /// return [Mode]
  Mode get mode => _mode;

  /// RU: Метод возвращает тип экземпляра.
  /// ENG: The method returns the type of the instance.
  ///
  /// return [Type]
  Type get key => _key;

  /// RU: Метод возвращает имя экземпляра.
  /// ENG: The method returns the name of the instance.
  ///
  /// return [String]
  String get name => _name;

  /// RU: Метод проверяет сингелтон экземпляр или нет.
  /// ENG: The method checks the singleton instance or not.
  ///
  /// return [bool]
  bool get isSingeltone => _isSingeltone;

  /// RU: Метод проверяет именован экземпляр или нет.
  /// ENG: The method checks whether the instance is named or not.
  ///
  /// return [bool]
  bool get isNamed => _isNamed;

  /// RU: Добавляет имя для экземляпя [value].
  /// ENG: Added name for instance [value].
  ///
  /// return [Binding]
  Binding<T> withName(String name) {
    _name = name;
    _isNamed = true;
    return this;
  }

  /// RU: Инициализация экземляпяра [value].
  /// ENG: Initialization instance [value].
  ///
  /// return [Binding]
  Binding<T> toInstance(T value) {
    _mode = Mode.INSTANCE;
    _instance = value;
    _isSingeltone = true;
    return this;
  }

  /// RU: Инициализация экземляпяра  через провайдер [value].
  /// ENG: Initialization instance via provider [value].
  ///
  /// return [Binding]
  Binding<T> toProvide(T Function() value) {
    _mode = Mode.PROVIDER_INSTANCE;
    _provider = value;
    return this;
  }

  /// RU: Инициализация экземляпяра  как сингелтон [value].
  /// ENG: Initialization instance as a singelton [value].
  ///
  /// return [Binding]
  Binding<T> singeltone() {
    if (_mode == Mode.PROVIDER_INSTANCE) {
      _instance = _provider?.call();
    }
    _isSingeltone = true;
    return this;
  }

  /// RU: Поиск экземпляра.
  /// ENG: Resolve instance.
  ///
  /// return [T]
  T? get instance => _instance;

  /// RU: Поиск экземпляра.
  /// ENG: Resolve instance.
  ///
  /// return [T]
  T? get provider => _provider?.call();
}
