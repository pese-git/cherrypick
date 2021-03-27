import 'package:dart_di/resolvers/resolver.dart';

class SingletonResolver<T> extends Resolver<T> {
  Resolver<T> _decoratedResolver;
  T? _value = null;

  SingletonResolver(this._decoratedResolver);

  @override
  T? resolve() {
    if (_value == null) {
      _value = _decoratedResolver.resolve();
    }
    return _value;
  }
}
