import 'package:cherrypick/cherrypick.dart';
import 'package:test/test.dart';

class _IntModule extends Module {
  final int value;
  final void Function()? onBuild;

  _IntModule(this.value, {this.onBuild});

  @override
  void builder(Scope currentScope) {
    onBuild?.call();
    bind<int>().toInstance(value);
  }
}

class _StringModule extends Module {
  final String value;

  _StringModule(this.value);

  @override
  void builder(Scope currentScope) {
    bind<String>().toInstance(value);
  }
}

class _NamedIntModule extends Module {
  final String name;
  final int value;

  _NamedIntModule(this.name, this.value);

  @override
  void builder(Scope currentScope) {
    bind<int>().withName(name).toInstance(value);
  }
}

class _DisposableModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<_DisposableService>().toProvide(() => _DisposableService());
  }
}

class _DisposableService implements Disposable {
  bool disposed = false;

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  tearDown(() => CherryPick.closeRootScope());

  group('SilentCherryPickObserver fast-path', () {
    late Scope scope;

    setUp(() {
      // Must NOT have cycle detection — otherwise _canUseDirectResolvePath is false
      // and the fast-path branch is never taken.
      CherryPick.disableGlobalCycleDetection();
      scope = CherryPick.openRootScope();
    });

    test('resolve with default silent observer uses fast-path', () {
      scope.installModules([_IntModule(42)]);
      expect(scope.resolve<int>(), 42);
    });

    test('resolveAsync with default silent observer uses fast-path', () async {
      scope.installModules([_IntModule(42)]);
      final result = await scope.resolveAsync<int>();
      expect(result, 42);
    });

    test('tryResolve with default silent observer uses fast-path', () {
      scope.installModules([_IntModule(42)]);
      expect(scope.tryResolve<int>(), 42);
    });

    test('tryResolveAsync with default silent observer uses fast-path',
        () async {
      scope.installModules([_IntModule(42)]);
      final result = await scope.tryResolveAsync<int>();
      expect(result, 42);
    });

    test('fast-path missing dependency throws', () {
      expect(() => scope.resolve<int>(), throwsStateError);
    });

    test('fast-path missing async dependency throws', () {
      expect(scope.resolveAsync<int>(), throwsA(isA<StateError>()));
    });

    test('installModules with silent observer skips diagnostics', () {
      var buildCalls = 0;
      scope.installModules([_IntModule(42, onBuild: () => buildCalls++)]);
      expect(buildCalls, 1);
      expect(scope.resolve<int>(), 42);
    });

    test('Disposable is tracked even in silent observer fast-path', () async {
      scope.installModules([_DisposableModule()]);

      final service = scope.resolve<_DisposableService>();
      expect(service.disposed, false);
      await scope.dispose();
      expect(service.disposed, true);
    });
  });

  group('Incremental module index', () {
    test('Multiple installModules calls accumulate bindings', () {
      final scope = CherryPick.openSafeRootScope();
      scope.installModules([_IntModule(1)]);
      scope.installModules([_StringModule('two')]);

      expect(scope.resolve<int>(), 1);
      expect(scope.resolve<String>(), 'two');
    });

    test('dropModules clears all bindings', () {
      final scope = CherryPick.openSafeRootScope();
      scope.installModules([_IntModule(1)]);
      scope.dropModules();

      expect(() => scope.resolve<int>(), throwsStateError);
    });

    test('Re-installing modules after dropModules works', () {
      final scope = CherryPick.openSafeRootScope();
      scope.installModules([_IntModule(1)]);
      scope.dropModules();
      scope.installModules([_IntModule(2)]);

      expect(scope.resolve<int>(), 2);
    });

    test('Named bindings are indexed incrementally', () {
      final scope = CherryPick.openSafeRootScope();
      scope.installModules([_NamedIntModule('a', 1)]);
      scope.installModules([_NamedIntModule('b', 2)]);

      expect(scope.resolve<int>(named: 'a'), 1);
      expect(scope.resolve<int>(named: 'b'), 2);
    });
  });
}
