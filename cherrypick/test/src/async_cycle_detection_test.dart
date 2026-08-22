import 'package:cherrypick/cherrypick.dart';
import 'package:test/test.dart';

/// Timeout guarding every resolve in this file.
///
/// A cycle that goes undetected does not fail fast — it recurses forever, so a
/// broken detector shows up as a hang rather than a wrong value. Every resolve
/// here is bounded so that failure mode surfaces as a test failure.
const _guard = Duration(seconds: 3);

void main() {
  setUp(() async {
    await CherryPick.closeRootScope();
    CherryPick.clearGlobalCycleDetector();
  });

  tearDown(() async {
    await CherryPick.closeRootScope();
    CherryPick.clearGlobalCycleDetector();
  });

  group('async cycle detection across an await boundary', () {
    test('detects a cycle whose providers await before recursing', () async {
      final scope = CherryPick.openRootScope()..enableCycleDetection();
      scope.installModules([AwaitingCycleModule()]);

      await expectLater(
        scope.resolveAsync<AsyncA>().timeout(_guard),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test('reports the full chain, not just the entry point', () async {
      final scope = CherryPick.openRootScope()..enableCycleDetection();
      scope.installModules([AwaitingCycleModule()]);

      await expectLater(
        scope.resolveAsync<AsyncA>().timeout(_guard),
        throwsA(
          isA<CircularDependencyException>().having(
            (e) => e.dependencyChain,
            'dependencyChain',
            allOf(contains('AsyncA'), contains('AsyncB')),
          ),
        ),
      );
    });

    test('detects a cycle reached through tryResolveAsync', () async {
      final scope = CherryPick.openRootScope()..enableCycleDetection();
      scope.installModules([AwaitingCycleModule()]);

      await expectLater(
        scope.tryResolveAsync<AsyncA>().timeout(_guard),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test('detects a self-referencing async provider', () async {
      final scope = CherryPick.openRootScope()..enableCycleDetection();
      scope.installModules([SelfCycleModule()]);

      await expectLater(
        scope.resolveAsync<AsyncA>().timeout(_guard),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test('leaves the scope usable after a detected cycle', () async {
      final scope = CherryPick.openRootScope()..enableCycleDetection();
      scope.installModules([AwaitingCycleModule(), LeafModule()]);

      await expectLater(
        scope.resolveAsync<AsyncA>().timeout(_guard),
        throwsA(isA<CircularDependencyException>()),
      );

      // The chain must have unwound: a healthy dependency still resolves, and
      // the diagnostic chain is empty again.
      await expectLater(
        scope.resolveAsync<Leaf>().timeout(_guard),
        completion(isA<Leaf>()),
      );
      expect(scope.currentResolutionChain, isEmpty);
    });
  });

  group('cross-scope async cycle detection', () {
    test('detects a cycle spanning parent and subscope', () async {
      late Scope child;
      final root = CherryPick.openRootScope()..enableGlobalCycleDetection();
      root.installModules([ParentSideModule(() => child)]);

      child = root.openSubScope('feature')..enableGlobalCycleDetection();
      child.installModules([ChildSideModule(root)]);

      await expectLater(
        child.resolveAsync<AsyncA>().timeout(_guard),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test('local detection also catches a cycle that leaves and re-enters',
        () async {
      late Scope child;
      final root = CherryPick.openRootScope();
      root.installModules([ParentSideModule(() => child)]);

      child = root.openSubScope('feature')..enableCycleDetection();
      child.installModules([ChildSideModule(root)]);

      // The zone-scoped chain follows the resolution out into the parent and
      // back, so the subscope's own detector sees AsyncA a second time.
      await expectLater(
        child.resolveAsync<AsyncA>().timeout(_guard),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test('detects a cycle between two sibling subscopes', () async {
      late Scope a, b;
      final root = CherryPick.openRootScope();
      a = root.openSubScope('a')..enableCycleDetection();
      b = root.openSubScope('b')..enableCycleDetection();
      a.installModules([SiblingAModule(() => b)]);
      b.installModules([SiblingBModule(() => a)]);

      // Neither sibling is an ancestor of the other, so no single scope sees
      // both halves of the cycle. The chain is carried by the zone, which
      // follows the resolution into the neighbour and back regardless.
      await expectLater(
        a.resolveAsync<AsyncA>().timeout(_guard),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test('detects a sibling cycle with cross-scope detection only', () async {
      late Scope a, b;
      final root = CherryPick.openRootScope()..enableGlobalCycleDetection();
      // Opened after arming, so both inherit cross-scope detection.
      a = root.openSubScope('a');
      b = root.openSubScope('b');
      a.installModules([SiblingAModule(() => b)]);
      b.installModules([SiblingBModule(() => a)]);

      await expectLater(
        a.resolveAsync<AsyncA>().timeout(_guard),
        throwsA(isA<CircularDependencyException>().having(
          (e) => e.dependencyChain,
          'dependencyChain',
          hasLength(greaterThan(2)),
        )),
      );
    });

    test('one armed scope on the cycle is enough, entered from the other',
        () async {
      late Scope a, b;
      final root = CherryPick.openRootScope();
      a = root.openSubScope('a')..enableCycleDetection();
      b = root.openSubScope('b'); // deliberately left unarmed
      a.installModules([SiblingAModule(() => b)]);
      b.installModules([SiblingBModule(() => a)]);

      // Entering through the unarmed sibling still trips a's detector: a real
      // cycle re-enters every node on it, including the guarded one.
      await expectLater(
        b.resolveAsync<AsyncB>().timeout(_guard),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test('detects a cycle between cousin scopes two levels deep', () async {
      late Scope x, y;
      final root = CherryPick.openRootScope()..enableGlobalCycleDetection();
      x = root.openSubScope('left').openSubScope('x');
      y = root.openSubScope('right').openSubScope('y');
      x.installModules([SiblingAModule(() => y)]);
      y.installModules([SiblingBModule(() => x)]);

      await expectLater(
        x.resolveAsync<AsyncA>().timeout(_guard),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test('siblings sharing a parent dependency is not a cycle', () async {
      final root = CherryPick.openRootScope()
        ..enableCycleDetection()
        ..enableGlobalCycleDetection();
      root.installModules([LeafModule()]);
      final a = root.openSubScope('a')..installModules([InheritsLeafModule()]);
      final b = root.openSubScope('b')..installModules([InheritsLeafModule()]);

      // Both siblings reach the same parent binding. The keys repeat across
      // the two resolutions but never within one, so this must not be read as
      // a cycle — including on a second pass through the first sibling.
      await expectLater(
          a.resolveAsync<Left>().timeout(_guard), completion(isA<Left>()));
      await expectLater(
          b.resolveAsync<Left>().timeout(_guard), completion(isA<Left>()));
      await expectLater(
          a.resolveAsync<Left>().timeout(_guard), completion(isA<Left>()));
    });
  });

  group('concurrent resolutions must not see each other', () {
    test('same type resolved twice in parallel is not a cycle', () async {
      final scope = CherryPick.openRootScope()..enableCycleDetection();
      scope.installModules([SlowLeafModule()]);

      final results = await Future.wait([
        scope.resolveAsync<Leaf>(),
        scope.resolveAsync<Leaf>(),
      ]).timeout(_guard);

      expect(results, hasLength(2));
      expect(results[0], isA<Leaf>());
      expect(results[1], isA<Leaf>());
    });

    test('parallel chains sharing a dependency is not a cycle', () async {
      final scope = CherryPick.openRootScope()..enableCycleDetection();
      scope.installModules([SharedDependencyModule()]);

      final results = await Future.wait([
        scope.resolveAsync<Left>(),
        scope.resolveAsync<Right>(),
      ]).timeout(_guard);

      expect(results, hasLength(2));
    });

    test('same type in parallel is not a cycle with global detection on',
        () async {
      final scope = CherryPick.openRootScope()
        ..enableCycleDetection()
        ..enableGlobalCycleDetection();
      scope.installModules([SlowLeafModule()]);

      final results = await Future.wait([
        scope.resolveAsync<Leaf>(),
        scope.resolveAsync<Leaf>(),
      ]).timeout(_guard);

      expect(results, hasLength(2));
    });
  });

  group('diagnostics', () {
    test('the chain is visible from inside an async provider', () async {
      final scope = CherryPick.openRootScope()..enableCycleDetection();
      final module = ChainRecordingModule();
      scope.installModules([module]);

      await scope.resolveAsync<Leaf>().timeout(_guard);

      expect(module.observedChain, contains('Leaf'));
      expect(scope.currentResolutionChain, isEmpty);
    });
  });
}

class AsyncA {
  final AsyncB b;
  AsyncA(this.b);
}

class AsyncB {
  final AsyncA a;
  AsyncB(this.a);
}

class Leaf {}

class Left {
  final Leaf leaf;
  Left(this.leaf);
}

class Right {
  final Leaf leaf;
  Right(this.leaf);
}

/// A cycle whose providers suspend *before* recursing.
///
/// The await is the point of the test: it moves the recursive resolve out of
/// the provider's synchronous prefix, so a detector that stops tracking when
/// the provider returns its future no longer sees the chain.
class AwaitingCycleModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<AsyncA>().toProvideAsync(() async {
      await Future<void>.delayed(Duration.zero);
      return AsyncA(await currentScope.resolveAsync<AsyncB>());
    });
    bind<AsyncB>().toProvideAsync(() async {
      await Future<void>.delayed(Duration.zero);
      return AsyncB(await currentScope.resolveAsync<AsyncA>());
    });
  }
}

class SelfCycleModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<AsyncA>().toProvideAsync(() async {
      await Future<void>.delayed(Duration.zero);
      return await currentScope.resolveAsync<AsyncA>();
    });
  }
}

class LeafModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Leaf>().toProvideAsync(() async {
      await Future<void>.delayed(Duration.zero);
      return Leaf();
    });
  }
}

class SlowLeafModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Leaf>().toProvideAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return Leaf();
    });
  }
}

class SharedDependencyModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Leaf>().toProvideAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return Leaf();
    });
    bind<Left>().toProvideAsync(() async {
      await Future<void>.delayed(Duration.zero);
      return Left(await currentScope.resolveAsync<Leaf>());
    });
    bind<Right>().toProvideAsync(() async {
      await Future<void>.delayed(Duration.zero);
      return Right(await currentScope.resolveAsync<Leaf>());
    });
  }
}

/// Parent half of a cycle that closes through a subscope.
///
/// Resolution only ever walks from a scope towards its parents, so the parent
/// cannot reach `AsyncA` on its own — the subscope is passed in, lazily because
/// it is opened after this module is installed.
class ParentSideModule extends Module {
  final Scope Function() _child;

  ParentSideModule(this._child);

  @override
  void builder(Scope currentScope) {
    bind<AsyncB>().toProvideAsync(() async {
      await Future<void>.delayed(Duration.zero);
      return AsyncB(await _child().resolveAsync<AsyncA>());
    });
  }
}

/// Subscope half: resolves the parent's binding, which resolves back into here.
class ChildSideModule extends Module {
  final Scope _root;

  ChildSideModule(this._root);

  @override
  void builder(Scope currentScope) {
    bind<AsyncA>().toProvideAsync(() async {
      await Future<void>.delayed(Duration.zero);
      return AsyncA(await _root.resolveAsync<AsyncB>());
    });
  }
}

/// One half of a cycle that closes between two scopes on different branches:
/// binds [AsyncA] here and reaches into the neighbour for [AsyncB].
///
/// The neighbour is supplied lazily because the two scopes are wired to each
/// other, so neither exists when the first module is built.
class SiblingAModule extends Module {
  final Scope Function() _neighbour;

  SiblingAModule(this._neighbour);

  @override
  void builder(Scope currentScope) {
    bind<AsyncA>().toProvideAsync(() async {
      await Future<void>.delayed(Duration.zero);
      return AsyncA(await _neighbour().resolveAsync<AsyncB>());
    });
  }
}

/// The mirror half of [SiblingAModule], closing the cycle back on itself.
class SiblingBModule extends Module {
  final Scope Function() _neighbour;

  SiblingBModule(this._neighbour);

  @override
  void builder(Scope currentScope) {
    bind<AsyncB>().toProvideAsync(() async {
      await Future<void>.delayed(Duration.zero);
      return AsyncB(await _neighbour().resolveAsync<AsyncA>());
    });
  }
}

/// Sibling-side binding that reaches up to a dependency owned by the parent —
/// the shape that must not be mistaken for a cycle when two siblings do it.
class InheritsLeafModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Left>().toProvideAsync(() async {
      await Future<void>.delayed(Duration.zero);
      return Left(await currentScope.resolveAsync<Leaf>());
    });
  }
}

/// Records the resolution chain as seen from inside an async provider, after
/// the provider has already suspended once.
class ChainRecordingModule extends Module {
  List<String> observedChain = const [];

  @override
  void builder(Scope currentScope) {
    bind<Leaf>().toProvideAsync(() async {
      await Future<void>.delayed(Duration.zero);
      observedChain = currentScope.currentResolutionChain;
      return Leaf();
    });
  }
}
