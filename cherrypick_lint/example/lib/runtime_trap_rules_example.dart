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
