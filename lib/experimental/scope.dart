import 'dart:collection';

import 'package:dart_di/experimental/binding.dart';
import 'package:dart_di/experimental/module.dart';

Scope openRootScope() => Scope(null);

class Scope {
  final Scope? _parentScope;

  Scope? get parentScope => _parentScope;

  final Map<String, Scope> _scopeMap = HashMap();

  Scope(this._parentScope);

  final Set<Module> _modulesList = HashSet();

  Scope openSubScope(String name) {
    final subScope = Scope(this);
    if (!_scopeMap.containsKey(name)) {
      _scopeMap[name] = subScope;
    }
    return _scopeMap[name]!;
  }

  void closeSubScope(String name) {
    _scopeMap.remove(name);
  }

  Scope installModules(List<Module> modules) {
    _modulesList.addAll(modules);
    modules.forEach((module) => module.builder(this));
    return this;
  }

  Scope dropModules() {
    _modulesList.removeAll(_modulesList);
    return this;
  }

  /**
     * Возвращает найденную зависимость, определенную параметром типа [T].
     * Выдает [StateError], если зависимость не может быть разрешена.
     * Если вы хотите получить [null], если зависимость не может быть найдена,
     * то используйте вместо этого [tryResolve]
     * @return - возвращает объект типа [T]  или [StateError]
     */
  T resolve<T>({String? named}) {
    var resolved = tryResolve<T>(named: named);
    if (resolved != null) {
      return resolved;
    } else {
      throw StateError(
          'Can\'t resolve dependency `$T`. Maybe you forget register it?');
    }
  }

  /**
     * Возвращает найденную зависимость типа [T] или null, если она не может быть найдена.
     */
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
