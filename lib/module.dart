import 'dart:collection';

import 'package:dart_di/binding.dart';
import 'package:dart_di/scope.dart';

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
