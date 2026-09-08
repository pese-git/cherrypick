// Fixtures for the runtime-trap-rules group.
// Run `dart run custom_lint` from this package to check them.
import 'package:cherrypick/cherrypick.dart';

// expect_lint: avoid_extends_silent_observer
class BadObserver extends SilentCherryPickObserver {}

/// Extending an unrelated class must not trigger the rule.
class GoodObserver extends PrintCherryPickObserver {}

class BadSingletonModule extends Module {
  @override
  void builder(Scope currentScope) {
    // expect_lint: avoid_redundant_singleton_on_instance
    bind<String>().toInstance('hello').singleton();
  }
}

class GoodSingletonModule extends Module {
  @override
  void builder(Scope currentScope) {
    // `.singleton()` is meaningful on a provider.
    bind<String>().toProvide(() => 'hello').singleton();
    // `.toInstance()` alone, no `.singleton()` chained — nothing to flag.
    bind<int>().toInstance(1);
  }
}

class ParamsSingletonModule extends Module {
  @override
  void builder(Scope currentScope) {
    // `.singleton()` here is a "master singleton" that ignores params after
    // the first resolve — surprising enough to flag, but not always wrong,
    // so this rule has no quick fix.
    // expect_lint: avoid_singleton_on_provide_with_params
    bind<String>().toProvideWithParams((p) => p.toString()).singleton();

    // No `.singleton()` chained — a fresh instance per params, as expected
    // for a parameterized provider. Nothing to flag.
    bind<int>().toProvideWithParams((p) => p as int);
  }
}

class BadResolveModule extends Module {
  @override
  void builder(Scope currentScope) {
    // `resolve()` runs eagerly while this builder is still registering
    // bindings — a sibling type isn't guaranteed to be available yet.
    // expect_lint: avoid_resolve_in_to_instance
    bind<int>().toInstance(currentScope.resolve<String>().length);
  }
}

class GoodResolveModule extends Module {
  @override
  void builder(Scope currentScope) {
    // Deferred via `.toProvide()` — the resolve only runs once this binding
    // is itself resolved, by which point sibling bindings are registered.
    bind<int>().toProvide(() => currentScope.resolve<String>().length);
  }
}

class BadPrecomputedModule extends Module {
  @override
  void builder(Scope currentScope) {
    // `hello` is built once, right here — every resolve<String>() call
    // silently gets this same instance back instead of a fresh one.
    final hello = 'hello';
    // expect_lint: avoid_precomputed_value_in_provide
    bind<String>().toProvide(() => hello);
  }
}

class GoodPrecomputedModule extends Module {
  @override
  void builder(Scope currentScope) {
    // Constructed inside the closure — a fresh value on every resolve.
    bind<String>().toProvide(() => 'hello');

    // A local variable used as part of an expression is fine — the
    // expression itself still runs inside the closure on every resolve.
    final suffix = '!';
    bind<String>().toProvide(() => 'hello$suffix');

    // toInstance() always constructs eagerly regardless of where the value
    // comes from, so precomputing here is fine — nothing to flag.
    final greeting = 'hi';
    bind<String>().withName('greeting').toInstance(greeting);
  }
}
