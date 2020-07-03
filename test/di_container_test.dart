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

  group('With parent', () {
    test(
        "Container bind() throws state error (if it's parent already has a resolver)",
        () {
      final parentContainer = new DiContainer();
      final container = new DiContainer(parentContainer);

      parentContainer.bind<int>().toResolver(_makeResolver(5));

      expect(() => container.bind<int>().toResolver(_makeResolver(3)),
          throwsA(isA<StateError>()));
    });

    test("Container resolve() returns a value from parent container", () {
      final expectedValue = 5;
      final parentContainer = DiContainer();
      final container = DiContainer(parentContainer);

      parentContainer.bind<int>().toResolver(_makeResolver(expectedValue));

      expect(container.resolve<int>(), expectedValue);
    });
  });

  test("Container resolve() returns a  several value from parent container",
      () {
    final expectedIntValue = 5;
    final expectedStringValue = "Hello world";
    final parentContainer = DiContainer();
    final container = DiContainer(parentContainer);

    parentContainer.bind<int>().toResolver(_makeResolver(expectedIntValue));
    parentContainer
        .bind<String>()
        .toResolver(_makeResolver(expectedStringValue));

    expect(container.resolve<int>(), expectedIntValue);
    expect(container.resolve<String>(), expectedStringValue);
  });

  test("Container resolve() throws a state error if parent hasn't value too",
      () {
    final parentContainer = DiContainer();
    final container = DiContainer(parentContainer);
    expect(() => container.resolve<int>(), throwsA(isA<StateError>()));
  });

  test("Container has() returns false if parent has a resolver", () {
    final parentContainer = DiContainer();
    final container = DiContainer(parentContainer);

    parentContainer.bind<int>().toResolver(_makeResolver(5));

    expect(container.has<int>(), false);
  });

  test("Container has() returns false if parent hasn't a resolver", () {
    final parentContainer = DiContainer();
    final container = DiContainer(parentContainer);

    expect(container.has<int>(), false);
  });

  test("Container hasInTree() returns true if parent has a resolver", () {
    final parentContainer = DiContainer();
    final container = DiContainer(parentContainer);

    parentContainer.bind<int>().toResolver(_makeResolver(5));

    expect(container.hasInTree<int>(), true);
  });

  test("Test asSingelton", () {
    final expectedIntValue = 10;
    final containerA = DiContainer();
    final containerB = DiContainer(containerA);

    containerA.bind<int>().toValue(expectedIntValue).asSingleton();

    expect(containerB.resolve<int>(), expectedIntValue);
  });

  test("Bind to the factory resolves with value", () {
    final container = DiContainer();
    final a = AA();
    container.bind<A>().toFactory(() => a);

    expect(container.resolve<A>(), a);
  });

  test("Bind to the factory resolves with value", () {
    final container = DiContainer();
    final a = AA();
    container.bind<A>().toValue(a);
    container.bind<DependOnA>().toFactory1<A>((a) => DependOnA(a));

    expect(container.resolve<DependOnA>().a, a);
  });

  test("Bind to the factory resolves with 2 value", () {
    final container = DiContainer();
    final a = AA();
    final b = BB();
    container.bind<A>().toValue(a);
    container.bind<B>().toValue(b);
    container.bind<DependOnAB>().toFactory2<A, B>((a, b) => DependOnAB(a, b));

    expect(container.resolve<DependOnAB>().a, a);
    expect(container.resolve<DependOnAB>().b, b);
  });

  test("Bind to the factory resolves with 3 value", () {
    final container = DiContainer();
    final a = AA();
    final b = BB();
    final c = CC();
    container.bind<A>().toValue(a);
    container.bind<B>().toValue(b);
    container.bind<C>().toValue(c);
    container
        .bind<DependOnABC>()
        .toFactory3<A, B, C>((a, b, c) => DependOnABC(a, b, c));

    expect(container.resolve<DependOnABC>().a, a);
    expect(container.resolve<DependOnABC>().b, b);
    expect(container.resolve<DependOnABC>().c, c);
  });

  test("Bind to the factory resolves with 4 value", () {
    final container = DiContainer();
    final a = AA();
    final b = BB();
    final c = CC();
    final d = DD();
    container.bind<A>().toValue(a);
    container.bind<B>().toValue(b);
    container.bind<C>().toValue(c);
    container.bind<D>().toValue(d);
    container
        .bind<DependOnABCD>()
        .toFactory4<A, B, C, D>((a, b, c, d) => DependOnABCD(a, b, c, d));

    expect(container.resolve<DependOnABCD>().a, a);
    expect(container.resolve<DependOnABCD>().b, b);
    expect(container.resolve<DependOnABCD>().c, c);
    expect(container.resolve<DependOnABCD>().d, d);
  });

  test("Bind to the factory resolves with 5 value", () {
    final container = DiContainer();
    final a = AA();
    final b = BB();
    final c = CC();
    final d = DD();
    final e = EE();
    container.bind<A>().toValue(a);
    container.bind<B>().toValue(b);
    container.bind<C>().toValue(c);
    container.bind<D>().toValue(d);
    container.bind<E>().toValue(e);
    container.bind<DependOnABCDE>().toFactory5<A, B, C, D, E>(
        (a, b, c, d, e) => DependOnABCDE(a, b, c, d, e));

    expect(container.resolve<DependOnABCDE>().a, a);
    expect(container.resolve<DependOnABCDE>().b, b);
    expect(container.resolve<DependOnABCDE>().c, c);
    expect(container.resolve<DependOnABCDE>().d, d);
    expect(container.resolve<DependOnABCDE>().e, e);
  });

  test("Bind to the factory resolves with 6 value", () {
    final container = DiContainer();
    final a = AA();
    final b = BB();
    final c = CC();
    final d = DD();
    final e = EE();
    final f = FF();
    container.bind<A>().toValue(a);
    container.bind<B>().toValue(b);
    container.bind<C>().toValue(c);
    container.bind<D>().toValue(d);
    container.bind<E>().toValue(e);
    container.bind<F>().toValue(f);
    container.bind<DependOnABCDEF>().toFactory6<A, B, C, D, E, F>(
        (a, b, c, d, e, f) => DependOnABCDEF(a, b, c, d, e, f));

    expect(container.resolve<DependOnABCDEF>().a, a);
    expect(container.resolve<DependOnABCDEF>().b, b);
    expect(container.resolve<DependOnABCDEF>().c, c);
    expect(container.resolve<DependOnABCDEF>().d, d);
    expect(container.resolve<DependOnABCDEF>().e, e);
    expect(container.resolve<DependOnABCDEF>().f, f);
  });

  test("Bind to the factory resolves with 7 value", () {
    final container = DiContainer();
    final a = AA();
    final b = BB();
    final c = CC();
    final d = DD();
    final e = EE();
    final f = FF();
    final g = GG();
    container.bind<A>().toValue(a);
    container.bind<B>().toValue(b);
    container.bind<C>().toValue(c);
    container.bind<D>().toValue(d);
    container.bind<E>().toValue(e);
    container.bind<F>().toValue(f);
    container.bind<G>().toValue(g);
    container.bind<DependOnABCDEFG>().toFactory7<A, B, C, D, E, F, G>(
        (a, b, c, d, e, f, g) => DependOnABCDEFG(a, b, c, d, e, f, g));

    expect(container.resolve<DependOnABCDEFG>().a, a);
    expect(container.resolve<DependOnABCDEFG>().b, b);
    expect(container.resolve<DependOnABCDEFG>().c, c);
    expect(container.resolve<DependOnABCDEFG>().d, d);
    expect(container.resolve<DependOnABCDEFG>().e, e);
    expect(container.resolve<DependOnABCDEFG>().f, f);
    expect(container.resolve<DependOnABCDEFG>().g, g);
  });

  test("Bind to the factory resolves with 8 value", () {
    final container = DiContainer();
    final a = AA();
    final b = BB();
    final c = CC();
    final d = DD();
    final e = EE();
    final f = FF();
    final g = GG();
    final h = HH();
    container.bind<A>().toValue(a);
    container.bind<B>().toValue(b);
    container.bind<C>().toValue(c);
    container.bind<D>().toValue(d);
    container.bind<E>().toValue(e);
    container.bind<F>().toValue(f);
    container.bind<G>().toValue(g);
    container.bind<H>().toValue(h);
    container.bind<DependOnABCDEFGH>().toFactory8<A, B, C, D, E, F, G, H>(
        (a, b, c, d, e, f, g, h) => DependOnABCDEFGH(a, b, c, d, e, f, g, h));

    expect(container.resolve<DependOnABCDEFGH>().a, a);
    expect(container.resolve<DependOnABCDEFGH>().b, b);
    expect(container.resolve<DependOnABCDEFGH>().c, c);
    expect(container.resolve<DependOnABCDEFGH>().d, d);
    expect(container.resolve<DependOnABCDEFGH>().e, e);
    expect(container.resolve<DependOnABCDEFGH>().f, f);
    expect(container.resolve<DependOnABCDEFGH>().g, g);
    expect(container.resolve<DependOnABCDEFGH>().h, h);
  });
}

ResolverMock<T> _makeResolver<T>(T expectedValue) {
  final resolverMock = new ResolverMock<T>();
  when(resolverMock.resolve()).thenReturn(expectedValue);
  return resolverMock;
}

class ResolverMock<T> extends Mock implements Resolver<T> {}

abstract class A {}

class AA implements A {}

abstract class B {}

class BB implements B {}

abstract class C {}

class CC implements C {}

abstract class D {}

class DD implements D {}

abstract class E {}

class EE implements E {}

abstract class F {}

class FF implements F {}

abstract class G {}

class GG implements G {}

abstract class H {}

class HH implements H {}

class DependOnA {
  final A a;

  DependOnA(this.a) : assert(a != null);
}

class DependOnAB {
  final A a;
  final B b;

  DependOnAB(this.a, this.b) : assert(a != null && b != null);
}

class DependOnABC {
  final A a;
  final B b;
  final C c;

  DependOnABC(this.a, this.b, this.c)
      : assert(a != null && b != null && c != null);
}

class DependOnABCD {
  final A a;
  final B b;
  final C c;
  final D d;

  DependOnABCD(this.a, this.b, this.c, this.d)
      : assert(a != null && b != null && c != null && d != null);
}

class DependOnABCDE {
  final A a;
  final B b;
  final C c;
  final D d;
  final E e;

  DependOnABCDE(this.a, this.b, this.c, this.d, this.e)
      : assert(a != null && b != null && c != null && d != null && e != null);
}

class DependOnABCDEF {
  final A a;
  final B b;
  final C c;
  final D d;
  final E e;
  final F f;

  DependOnABCDEF(this.a, this.b, this.c, this.d, this.e, this.f)
      : assert(a != null &&
            b != null &&
            c != null &&
            d != null &&
            e != null &&
            f != null);
}

class DependOnABCDEFG {
  final A a;
  final B b;
  final C c;
  final D d;
  final E e;
  final F f;
  final G g;

  DependOnABCDEFG(this.a, this.b, this.c, this.d, this.e, this.f, this.g)
      : assert(a != null &&
            b != null &&
            c != null &&
            d != null &&
            e != null &&
            f != null &&
            g != null);
}

class DependOnABCDEFGH {
  final A a;
  final B b;
  final C c;
  final D d;
  final E e;
  final F f;
  final G g;
  final H h;

  DependOnABCDEFGH(
      this.a, this.b, this.c, this.d, this.e, this.f, this.g, this.h)
      : assert(a != null &&
            b != null &&
            c != null &&
            d != null &&
            e != null &&
            f != null &&
            g != null &&
            h != null);
}
