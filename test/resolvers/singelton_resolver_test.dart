import 'package:dart_di/resolvers/factory_resolver.dart';
import 'package:dart_di/resolvers/singelton_resolver.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart' as mockito;

void main() {
  test(
      'Not singleton resolver resolves different values after multiple resolve() calls',
      () {
    const callCount = 3;
    final spy = new SpyMock();
    final factoryResolver = new FactoryResolver(() => spy..onFactory());

    for (var i = 0; i < callCount; i++) factoryResolver.resolve();

    mockito.verify(spy.onFactory()).called(callCount);
  });

  test('Singleton resolver resolves same value after multiple resolve() calls',
      () {
    const callCount = 3;
    final spy = new SpyMock();
    final singletonResolver =
        new SingletonResolver(new FactoryResolver(() => spy..onFactory()));

    for (var i = 0; i < callCount; i++) singletonResolver.resolve();

    mockito.verify(spy.onFactory()).called(1);
  });
}

abstract class Spy {
  void onFactory();
}

class SpyMock extends mockito.Mock implements Spy {}
