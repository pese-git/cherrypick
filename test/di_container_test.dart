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

    test("Container resolves value after adding a dependency", () {
      final expectedValue = 3;
      final container = new DiContainer();
      container.bind<int>().toResolver(_makeResolver(expectedValue));
      expect(container.resolve<int>(), expectedValue);
    });

    test("Container throws state error if the value can't be resolved", () {
      final container = DiContainer();
      expect(() => container.resolve<int>(), throwsA(isA<StateError>()));
    });

    test("Container has() returns true if it has resolver", () {
      final expectedValue = 5;
      final container = new DiContainer();
      container.bind<int>().toResolver(_makeResolver(expectedValue));
      expect(container.has<int>(), true);
    });

    test("Container has() returns false if it hasn't resolver", () {
      final container = new DiContainer();
      expect(container.has<int>(), false);
    });

    test("Container hasInTree() returns true if it has resolver", () {
      final expectedValue = 5;
      final container = DiContainer();
      container.bind<int>().toResolver(_makeResolver(expectedValue));
      expect(container.hasInTree<int>(), true);
    });

    test("Container hasInTree() returns true if it hasn`t resolver", () {
      final container = DiContainer();
      expect(container.hasInTree<int>(), false);
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
