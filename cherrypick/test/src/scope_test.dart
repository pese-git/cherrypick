import 'package:cherrypick/cherrypick.dart' show Disposable, Module, Scope, openRootScope;
import 'package:test/test.dart';

// -----------------------------------------------------------------------------
// Вспомогательные классы для тестов

class TestDisposable implements Disposable {
  bool disposed = false;
  @override
  void dispose() {
    disposed = true;
  }
}

class AnotherDisposable implements Disposable {
  bool disposed = false;
  @override
  void dispose() {
    disposed = true;
  }
}

class CountingDisposable implements Disposable {
  int disposeCount = 0;
  @override
  void dispose() {
    disposeCount++;
  }
}

class ModuleCountingDisposable extends Module {
  @override
  void builder(Scope scope) {
    bind<CountingDisposable>().toProvide(() => CountingDisposable()).singleton();
  }
}

class ModuleWithDisposable extends Module {
  @override
  void builder(Scope scope) {
    bind<TestDisposable>().toProvide(() => TestDisposable()).singleton();
    bind<AnotherDisposable>().toProvide(() => AnotherDisposable()).singleton();
    bind<String>().toProvide(() => 'super string').singleton();
  }
}

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

class _InlineModule extends Module {
  final void Function(Module, Scope) _builder;
  _InlineModule(this._builder);
  @override
  void builder(Scope s) => _builder(this, s);
}

class AsyncCreatedDisposable implements Disposable {
  bool disposed = false;
  @override
  void dispose() {
    disposed = true;
  }
}

class AsyncModule extends Module {
  @override
  void builder(Scope scope) {
    bind<AsyncCreatedDisposable>()
        .toProvideAsync(() async {
          await Future.delayed(Duration(milliseconds: 10));
          return AsyncCreatedDisposable();
        })
        .singleton();
  }
}

// -----------------------------------------------------------------------------

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
            m.bind<String>().toInstance(Future.value('async value'));
          }),
        ]);
      expect(await scope.resolveAsync<String>(), "async value");
    });
    test('Resolve async provider', () async {
      final scope = Scope(null)
        ..installModules([
          _InlineModule((m, s) {
            m.bind<int>().toProvide(() async => 7);
          }),
        ]);
      expect(await scope.resolveAsync<int>(), 7);
    });
    test('Resolve async provider with param', () async {
      final scope = Scope(null)
        ..installModules([
          _InlineModule((m, s) {
            m.bind<int>().toProvideWithParams((x) async => (x as int) * 3);
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
  });

  // --------------------------------------------------------------------------
  group('Disposable resource management', () {
    test('scope.dispose calls dispose on singleton disposable', () {
      final scope = openRootScope();
      scope.installModules([ModuleWithDisposable()]);
      final t = scope.resolve<TestDisposable>();
      expect(t.disposed, isFalse);
      scope.dispose();
      expect(t.disposed, isTrue);
    });
    test('scope.dispose calls dispose on all unique disposables', () {
      final scope = openRootScope();
      scope.installModules([ModuleWithDisposable()]);
      final t1 = scope.resolve<TestDisposable>();
      final t2 = scope.resolve<AnotherDisposable>();
      expect(t1.disposed, isFalse);
      expect(t2.disposed, isFalse);
      scope.dispose();
      expect(t1.disposed, isTrue);
      expect(t2.disposed, isTrue);
    });
    test('calling dispose twice does not throw and not call twice', () {
      final scope = openRootScope();
      scope.installModules([ModuleWithDisposable()]);
      final t = scope.resolve<TestDisposable>();
      scope.dispose();
      expect(() => scope.dispose(), returnsNormally);
      expect(t.disposed, isTrue);
    });
    test('Non-disposable dependency is ignored by scope.dispose', () {
      final scope = openRootScope();
      scope.installModules([ModuleWithDisposable()]);
      final s = scope.resolve<String>();
      expect(s, 'super string');
      expect(() => scope.dispose(), returnsNormally);
    });
  });

  // --------------------------------------------------------------------------
  // Расширенные edge-тесты для dispose и subScope
  group('Scope/subScope dispose edge cases', () {
    test('Dispose called in closed subScope only', () {
      final root = openRootScope();
      final sub = root.openSubScope('feature')..installModules([ModuleCountingDisposable()]);
      final d = sub.resolve<CountingDisposable>();
      expect(d.disposeCount, 0);

      root.closeSubScope('feature');
      expect(d.disposeCount, 1); // dispose должен быть вызван

      // Повторное закрытие не вызывает double-dispose
      root.closeSubScope('feature');
      expect(d.disposeCount, 1);

      // Повторное открытие subScope создает NEW instance (dispose на старый не вызовется снова)
      final sub2 = root.openSubScope('feature')..installModules([ModuleCountingDisposable()]);
      final d2 = sub2.resolve<CountingDisposable>();
      expect(identical(d, d2), isFalse);
      root.closeSubScope('feature');
      expect(d2.disposeCount, 1);
    });
    test('Dispose for all nested subScopes on root dispose', () {
      final root = openRootScope();
      final nested = root.openSubScope('a').openSubScope('b')..installModules([ModuleCountingDisposable()]);
      final d = root.openSubScope('a').openSubScope('b').resolve<CountingDisposable>();
      root.dispose();
      expect(d.disposeCount, 1);
    });
  });

  // --------------------------------------------------------------------------
  // Async singleton with sync dispose
  group('Async singleton with sync dispose', () {
    test('Async singleton created, dispose called for resolved', () async {
      final scope = openRootScope()..installModules([AsyncModule()]);
      final d = await scope.resolveAsync<AsyncCreatedDisposable>();
      expect(d.disposed, isFalse);
      scope.dispose();
      expect(d.disposed, isTrue);
    });
  });
}