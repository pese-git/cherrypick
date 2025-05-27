import 'package:cherrypick/src/module.dart';
import 'package:cherrypick/src/scope.dart';
import 'package:test/test.dart';

void main() {
  // --------------------------------------------------------------------------
  group('Scope & Subscope Management', () {
    test('Scope has no parent if constructed with null', () {
      final scope = Scope(null);
      expect(scope.parentScope, null);
    });

    test('Can open and retrieve the same subScope by key', () {
      final scope = Scope(null);
      final subScope = scope.openSubScope('subScope');
      expect(scope.openSubScope('subScope'), subScope);
    });

    test('closeSubScope removes subscope so next openSubScope returns new', () {
      final scope = Scope(null);
      final subScope = scope.openSubScope("child");
      expect(scope.openSubScope("child"), same(subScope));
      scope.closeSubScope("child");
      final newSubScope = scope.openSubScope("child");
      expect(newSubScope, isNot(same(subScope)));
    });
  });

  // --------------------------------------------------------------------------
  group('Dependency Resolution (standard)', () {
    test("Throws StateError if value can't be resolved", () {
      final scope = Scope(null);
      expect(() => scope.resolve<String>(), throwsA(isA<StateError>()));
    });

    test('Resolves value after adding a dependency', () {
      final expectedValue = 'test string';
      final scope = Scope(null)
          .installModules([TestModule<String>(value: expectedValue)]);
      expect(scope.resolve<String>(), expectedValue);
    });

    test('Returns a value from parent scope', () {
      final expectedValue = 5;
      final parentScope = Scope(null);
      final scope = Scope(parentScope);

      parentScope.installModules([TestModule<int>(value: expectedValue)]);

      expect(scope.resolve<int>(), expectedValue);
    });

    test('Returns several values from parent container', () {
      final expectedIntValue = 5;
      final expectedStringValue = 'Hello world';
      final parentScope = Scope(null).installModules([
        TestModule<int>(value: expectedIntValue),
        TestModule<String>(value: expectedStringValue)
      ]);
      final scope = Scope(parentScope);

      expect(scope.resolve<int>(), expectedIntValue);
      expect(scope.resolve<String>(), expectedStringValue);
    });

    test("Throws StateError if parent hasn't value too", () {
      final parentScope = Scope(null);
      final scope = Scope(parentScope);
      expect(() => scope.resolve<int>(), throwsA(isA<StateError>()));
    });

    test("After dropModules resolves fail", () {
      final scope = Scope(null)..installModules([TestModule<int>(value: 5)]);
      expect(scope.resolve<int>(), 5);
      scope.dropModules();
      expect(() => scope.resolve<int>(), throwsA(isA<StateError>()));
    });
  });

  // --------------------------------------------------------------------------
  group('Named Dependencies', () {
    test('Resolve named binding', () {
      final scope = Scope(null)
        ..installModules([
          TestModule<String>(value: "first"),
          TestModule<String>(value: "second", name: "special")
        ]);
      expect(scope.resolve<String>(named: "special"), "second");
      expect(scope.resolve<String>(), "first");
    });

    test('Named binding does not clash with unnamed', () {
      final scope = Scope(null)
        ..installModules([
          TestModule<String>(value: "foo", name: "bar"),
        ]);
      expect(() => scope.resolve<String>(), throwsA(isA<StateError>()));
      expect(scope.resolve<String>(named: "bar"), "foo");
    });

    test("tryResolve returns null for missing named", () {
      final scope = Scope(null)
        ..installModules([
          TestModule<String>(value: "foo"),
        ]);
      expect(scope.tryResolve<String>(named: "bar"), isNull);
    });
  });

  // --------------------------------------------------------------------------
  group('Provider with parameters', () {
    test('Resolve dependency using providerWithParams', () {
      final scope = Scope(null)
        ..installModules([
          _InlineModule((m, s) {
            m.bind<int>().toProvideWithParams((param) => (param as int) * 2);
          }),
        ]);
      expect(scope.resolve<int>(params: 3), 6);
      expect(() => scope.resolve<int>(), throwsA(isA<StateError>()));
    });
  });

  // --------------------------------------------------------------------------
  group('Async Resolution', () {
    test('Resolve async instance', () async {
      final scope = Scope(null)
        ..installModules([
          _InlineModule((m, s) {
            m.bind<String>().toInstanceAsync(Future.value('async value'));
          }),
        ]);
      expect(await scope.resolveAsync<String>(), "async value");
    });

    test('Resolve async provider', () async {
      final scope = Scope(null)
        ..installModules([
          _InlineModule((m, s) {
            m.bind<int>().toProvideAsync(() async => 7);
          }),
        ]);
      expect(await scope.resolveAsync<int>(), 7);
    });

    test('Resolve async provider with param', () async {
      final scope = Scope(null)
        ..installModules([
          _InlineModule((m, s) {
            m.bind<int>().toProvideAsyncWithParams((x) async => (x as int) * 3);
          }),
        ]);
      expect(await scope.resolveAsync<int>(params: 2), 6);
      expect(() => scope.resolveAsync<int>(), throwsA(isA<StateError>()));
    });

    test('tryResolveAsync returns null for missing', () async {
      final scope = Scope(null);
      final result = await scope.tryResolveAsync<String>();
      expect(result, isNull);
    });
  });

  // --------------------------------------------------------------------------
  group('Optional resolution and error handling', () {
    test("tryResolve returns null for missing dependency", () {
      final scope = Scope(null);
      expect(scope.tryResolve<int>(), isNull);
    });

    // Не реализован:
    // test("Container bind() throws state error (if it's parent already has a resolver)", () {
    //   final parentScope = new Scope(null).installModules([TestModule<String>(value: "string one")]);
    //   final scope = new Scope(parentScope);

    //   expect(
    //       () => scope.installModules([TestModule<String>(value: "string two")]),
    //       throwsA(isA<StateError>()));
    // });
  });
}

// ----------------------------------------------------------------------------
// Вспомогательные модули

class TestModule<T> extends Module {
  final T value;
  final String? name;

  TestModule({required this.value, this.name});
  @override
  void builder(Scope currentScope) {
    if (name == null) {
      bind<T>().toInstance(value);
    } else {
      bind<T>().withName(name!).toInstance(value);
    }
  }
}

/// Вспомогательный модуль для подстановки builder'а через конструктор
class _InlineModule extends Module {
  final void Function(Module, Scope) _builder;
  _InlineModule(this._builder);

  @override
  void builder(Scope s) => _builder(this, s);
}
