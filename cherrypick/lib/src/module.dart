///
/// Copyright 2021 Sergey Penkovsky (sergey.penkovsky@gmail.com)
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
import 'dart:collection';

import 'package:cherrypick/src/binding.dart';
import 'package:cherrypick/src/scope.dart';

/// RU: Класс Module является основой для пользовательских модулей.
///  Этот класс нужен для инициализации [Scope].
///
/// RU: The Module class is the basis for custom modules.
/// This class is needed to initialize [Scope].
///
abstract class Module {
  final Set<Binding> _bindingSet = HashSet();

  /// RU: Метод добавляет в коллекцию модуля [Binding] экземпляр.
  ///
  /// ENG: The method adds an instance to the collection of the [Binding] module.
  ///
  /// return [Binding<T>]
  Binding<T> bind<T>() {
    final binding = Binding<T>();
    _bindingSet.add(binding);
    return binding;
  }

  /// RU: Метод возвращает коллекцию [Binding] экземпляров.
  ///
  /// ENG: The method returns a collection of [Binding] instances.
  ///
  /// return [Set<Binding>]
  Set<Binding> get bindingSet => _bindingSet;

  /// RU: Абстрактный метод для инициализации пользовательских экземпляров.
  /// В этом методе осуществляется конфигурация зависимостей.
  ///
  /// ENG: Abstract method for initializing custom instances.
  /// This method configures dependencies.
  ///
  /// return [void]
  void builder(Scope currentScope);
}
