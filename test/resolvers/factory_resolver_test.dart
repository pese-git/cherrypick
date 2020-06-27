import 'package:dart_di/resolvers/factory_resolver.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart' as mockito;

void main() {
  test('Factory resolver resolves with factory', () {
    const expected = 3;
    final factoryResolver = new FactoryResolver(() => expected);

    expect(factoryResolver.resolve(), expected);
  });

  test('Factory creates value only after resolve() call', () {
    final spy = new SpyMock();
    final factoryResolver = new FactoryResolver(() => spy.onFactory());

    mockito.verifyNever(spy.onFactory());
    factoryResolver.resolve();
    mockito.verify(spy.onFactory());
  });
}

abstract class Spy {
  void onFactory();
}

class SpyMock extends mockito.Mock implements Spy {}
