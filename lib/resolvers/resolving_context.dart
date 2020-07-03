import 'package:dart_di/di_container.dart';
import 'package:dart_di/resolvers/factory_resolver.dart';
import 'package:dart_di/resolvers/resolver.dart';
import 'package:dart_di/resolvers/singelton_resolver.dart';
import 'package:dart_di/resolvers/value_resolver.dart';

class ResolvingContext<T> extends Resolver {
  /// Корневой резолвер
  Resolver<T> get resolver => _resolver;

  DiContainer _container;

  Resolver _resolver;

  ResolvingContext(this._container);

/**
     * Разрешает зависимость типа [T]
     * @return - возвращает объект типа [T]
     */
  @override
  T resolve() {
    _verify();
    return _resolver?.resolve();
  }

  /**
     * Добавляет резолвер в качестве корневого резолвера
     * С помощью этого метода вы можете добавить любой
     * пользовательский резолвер
     */
  ResolvingContext<T> toResolver<TImpl extends T>(Resolver<TImpl> resolver) {
    _resolver = resolver;
    return this;
  }

  /**
     *  Создать резолвер значения
     */
  ResolvingContext<T> toValue<TImpl extends T>(T value) {
    Resolver<TImpl> resolver = ValueResolver(value);
    return toResolver<TImpl>(resolver);
  }

  /**
     * Преобразователь в сингелтон
     */
  ResolvingContext<T> asSingleton() {
    return toResolver(SingletonResolver<T>(resolver));
  }

  /**
     * Создать фабричный resolver без каких-либо зависимостей
     */
  ResolvingContext<T> toFactory<TImpl extends T>(TImpl Function() factory) {
    Resolver<TImpl> resolver = FactoryResolver<TImpl>(factory);
    return toResolver(resolver);
  }

  /**
     * Создать фабричный resolver с 1 зависимостью от контейнера
     */
  ResolvingContext<T> toFactory1<T1>(T Function(T1) factory) {
    Resolver<T> resolver =
        FactoryResolver<T>(() => factory(_container.resolve<T1>()));
    return toResolver(resolver);
  }

  /**
     * Создать фабричный resolver с 2 зависимостями от контейнера
     */
  ResolvingContext<T> toFactory2<T1, T2>(T Function(T1, T2) factory) {
    Resolver<T> resolver = FactoryResolver<T>(
        () => factory(_container.resolve<T1>(), _container.resolve<T2>()));
    return toResolver(resolver);
  }

  /**
     * Создать фабричный resolver с 3 зависимостями от контейнера
     */
  ResolvingContext<T> toFactory3<T1, T2, T3>(T Function(T1, T2, T3) factory) {
    Resolver<T> resolver = FactoryResolver<T>(() => factory(
        _container.resolve<T1>(),
        _container.resolve<T2>(),
        _container.resolve<T3>()));
    return toResolver(resolver);
  }

  /**
     * Создать фабричный resolver с 4 зависимостями от контейнера
     */
  ResolvingContext<T> toFactory4<T1, T2, T3, T4>(
      T Function(T1, T2, T3, T4) factory) {
    // TODO: implement toFactory4
    throw UnimplementedError();
  }

  /**
     * Создать фабричный resolver с 5 зависимостями от контейнера
     */
  ResolvingContext<T> toFactory5<T1, T2, T3, T4, T5>(
      T Function(T1, T2, T3, T4, T5) factory) {
    // TODO: implement toFactory5
    throw UnimplementedError();
  }

  /**
     * Создать фабричный resolver с 6 зависимостями от контейнера
     */
  ResolvingContext<T> toFactory6<T1, T2, T3, T4, T5, T6>(
      T Function(T1, T2, T3, T4, T5, T6) factory) {
    // TODO: implement toFactory6
    throw UnimplementedError();
  }

  /**
     * Создать фабричный resolver с 7 зависимостями от контейнера
     */
  ResolvingContext<T> toFactory7<T1, T2, T3, T4, T5, T6, T7>(
      T Function(T1, T2, T3, T4, T5, T6, T7) factory) {
    // TODO: implement toFactory7
    throw UnimplementedError();
  }

  /**
     * Создать фабричный resolver с 8 зависимостями от контейнера
     */
  ResolvingContext<T> toFactory8<T1, T2, T3, T4, T5, T6, T7, T8>(
      T Function(T1, T2, T3, T4, T5, T6, T7, T8) factory) {
    // TODO: implement toFactory8
    throw UnimplementedError();
  }

  void _verify() {
    if (_resolver == null) {
      throw StateError("Can\'t resolve T without any resolvers. " +
          "Please check, may be you didn\'t do anything after bind()");
    }
  }
}
