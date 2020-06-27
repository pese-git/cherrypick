import 'package:dart_di/resolvers/resolver.dart';

/**
 * Разрешает зависимость для фабричной функции
 */
class FactoryResolver<T> extends Resolver<T> {
  Function _factory;

  FactoryResolver(this._factory);

  @override
  T resolve() {
    return _factory();
  }
}
