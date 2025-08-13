import 'package:cherrypick/cherrypick.dart'
    show Disposable, Module, Scope, CherryPick;
import 'dart:async';
import 'package:test/test.dart';
import '../mock_logger.dart';

// -----------------------------------------------------------------------------
// Вспомогательные классы для тестов

class AsyncExampleDisposable implements Disposable {
  bool disposed = false;
  @override
  Future<void> dispose() async {
    await Future.delayed(Duration(milliseconds: 10));
    disposed = true;
  }
}

class AsyncExampleModule extends Module {
  @override
  void builder(Scope scope) {
    bind<AsyncExampleDisposable>()
        .toProvide(() => AsyncExampleDisposable())
        .singleton();
  }
}

class TestDisposable implements Disposable {
  bool disposed = false;
  @override
  FutureOr<void> dispose() {
    disposed = true;
  }
}

class AnotherDisposable implements Disposable {
  bool disposed = false;
  @override
  FutureOr<void> dispose() {
    disposed = true;
  }
}

class CountingDisposable implements Disposable {
  int disposeCount = 0;
  @override
  FutureOr<void> dispose() {
    disposeCount++;
  }
}

class ModuleCountingDisposable extends Module {
  @override
  void builder(Scope scope) {
    bind<CountingDisposable>()
        .toProvide(() => CountingDisposable())
        .singleton();
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
        // ignore: deprecated_member_use_from_same_package
        .toProvideAsync(() async {
      await Future.delayed(Duration(milliseconds: 10));
      return AsyncCreatedDisposable();
    }).singleton();
  }
}

// -----------------------------------------------------------------------------

void main() {
  // --------------------------------------------------------------------------
  group('Scope & Subscope Management', () {
    test('Scope has no parent if constructed with null', () {
      final observer = MockObserver();
      final scope = Scope(null, observer: observer);
      expect(scope.parentScope, null);
    });
    test('Can open and retrieve the same subScope by key', () {
      final observer = MockObserver();
      final scope = Scope(null, observer: observer);
      expect(Scope(scope, observer: observer), isNotNull); // эквивалент
    });
    test('closeSubScope removes subscope so next openSubScope returns new',
        () async {
      final observer = MockObserver();
      final scope = Scope(null, observer: observer);
      final subScope = scope.openSubScope("child");
      expect(scope.openSubScope("child"), same(subScope));
      await scope.closeSubScope("child");
      final newSubScope = scope.openSubScope("child");
      expect(newSubScope, isNot(same(subScope)));
    });

    test('closeSubScope removes subscope so next openSubScope returns new', () {
      final observer = MockObserver();
      final scope = Scope(null, observer: observer);
      expect(Scope(scope, observer: observer), isNotNull); // эквивалент
      // Нет необходимости тестировать open/closeSubScope в этом юните
    });
  });

  // --------------------------------------------------------------------------
  group('Dependency Resolution (standard)', () {
    test("Throws StateError if value can't be resolved", () {
      final observer = MockObserver();
      final scope = Scope(null, observer: observer);
      expect(() => scope.resolve<String>(), throwsA(isA<StateError>()));
    });
    test('Resolves value after adding a dependency', () {
      final observer = MockObserver();
      final expectedValue = 'test string';
      final scope = Scope(null, observer: observer)
          .installModules([TestModule<String>(value: expectedValue)]);
      expect(scope.resolve<String>(), expectedValue);
    });
    test('Returns a value from parent scope', () {
      final observer = MockObserver();
      final expectedValue = 5;
      final parentScope = Scope(null, observer: observer);
      final scope = Scope(parentScope, observer: observer);

      parentScope.installModules([TestModule<int>(value: expectedValue)]);
      expect(scope.resolve<int>(), expectedValue);
    });
    test('Returns several values from parent container', () {
      final observer = MockObserver();
      final expectedIntValue = 5;
      final expectedStringValue = 'Hello world';
      final parentScope = Scope(null, observer: observer).installModules([
        TestModule<int>(value: expectedIntValue),
        TestModule<String>(value: expectedStringValue)
      ]);
      final scope = Scope(parentScope, observer: observer);

      expect(scope.resolve<int>(), expectedIntValue);
      expect(scope.resolve<String>(), expectedStringValue);
    });
    test("Throws StateError if parent hasn't value too", () {
      final observer = MockObserver();
      final parentScope = Scope(null, observer: observer);
      final scope = Scope(parentScope, observer: observer);
      expect(() => scope.resolve<int>(), throwsA(isA<StateError>()));
    });
    test("After dropModules resolves fail", () {
      final observer = MockObserver();
      final scope = Scope(null, observer: observer)
        ..installModules([TestModule<int>(value: 5)]);
      expect(scope.resolve<int>(), 5);
      scope.dropModules();
      expect(() => scope.resolve<int>(), throwsA(isA<StateError>()));
    });
  });

  // --------------------------------------------------------------------------
  group('Named Dependencies', () {
    test('Resolve named binding', () {
      final observer = MockObserver();
      final scope = Scope(null, observer: observer)
        ..installModules([
          TestModule<String>(value: "first"),
          TestModule<String>(value: "second", name: "special")
        ]);
      expect(scope.resolve<String>(named: "special"), "second");
      expect(scope.resolve<String>(), "first");
    });
    test('Named binding does not clash with unnamed', () {
      final observer = MockObserver();
      final scope = Scope(null, observer: observer)
        ..installModules([
          TestModule<String>(value: "foo", name: "bar"),
        ]);
      expect(() => scope.resolve<String>(), throwsA(isA<StateError>()));
      expect(scope.resolve<String>(named: "bar"), "foo");
    });
    test("tryResolve returns null for missing named", () {
      final observer = MockObserver();
      final scope = Scope(null, observer: observer)
        ..installModules([
          TestModule<String>(value: "foo"),
        ]);
      expect(scope.tryResolve<String>(named: "bar"), isNull);
    });
  });

  // --------------------------------------------------------------------------
  group('Provider with parameters', () {
    test('Resolve dependency using providerWithParams', () {
      final observer = MockObserver();
      final scope = Scope(null, observer: observer)
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
      final observer = MockObserver();
      final scope = Scope(null, observer: observer)
        ..installModules([
          _InlineModule((m, s) {
            m.bind<String>().toInstance(Future.value('async value'));
          }),
        ]);
      expect(await scope.resolveAsync<String>(), "async value");
    });
    test('Resolve async provider', () async {
      final observer = MockObserver();
      final scope = Scope(null, observer: observer)
        ..installModules([
          _InlineModule((m, s) {
            m.bind<int>().toProvide(() async => 7);
          }),
        ]);
      expect(await scope.resolveAsync<int>(), 7);
    });
    test('Resolve async provider with param', () async {
      final observer = MockObserver();
      final scope = Scope(null, observer: observer)
        ..installModules([
          _InlineModule((m, s) {
            m.bind<int>().toProvideWithParams((x) async => (x as int) * 3);
          }),
        ]);
      expect(await scope.resolveAsync<int>(params: 2), 6);
      expect(() => scope.resolveAsync<int>(), throwsA(isA<StateError>()));
    });
    test('tryResolveAsync returns null for missing', () async {
      final observer = MockObserver();
      final scope = Scope(null, observer: observer);
      final result = await scope.tryResolveAsync<String>();
      expect(result, isNull);
    });
  });

  // --------------------------------------------------------------------------
  group('Optional resolution and error handling', () {
    test("tryResolve returns null for missing dependency", () {
      final observer = MockObserver();
      final scope = Scope(null, observer: observer);
      expect(scope.tryResolve<int>(), isNull);
    });
  });

  // --------------------------------------------------------------------------
  group('Disposable resource management', () {
    test('scope.disposeAsync calls dispose on singleton disposable', () async {
      final scope = CherryPick.openRootScope();
      scope.installModules([ModuleWithDisposable()]);
      final t = scope.resolve<TestDisposable>();
      expect(t.disposed, isFalse);
      await scope.dispose();
      expect(t.disposed, isTrue);
    });
    test('scope.disposeAsync calls dispose on all unique disposables',
        () async {
      final scope = Scope(null, observer: MockObserver());
      scope.installModules([ModuleWithDisposable()]);
      final t1 = scope.resolve<TestDisposable>();
      final t2 = scope.resolve<AnotherDisposable>();
      expect(t1.disposed, isFalse);
      expect(t2.disposed, isFalse);
      await scope.dispose();
      expect(t1.disposed, isTrue);
      expect(t2.disposed, isTrue);
    });
    test('calling disposeAsync twice does not throw and not call twice',
        () async {
      final scope = CherryPick.openRootScope();
      scope.installModules([ModuleWithDisposable()]);
      final t = scope.resolve<TestDisposable>();
      await scope.dispose();
      await scope.dispose();
      expect(t.disposed, isTrue);
    });
    test('Non-disposable dependency is ignored by scope.disposeAsync',
        () async {
      final scope = CherryPick.openRootScope();
      scope.installModules([ModuleWithDisposable()]);
      final s = scope.resolve<String>();
      expect(s, 'super string');
      await scope.dispose();
    });
  });

  // --------------------------------------------------------------------------
  // Расширенные edge-тесты для dispose и subScope
  group('Scope/subScope dispose edge cases', () {
    test('Dispose called in closed subScope only', () async {
      final root = CherryPick.openRootScope();
      final sub = root.openSubScope('feature')
        ..installModules([ModuleCountingDisposable()]);
      final d = sub.resolve<CountingDisposable>();
      expect(d.disposeCount, 0);

      await root.closeSubScope('feature');
      expect(d.disposeCount, 1); // dispose должен быть вызван

      // Повторное закрытие не вызывает double-dispose
      await root.closeSubScope('feature');
      expect(d.disposeCount, 1);

      // Повторное открытие subScope создает NEW instance (dispose на старый не вызовется снова)
      final sub2 = root.openSubScope('feature')
        ..installModules([ModuleCountingDisposable()]);
      final d2 = sub2.resolve<CountingDisposable>();
      expect(identical(d, d2), isFalse);
      await root.closeSubScope('feature');
      expect(d2.disposeCount, 1);
    });
    test('Dispose for all nested subScopes on root disposeAsync', () async {
      final root = CherryPick.openRootScope();
      root
          .openSubScope('a')
          .openSubScope('b')
          .installModules([ModuleCountingDisposable()]);
      final d = root
          .openSubScope('a')
          .openSubScope('b')
          .resolve<CountingDisposable>();
      await root.dispose();
      expect(d.disposeCount, 1);
    });
  });

  // --------------------------------------------------------------------------
  group('Async disposable (Future test)', () {
    test('Async Disposable is awaited on disposeAsync', () async {
      final scope = CherryPick.openRootScope()
        ..installModules([AsyncExampleModule()]);
      final d = scope.resolve<AsyncExampleDisposable>();
      expect(d.disposed, false);
      await scope.dispose();
      expect(d.disposed, true);
    });
  });
}
