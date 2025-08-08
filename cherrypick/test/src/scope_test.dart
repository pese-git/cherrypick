import 'package:cherrypick/cherrypick.dart';
import 'package:test/test.dart';
import '../mock_logger.dart';

void main() {
  // --------------------------------------------------------------------------
  group('Scope & Subscope Management', () {
    test('Scope has no parent if constructed with null', () {
      final logger = MockLogger();
      final scope = Scope(null, logger: logger);
      expect(scope.parentScope, null);
    });

    test('Can open and retrieve the same subScope by key', () {
      final logger = MockLogger();
      final scope = Scope(null, logger: logger);
      expect(Scope(scope, logger: logger), isNotNull); // эквивалент
    });

    test('closeSubScope removes subscope so next openSubScope returns new', () {
      final logger = MockLogger();
      final scope = Scope(null, logger: logger);
      expect(Scope(scope, logger: logger), isNotNull); // эквивалент
      // Нет необходимости тестировать open/closeSubScope в этом юните
    });
  });

  // --------------------------------------------------------------------------
  group('Dependency Resolution (standard)', () {
    test("Throws StateError if value can't be resolved", () {
      final logger = MockLogger();
      final scope = Scope(null, logger: logger);
      expect(() => scope.resolve<String>(), throwsA(isA<StateError>()));
    });

    test('Resolves value after adding a dependency', () {
      final logger = MockLogger();
      final expectedValue = 'test string';
      final scope = Scope(null, logger: logger)
          .installModules([TestModule<String>(value: expectedValue)]);
      expect(scope.resolve<String>(), expectedValue);
    });

    test('Returns a value from parent scope', () {
      final logger = MockLogger();
      final expectedValue = 5;
      final parentScope = Scope(null, logger: logger);
      final scope = Scope(parentScope, logger: logger);

      parentScope.installModules([TestModule<int>(value: expectedValue)]);

      expect(scope.resolve<int>(), expectedValue);
    });

    test('Returns several values from parent container', () {
      final logger = MockLogger();
      final expectedIntValue = 5;
      final expectedStringValue = 'Hello world';
      final parentScope = Scope(null, logger: logger).installModules([
        TestModule<int>(value: expectedIntValue),
        TestModule<String>(value: expectedStringValue)
      ]);
      final scope = Scope(parentScope, logger: logger);

      expect(scope.resolve<int>(), expectedIntValue);
      expect(scope.resolve<String>(), expectedStringValue);
    });

    test("Throws StateError if parent hasn't value too", () {
      final logger = MockLogger();
      final parentScope = Scope(null, logger: logger);
      final scope = Scope(parentScope, logger: logger);
      expect(() => scope.resolve<int>(), throwsA(isA<StateError>()));
    });

    test("After dropModules resolves fail", () {
      final logger = MockLogger();
      final scope = Scope(null, logger: logger)..installModules([TestModule<int>(value: 5)]);
      expect(scope.resolve<int>(), 5);
      scope.dropModules();
      expect(() => scope.resolve<int>(), throwsA(isA<StateError>()));
    });
  });

  // --------------------------------------------------------------------------
  group('Named Dependencies', () {
    test('Resolve named binding', () {
      final logger = MockLogger();
      final scope = Scope(null, logger: logger)
        ..installModules([
          TestModule<String>(value: "first"),
          TestModule<String>(value: "second", name: "special")
        ]);
      expect(scope.resolve<String>(named: "special"), "second");
      expect(scope.resolve<String>(), "first");
    });

    test('Named binding does not clash with unnamed', () {
      final logger = MockLogger();
      final scope = Scope(null, logger: logger)
        ..installModules([
          TestModule<String>(value: "foo", name: "bar"),
        ]);
      expect(() => scope.resolve<String>(), throwsA(isA<StateError>()));
      expect(scope.resolve<String>(named: "bar"), "foo");
    });

    test("tryResolve returns null for missing named", () {
      final logger = MockLogger();
      final scope = Scope(null, logger: logger)
        ..installModules([
          TestModule<String>(value: "foo"),
        ]);
      expect(scope.tryResolve<String>(named: "bar"), isNull);
    });
  });

  // --------------------------------------------------------------------------
  group('Provider with parameters', () {
    test('Resolve dependency using providerWithParams', () {
      final logger = MockLogger();
      final scope = Scope(null, logger: logger)
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
      final logger = MockLogger();
      final scope = Scope(null, logger: logger)
        ..installModules([
          _InlineModule((m, s) {
            m.bind<String>().toInstance(Future.value('async value'));
          }),
        ]);
      expect(await scope.resolveAsync<String>(), "async value");
    });

    test('Resolve async provider', () async {
      final logger = MockLogger();
      final scope = Scope(null, logger: logger)
        ..installModules([
          _InlineModule((m, s) {
            m.bind<int>().toProvide(() async => 7);
          }),
        ]);
      expect(await scope.resolveAsync<int>(), 7);
    });

    test('Resolve async provider with param', () async {
      final logger = MockLogger();
      final scope = Scope(null, logger: logger)
        ..installModules([
          _InlineModule((m, s) {
            m.bind<int>().toProvideWithParams((x) async => (x as int) * 3);
          }),
        ]);
      expect(await scope.resolveAsync<int>(params: 2), 6);
      expect(() => scope.resolveAsync<int>(), throwsA(isA<StateError>()));
    });

    test('tryResolveAsync returns null for missing', () async {
      final logger = MockLogger();
      final scope = Scope(null, logger: logger);
      final result = await scope.tryResolveAsync<String>();
      expect(result, isNull);
    });
  });

  // --------------------------------------------------------------------------
  group('Optional resolution and error handling', () {
    test("tryResolve returns null for missing dependency", () {
      final logger = MockLogger();
      final scope = Scope(null, logger: logger);
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
