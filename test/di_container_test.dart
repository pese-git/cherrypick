import 'package:dart_di/di_container.dart';
import 'package:dart_di/resolvers/resolver.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('Without parent', () {
    test('Container bind<T> throws state error if it\'s already has resolver',
        () {
      final container = new DiContainer();
      container.bind<int>().toResolver(_makeResolver(5));

      expect(() => container.bind<int>().toResolver(_makeResolver(3)),
          throwsA(isA<StateError>()));
    });
  });
}

ResolverMock<T> _makeResolver<T>(T expectedValue) {
  final resolverMock = new ResolverMock<T>();
  when(resolverMock.resolve()).thenReturn(expectedValue);
  return resolverMock;
}

class ResolverMock<T> extends Mock implements Resolver<T> {}

abstract class A {}

class B implements A {}

class DependOnA {
  final A a;

  DependOnA(this.a) : assert(a != null);
}
