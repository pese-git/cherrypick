import 'dart:collection';

import 'package:dart_di/experimental/binding.dart';
import 'package:dart_di/experimental/scope.dart';

abstract class Module {
  final Set<Binding> _bindingSet = HashSet();

  Binding<T> bind<T>() {
    final binding = Binding<T>();
    _bindingSet.add(binding);
    return binding;
  }

  Set<Binding> get bindingSet => _bindingSet;

  void builder(Scope currentScope);
}
