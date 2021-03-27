import 'package:dart_di/resolvers/resolving_context.dart';

/**
 * Контейнер - это объект, которой хранит все резолверы зависимостей.
 */
class DiContainer {
  final DiContainer? _parent;

  final _resolvers = <Type, ResolvingContext>{};

  DiContainer([this._parent]);

/**
     * Добавляет resolver зависимостей типа [T] в контейнер.
     * Обратите внимание, что перезапись значений внутри одного контейнера запрещена.
     * @return - возвращает [ResolvingContext] или [StateError]
     */
  ResolvingContext<T> bind<T>() {
    var context = ResolvingContext<T>(this);
    if (hasInTree<T>()) {
      throw StateError(
          'Dependency of type `$T` is already exist in containers tree');
    }

    _resolvers[T] = context;
    return context;
  }

  /**
     * Возвращает разрешенную зависимость, определенную параметром типа [T].
     * Выдает [StateError], если зависимость не может быть разрешена.
     * Если вы хотите получить [null], если зависимость не может быть разрешена,
     * то используйте вместо этого [tryResolve]
     * @return - возвращает объект типа [T]  или [StateError]
     */
  T resolve<T>() {
    var resolved = tryResolve<T>();
    if (resolved != null) {
      return resolved;
    } else {
      throw StateError(
          'Can\'t resolve dependency `$T`. Maybe you forget register it?');
    }
  }

  /**
     * Возвращает разрешенную зависимость типа [T] или null, если она не может быть разрешена.
     */
  T? tryResolve<T>() {
    var resolver = _resolvers[T];
    if (resolver != null) {
      return resolver.resolve();
    } else {
      return _parent?.tryResolve<T>();
    }
  }

  /**
     * Возвращает true, если у этого контейнера есть средство разрешения зависимостей для типа [T].
     * Если вы хотите проверить его для всего дерева контейнеров, используйте вместо него [hasInTree].
     * @return - возвращает булево значение
     */
  bool has<T>() {
    return _resolvers.containsKey(T);
  }

/**
     * Возвращает true, если контейнер или его родители содержат средство разрешения зависимостей для типа [T].
     * Если вы хотите проверить его только для этого контейнера, используйте вместо него [has].
     * @return - возвращает булево значение
     */
  bool hasInTree<T>() {
    return has<T>() || (_parent != null && _parent!.hasInTree<T>());
  }
}
